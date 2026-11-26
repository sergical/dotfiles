#!/bin/bash
# Run manually on macOS to check the installer against scratch bundles.
set -euo pipefail

source_dir="$(cd "$(dirname "$0")/.." && pwd)"
installer="$source_dir/private_dot_local/private_bin/executable_t3-fork-install-pending"
scratch="$(cd "$(mktemp -d)" && pwd -P)"
trap 'rm -rf "$scratch"' EXIT
export T3_FORK_SYNC_STATE_DIR="$scratch/sync"
export T3_FORK_SYNC_APP_PATH="$scratch/Fake App.app"
pending="$T3_FORK_SYNC_STATE_DIR/pending"
mkdir -p "$T3_FORK_SYNC_APP_PATH/Contents/MacOS" "$pending/T3 fork.app"
printf 'old\n' >"$T3_FORK_SYNC_APP_PATH/marker"
printf 'new\n' >"$pending/T3 fork.app/marker"
printf 'v0.1.0-nightly.1+1234567890\n' >"$pending/version"

/bin/bash -c '
  exec -a "$1" /bin/bash -c '\''
    set -e
    pattern="^${0%/*}/"
    if /usr/bin/pgrep -qf "$pattern"; then
      echo "pgrep unexpectedly matched the fake app without -a" >&2
      exit 1
    fi
    echo "pgrep without -a: 1 (missed the running ancestor)"
    /usr/bin/pgrep -aqf "$pattern"
    echo "pgrep with -a: 0 (found the running ancestor)"
    /bin/bash "$1"
    [ "$(cat "$T3_FORK_SYNC_APP_PATH/marker")" = old ]
    [ -f "$T3_FORK_SYNC_STATE_DIR/pending/version" ]
    [ ! -e "$T3_FORK_SYNC_APP_PATH.previous" ]
    echo "Shared installer left the running app and pending bundle in place."
  '\'' "$1" "$2"
' _ "$T3_FORK_SYNC_APP_PATH/Contents/MacOS/Fake" "$installer"

/bin/bash "$installer"
[ "$(cat "$T3_FORK_SYNC_APP_PATH/marker")" = new ]
[ "$(cat "$T3_FORK_SYNC_APP_PATH.previous/marker")" = old ]
[ "$(cat "$T3_FORK_SYNC_STATE_DIR/installed")" = v0.1.0-nightly.1+1234567890 ]
[ ! -e "$pending" ]
echo "Shared installer copied the pending bundle, kept .previous, and recorded the installed version."

# LaunchServices is exercised with a small app that can exit before announcing readiness.
fixtures="$scratch/fixtures"
mkdir -p "$fixtures"
cat >"$fixtures/main.c" <<'C'
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
int main(int argc, char **argv) {
  const char *state = getenv("T3_FORK_SYNC_STATE_DIR");
  const char *prefix = "--t3-fork-restart-attempt=";
  const char *attempt = NULL;
  for (int i = 1; i < argc; i++) {
    if (strncmp(argv[i], prefix, strlen(prefix)) == 0) attempt = argv[i] + strlen(prefix);
  }
  char path[4096], ready[4096];
  if (!attempt) {
    snprintf(path, sizeof path, "%s/fallback-opened", state);
    FILE *fallback = fopen(path, "w");
    if (!fallback) return 1;
    fclose(fallback);
    return 0;
  }
  snprintf(path, sizeof path, "%s/attempts", state);
  FILE *attempts = fopen(path, "a+");
  rewind(attempts);
  int first = fgetc(attempts) == EOF;
  fputs("launch\n", attempts);
  fclose(attempts);
  snprintf(path, sizeof path, "%s/always-exit", state);
  if (first || access(path, F_OK) == 0) return 42;
  snprintf(path, sizeof path, "%s/%s/writing", state, attempt);
  snprintf(ready, sizeof ready, "%s/%s/ready", state, attempt);
  FILE *marker = fopen(path, "w");
  if (!marker) return 1;
  fprintf(marker, "%d\nhttp://127.0.0.1:%s/.well-known/t3/environment\n", getpid(),
    getenv("T3CODE_PORT"));
  fclose(marker);
  if (rename(path, ready) != 0) return 1;
  snprintf(path, sizeof path, "%s/fixture-pid", state);
  FILE *pid = fopen(path, "w");
  if (!pid) return 1;
  fprintf(pid, "%d\n", getpid());
  fclose(pid);
  while (access(path, F_OK) == 0) usleep(10000);
  return 0;
}
C
/usr/bin/clang "$fixtures/main.c" -o "$fixtures/ForkRestartFixture"
node -e 'const s=require("node:http").createServer((q,r)=>{r.statusCode=q.url==="/.well-known/t3/environment"?200:404;r.end()});s.listen(0,"127.0.0.1",()=>console.log(s.address().port))' >"$fixtures/port" &
backend=$!
keep_open=
cleanup() {
  if [ -n "$keep_open" ]; then touch "$fixtures/old-exit"; wait "$keep_open" || true; fi
  rm -f "$T3_FORK_SYNC_STATE_DIR/fixture-pid"
  kill "$backend" 2>/dev/null || true
  wait "$backend" || true
  rm -rf "$scratch"
}
trap cleanup EXIT
while [ ! -s "$fixtures/port" ]; do sleep 0.05; done
export T3CODE_PORT
T3CODE_PORT="$(cat "$fixtures/port")"
version=v0.1.0-nightly.2+1234567890
make_pending() {
  mkdir -p "$pending/T3 fork.app/Contents/MacOS"
  cp "$fixtures/ForkRestartFixture" "$pending/T3 fork.app/Contents/MacOS/"
  cat >"$pending/T3 fork.app/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<plist version="1.0"><dict>
<key>CFBundleIdentifier</key><string>test.t3.fork.restart.$$.fixture</string>
<key>CFBundleExecutable</key><string>ForkRestartFixture</string>
<key>CFBundlePackageType</key><string>APPL</string>
<key>CFBundleShortVersionString</key><string>0.1.0-fork.2</string>
<key>T3ForkCommitHash</key><string>1234567890123456789012345678901234567890</string>
</dict></plist>
PLIST
  echo "$version" >"$pending/version"
}
make_pending
/bin/bash -c 'while [ ! -e "$1" ]; do sleep 0.05; done' _ "$fixtures/old-exit" &
keep_open=$!
/bin/bash "$installer" --restart "$keep_open" "$version" >"$fixtures/restart.log" 2>&1 &
handoff=$!
for ((i = 0; i < 100; i++)); do
  if grep -q "restart waiting for PID $keep_open" "$fixtures/restart.log"; then break; fi
  sleep 0.05
done
grep -q "restart waiting for PID $keep_open" "$fixtures/restart.log"
kill -0 "$keep_open"
[ -f "$pending/version" ]
[ ! -e "$T3_FORK_SYNC_STATE_DIR/attempts" ]
touch "$fixtures/old-exit"
wait "$keep_open"
keep_open=
wait "$handoff" || { cat "$fixtures/restart.log" >&2; exit 1; }
[ "$(wc -l <"$T3_FORK_SYNC_STATE_DIR/attempts" | tr -d ' ')" = 2 ]
grep -F "restart ready" "$fixtures/restart.log"
test ! -e "$T3_FORK_SYNC_STATE_DIR/restart-failure"
echo "Restart waited for the old process and retried the first launch that exited before readiness."

fixture_pid="$(cat "$T3_FORK_SYNC_STATE_DIR/fixture-pid")"
rm "$T3_FORK_SYNC_STATE_DIR/fixture-pid" "$T3_FORK_SYNC_STATE_DIR/attempts"
touch "$T3_FORK_SYNC_STATE_DIR/always-exit"
if /bin/bash "$installer" --restart "$fixture_pid" "$version" >"$fixtures/failed.log" 2>&1; then
  echo "Restart unexpectedly accepted a launch without readiness" >&2
  exit 1
fi
[ "$(wc -l <"$T3_FORK_SYNC_STATE_DIR/attempts" | tr -d ' ')" = 2 ]
grep -F "did not become ready after two launches" "$T3_FORK_SYNC_STATE_DIR/restart-failure"
test -d "$T3_FORK_SYNC_APP_PATH.previous"
echo "Two early exits reported a persistent failure and kept the previous app."

if /bin/bash "$installer" --restart "$fixture_pid" v0.1.0-nightly.3+1234567890 >"$fixtures/stale.log" 2>&1; then
  echo "Restart unexpectedly installed a build that was no longer pending" >&2
  exit 1
fi
for ((i = 0; i < 100; i++)); do
  if [ -f "$T3_FORK_SYNC_STATE_DIR/fallback-opened" ]; then break; fi
  sleep 0.05
done
test -f "$T3_FORK_SYNC_STATE_DIR/fallback-opened"
test "$(cat "$T3_FORK_SYNC_STATE_DIR/installed")" = "$version"
echo "A stale restart request reported the install failure and reopened the current app."
