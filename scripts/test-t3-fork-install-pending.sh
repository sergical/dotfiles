#!/bin/bash
set -euo pipefail

source_dir="$(cd "$(dirname "$0")/.." && pwd)"
installer="$source_dir/private_dot_local/private_bin/executable_t3-fork-install-pending"
scratch="$(mktemp -d)"
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
