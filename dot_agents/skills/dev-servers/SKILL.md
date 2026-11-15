---
name: dev-servers
description: Use before you start, stop, or read the logs of a dev server or other long-running process, and before any `rex` command.
---

# Dev Servers

Run every dev server in a Rex terminal through `portless`, so it outlives your
turn, gets a named `.localhost` URL, and the user can watch it. Keep the
session ID and block ID that each command returns. For a `rex` command that is
not shown here, load the `rex` skill.

## Mode

- **Inside Rex:** `REX_SESSION` and `REX_BLOCK` are set. Your agent runs in
  `REX_BLOCK`.
- **Outside Rex:** `REX_SESSION` is not set, and `rex whoami --json` succeeds.
  T3 Code runs this way.
- **No Rex:** neither is true. Ask the user to start the server in the T3 Code
  thread terminal, and read its output from `~/.t3/userdata/logs/terminals/`.

## Start

- Inside Rex, open a tab in the current session and keep focus where it is:
  `rex window new -s "$REX_SESSION" Server -c "$PWD" --keep-open --focus=false --json -- <cmd>`
- Outside Rex, create one session per worktree:
  `rex new "<repo>-<branch>" -c "$PWD" --keep-open --json -- <cmd>`
  Restart in that same session:
  `rex run -s <session> -c "$PWD" --keep-open --focus=false --json -- <cmd>`

## Logs and stop

- Logs: `rex capture -s <session> -b <block> --trim | tail -n 200`
- Stop: `rex send-key -s <session> -b <block> ctrl+c`

## Hand back

Leave the server running and tell the user its session name. Kill the session
when the user asks, when you remove its worktree, or when its PR is merged.
