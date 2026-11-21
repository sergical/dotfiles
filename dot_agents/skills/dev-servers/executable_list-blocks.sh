#!/usr/bin/env bash
# List every Rex block: session label, window, block, exit code, folder.
# A block with an exit code has stopped. Read-only.
set -euo pipefail
rex ls --json | jq -r '.sessions[] | "\(.session_id) \(.label)"' |
  while read -r s label; do
    rex block ls -s "$s" --json | jq -r '.blocks[] | "\(.block_id) \(.window_id)"' |
      while read -r b w; do
        echo "$label $w $b $(rex block call -s "$s" -b "$b" process |
          jq -c '{exit: .last_exit.exit_code, cwd: .foreground.cwd}')"
      done
  done
