#!/bin/bash
# Exercise the sync script on macOS with a scratch checkout and fake checks and build.
set -euo pipefail

source_dir="$(cd "$(dirname "$0")/.." && pwd)"
scratch="$(mktemp -d)"
trap 'rm -rf "$scratch"' EXIT
export REAL_NODE="$(command -v node)"
export HOME="$scratch/home"
export T3_FORK_REPO="$scratch/fork"
export CALLS="$scratch/calls"
bin="$HOME/.vite-plus/bin"
state="$HOME/.t3-fork-lab/sync"
mkdir -p "$bin" "$T3_FORK_REPO"
cp "$source_dir/private_dot_local/private_bin/executable_t3-fork-sync" "$scratch/t3-fork-sync"
printf '#!/bin/bash\nexit 0\n' >"$scratch/t3-fork-install-pending"
cat >"$bin/osascript" <<'SH'
#!/bin/bash
exit 0
SH
cat >"$bin/node" <<'SH'
#!/bin/bash
set -euo pipefail
case "$1" in
  scripts/check-changed.ts)
    echo check >>"$CALLS"
    if [ "$SCENARIO" = node ]; then
      if vp exec node --test .github/scripts/passing.test.cjs .github/scripts/failing.test.cjs; then
        exit 98
      fi
      printf '\ncheck:changed summary\n  FAIL  node --test (2 files)  1.0s\n'
      exit 1
    fi
    if [ "$SCENARIO" = lint ]; then
      printf '\ncheck:changed summary\n  FAIL  lint  1.0s\n'
      exit 1
    fi
    if vp test run --passWithNoTests apps/web/passing.test.ts apps/web/failing.browser.test.ts; then
      exit 98
    fi
    if [ "$SCENARIO" = mixed ] &&
      vp test run apps/web/src/reactCompilerCoverage.test.ts -t 'compiles a|^(?!.*compiles )'; then
      exit 98
    fi
    printf '\ncheck:changed summary\n'
    if [ "$SCENARIO" = mixed ]; then
      printf '  FAIL  react compiler (1 files)  1.0s\n'
    else
      printf '  pass  react compiler (1 files)  1.0s\n'
    fi
    if [ "$SCENARIO" = timeout ]; then
      printf '  TIMEOUT  test (2 files)  killed after 900s\n'
    else
      printf '  FAIL  test (2 files)  1.0s\n'
    fi
    exit 1
    ;;
  scripts/build-desktop-artifact.ts)
    echo build >>"$CALLS"
    out="${!#}"
    mkdir -p "$out" "$HOME/bundle/T3 fork.app"
    ditto -c -k --keepParent "$HOME/bundle/T3 fork.app" "$out/app.zip"
    ;;
  *) exec "$REAL_NODE" "$@" ;;
esac
SH
cat >"$bin/vp" <<'SH'
#!/bin/bash
set -euo pipefail
case "$*" in
  'install --frozen-lockfile') exit 0 ;;
  'run scenarios --target web --workers 1 '*) echo journeys >>"$CALLS"; [ "$SCENARIO" != browser ] ;;
  'exec node --test --test-reporter=tap .github/scripts/passing.test.cjs .github/scripts/failing.test.cjs')
    echo initial-tests >>"$CALLS"
    printf 'ok 1 - .github/scripts/passing.test.cjs\nnot ok 2 - .github/scripts/failing.test.cjs\n'
    exit 1
    ;;
  'exec node --test --test-concurrency=1 .github/scripts/failing.test.cjs')
    echo retry >>"$CALLS"
    exit 0
    ;;
  'test run --passWithNoTests '*)
    echo initial-tests >>"$CALLS"
    for arg in "$@"; do
      case "$arg" in
        --outputFile.json=*)
          if [ "$SCENARIO" != timeout ]; then
            printf '{"success":false,"testResults":[{"name":"%s/apps/web/passing.test.ts","status":"passed"},{"name":"%s/apps/web/failing.browser.test.ts","status":"failed"}]}\n' \
              "$PWD" "$PWD" >"${arg#*=}"
          fi
          ;;
      esac
    done
    exit 1
    ;;
  'test run apps/web/src/reactCompilerCoverage.test.ts -t '*)
    echo initial-compiler >>"$CALLS"
    exit 1
    ;;
  'test run --maxWorkers=1 --no-file-parallelism apps/web/src/reactCompilerCoverage.test.ts -t '*)
    echo compiler-retry >>"$CALLS"
    [ "$7" = 'compiles a|^(?!.*compiles )' ] || { echo unexpected-pattern >>"$CALLS"; exit 97; }
    ;;
  'test run --maxWorkers=1 --no-file-parallelism '*)
    echo retry >>"$CALLS"
    files=("${@:5}")
    if [ "$SCENARIO" = timeout ]; then
      [ "${files[*]}" = 'apps/web/passing.test.ts apps/web/failing.browser.test.ts' ]
    else
      [ "${#files[@]}" -eq 1 ] && [ "${files[0]}" = 'apps/web/failing.browser.test.ts' ]
    fi || { echo unexpected-files >>"$CALLS"; exit 97; }
    [ "$SCENARIO" != repeats ]
    ;;
  *) echo "Unexpected vp invocation: $*" >&2; exit 99 ;;
esac
SH
chmod +x "$bin/"* "$scratch/t3-fork-install-pending"
cd "$T3_FORK_REPO"
git init -q -b t3-fork
git config user.name 'Sync Test'
git config user.email 'sync-test@example.invalid'
git config core.hooksPath /dev/null
touch .env.example
git add .env.example
git commit -qm base
git tag v0.0.0-nightly.1
mkdir -p apps/web
touch apps/web/{passing.test.ts,failing.browser.test.ts}
git add apps/web
git commit -qm fork
git remote add origin .
want="v0.0.0-nightly.1+$(git rev-parse --short HEAD)"

run_case() {
  rm -rf "$state"
  mkdir -p "$state/pending"
  printf "previous\n" >"$state/pending/version"
  : >"$CALLS"
  local status=0
  SCENARIO="$1" /bin/bash "$scratch/t3-fork-sync" >"$scratch/log" 2>&1 || status=$?
  if [ "$status" != "$2" ] || [ "$(cat "$CALLS")" != "$3" ]; then
    cat "$scratch/log" "$CALLS" >&2
    return 1
  fi
  if grep -qx retry "$CALLS"; then
    grep -q 'Retrying .* tests once with one worker' "$scratch/log"
  fi
  if [ "$status" -eq 0 ]; then
    [ ! -e "$state/failed" ]
    [ "$(cat "$state/pending/version")" = "$want" ]
  else
    [ "$(cat "$state/failed")" = "$want" ]
    [ "$(cat "$state/pending/version")" = previous ]
  fi
}

run_case recovers 0 $'check\ninitial-tests\nretry\njourneys\nbuild'
echo 'PASS: retried only the failed file, built, and left no failed marker'
run_case repeats 1 $'check\ninitial-tests\nretry'
echo 'PASS: a second failure wrote the failed marker'
run_case mixed 0 $'check\ninitial-tests\ninitial-compiler\ncompiler-retry\nretry\njourneys\nbuild'
echo 'PASS: a React Compiler failure retried its stage with one worker, pattern intact'
run_case lint 1 $'check'
echo 'PASS: a lint failure wrote the failed marker without a retry'
run_case timeout 0 $'check\ninitial-tests\nretry\njourneys\nbuild'
echo 'PASS: a timed-out test stage retried its original files with one worker'
run_case node 0 $'check\ninitial-tests\nretry\njourneys\nbuild'
echo 'PASS: a Node test failure retried only the failed file with one worker'

run_case browser 1 $'check\ninitial-tests\nretry\njourneys'
echo 'PASS: a browser failure blocked the build and preserved the previous pending version'

fork_tip="$(git rev-parse HEAD)"
git switch -qc upstream v0.0.0-nightly.1
git merge --ff-only "$fork_tip" >/dev/null
echo next >upstream
git add upstream
git commit -qm upstream
git tag v0.0.0-nightly.2
git switch -q t3-fork
echo next >fork
git add fork
git commit -qm local
local_tip="$(git rev-parse HEAD)"
rm -rf "$state"
: >"$CALLS"
SCENARIO=recovers bash "$scratch/t3-fork-sync" >"$scratch/log" 2>&1
git merge-base --is-ancestor "$local_tip" HEAD
git merge-base --is-ancestor v0.0.0-nightly.2 HEAD
merged_tip="$(git rev-parse HEAD)"
: >"$CALLS"
SCENARIO=recovers bash "$scratch/t3-fork-sync" >"$scratch/log" 2>&1
[ ! -s "$CALLS" ]
[ "$(git rev-parse HEAD)" = "$merged_tip" ]
echo 'PASS: shared history merges once and a repeated sync does no work'

git switch -qc conflicting v0.0.0-nightly.2
echo conflict >fork
git add fork
git commit -qm conflicting
git tag v0.0.0-nightly.3
git switch -q t3-fork
pending_version="$(cat "$state/pending/version")"
: >"$CALLS"
status=0
SCENARIO=recovers bash "$scratch/t3-fork-sync" >"$scratch/log" 2>&1 || status=$?
[ "$status" -eq 1 ] && [ ! -s "$CALLS" ]
[ "$(git rev-parse HEAD)" = "$merged_tip" ]
[ -z "$(git status --porcelain)" ]
[ "$(cat "$state/pending/version")" = "$pending_version" ]
echo 'PASS: a true conflict leaves the fork clean and keeps the pending build'
