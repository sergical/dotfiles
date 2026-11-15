---
name: dev-servers
description: Use before you start, stop, or read the logs of a dev server or other long-running process, and before any `rex` command.
---

# Dev Servers

Run every dev server in a Rex terminal through `portless`, so it outlives your
turn, gets a named `.localhost` URL, and the user can watch it. For a `rex`
command that is not shown here, load the `rex` skill.

## Mode

- **Inside Rex:** `REX_SESSION` and `REX_BLOCK` are set. Your agent runs in
  `REX_BLOCK`.
- **Outside Rex:** `REX_SESSION` is not set, and `rex whoami --json` succeeds.
  T3 Code runs this way.
- **No Rex:** neither is true. Ask the user to start the server in the T3 Code
  thread terminal, and read its output from `~/.t3/userdata/logs/terminals/`.

## Names

The Rex sidebar shows only names. A tab without a name shows as
"Window <id>", and nobody can tell what it is.

- Session: `<repo>-<branch>` for a worktree. For a scratch folder, use
  `<topic>-<8 hex>`, where the 8 hex characters are the end of the scratch
  folder name. They are also the end of the T3 thread ID.
- Tab: `<portless name>.localhost (dev)`, for example
  `shop.localhost (dev)`. For a server without portless, use
  `<what> :<port>`, for example `test shop :47820`.
- Give each tab a name when you open it. Never open a tab without a name.

## Start

Keep the session ID, window ID, and block ID that each command returns.

- New session, outside Rex:
  `rex new "<session>" --window "<tab>" -c "$PWD" --keep-open --json -- portless <name> <cmd>`
- New tab in a session that exists (inside Rex, use `"$REX_SESSION"`):
  `rex window new -s <session> "<tab>" -c "$PWD" --keep-open --focus=false --json -- portless <name> <cmd>`

## Logs

`rex capture -s <session> -b <block> --trim | tail -n 200`

## Stop and restart

`--keep-open` keeps a block after its program exits, so you can read a crash.
Thus each stop must also close the block.

1. `rex send-key -s <session> -b <block> ctrl+c`
2. `rex block call -s <session> -b <block> process` shows `last_exit` when the
   program has stopped. Read the logs first if you need them.
3. `rex block close -s <session> <block>`. When the block is the only one in
   its tab, the tab closes too. Other panes in the tab stay open.

To restart, do the stop steps, then open a new tab with the same name. Each
server has one tab.

## Hand back

Tell the user the session name, the tab name, and the URL. Leave the server
running only while the user needs it. When your task is done and the server
has no more use, stop it and close its tab.

## Clean up

Kill a session when its owner thread is settled or archived, or its worktree
is gone. A merged PR is not enough, because one thread can open many PRs.

1. List the blocks and what they run:

   ```sh
   rex ls --json | jq -r '.sessions[] | "\(.session_id) \(.label)"' |
     while read -r s label; do
       rex block ls -s "$s" --json | jq -r '.blocks[] | "\(.block_id) \(.window_id)"' |
         while read -r b w; do
           echo "$label $w $b $(rex block call -s "$s" -b "$b" process |
             jq -c '{exit: .last_exit.exit_code, cwd: .foreground.cwd}')"
         done
     done
   ```

   A block with `exit` set is stopped. Rex does not keep the folder of a
   stopped block, so read its first lines with `rex capture`.
2. Find the owner thread with the T3 MCP tools. A worktree folder matches the
   `worktreePath` of a thread. A scratch path, in `~/.t3/scratch` or in an
   agent scratchpad, holds a folder name that ends with the last 8 hex
   characters of its thread ID. `t3_thread_read` shows `settled` and
   `archived`.
3. Close stopped blocks with `rex block close`. Kill the session with
   `rex kill <session>` when the owner thread is done and no block in it
   belongs to other work, such as a pane that the user opened.
4. Never remove a worktree when you kill its session. Run
   `git -C <worktree> status --short` and tell the user about work that is not
   committed.
