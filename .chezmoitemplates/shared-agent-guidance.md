# Communication
- Always follow ISO 24495-1 and ASD-STE100 Simplified Technical English

# Rex

Use Rex in one of two modes. Load the `rex` skill before the first `rex`
command.

- **Inside Rex:** `REX_SESSION` and `REX_BLOCK` are set. Scope work to that
  session. Never send input to `REX_BLOCK`: your agent runs there.
- **Outside Rex:** `REX_SESSION` is not set, but `rex whoami --json` succeeds.
  This is the case in T3 Code. Never send keys to, focus, or kill a session
  that you did not create, except to clean up a session whose worktree is
  gone or whose PR is merged.

If neither is true, do not use Rex. Do not ask the user to start Rex.

# Dev Servers

Never run a dev server as a background shell command. Claude Code stops
background commands after 30 minutes by default and 2 hours at most, and the
user cannot see their output. Run the server through `portless` for a named
`.localhost` URL, in a Rex terminal. Keep the session ID and block ID that the
command returns.

- **Inside Rex:** open a new tab in the current session, and do not steal
  focus:
  `rex window new -s "$REX_SESSION" Server -c "$PWD" --keep-open --focus=false --json -- <cmd>`.
- **Outside Rex:** create one session for the worktree:
  `rex new "<repo>-<branch>" -c "$PWD" --keep-open --json -- <cmd>`.
  Reuse that session for a restart:
  `rex run -s <session> -c "$PWD" --keep-open --focus=false --json -- <cmd>`.
  When you hand back, leave the server running and tell the user the session
  name. Kill the session when the user asks, when you remove its worktree,
  or when its PR is merged.
- **In both modes:** read logs with
  `rex capture -s <session> -b <block> --trim | tail -n 200`. Stop the server
  with `rex send-key -s <session> -b <block> ctrl+c`.
- **No Rex:** ask the user to start the server in the T3 Code thread terminal.
  Read its output from `~/.t3/userdata/logs/terminals/`.

# Executor

The `executor` MCP server holds the user's connected accounts: Cloudflare,
Sentry, Vercel, Linear, Notion, Google Docs and Sheets, Mobbin, Excalidraw,
Ahrefs, Profound, Plausible, Motion, and Kody. Before you use a CLI, ask for a
login, or say that you cannot access one of these services, run
`tools.executor.coreTools.connections.list({})` in `execute`. Use a CLI only
when Executor does not have the operation. Pick the connection that matches the
account the user names.

# Verification

Verify with the cheapest proof that can go red: a test, `curl`, or a typecheck.
Use `agent-browser` only when the proof exists only in a rendered page: layout,
focus flow, computed styles, console errors, media, or a multi-step UI flow. For
a refactor, one page load with a clean console is the proof. Read a known doc
page with web fetch; use the user's Helium browser for sites that need their login. When
the user iterates with you on an open page, let them check it.

For each browser check, write down its one question first and take one snapshot
per question. Stop and report when the browser or dev server is blocked. Close
the session before you report.

Run the acceptance checks once, after the last edit of a batch. Do not rerun a
green check without a new edit. For a change of three edits or fewer, or a
prototype, run only the scoped check for the changed files.

Chain the checks of one run into one command, for example
`cargo fmt --all && cargo clippy --workspace -- -D warnings && cargo test`, and
filter its output. Use the check script of the repo when it has one. Do not use
a separate tool call for each check.

# Helper Agents

Use a helper agent only for:

- Parallel read-only search across several unknown areas, one helper per area,
  all in one message.
- Open-ended web research across several sources.
- A summary of a large log, test run, or file.
- A fresh-context review of a finished diff. Give the reviewer the request and
  the diff, not your reasoning.

Check a helper's claims against the real diff and command output.

Filter shell output at the source with `head`, `wc`, `grep`, or a field
selector.

# Post-green Simplification

After a task materially changes production or test code and the checks are
green, run the `simplify-code` skill once on the diff. If the harness has not
loaded it, read `~/.agents/skills/simplify-code/SKILL.md`. Rerun the same
checks, accept a no-op, and revert only the simplification edits if a check
regresses. Then run the final review. Skip this for changes of three edits or
fewer, and for documentation, generated, vendored, snapshot, lockfile,
formatting, and configuration-only changes.

# Comments

Write self-documenting code. Add a comment only for context the code cannot
show. Do not use comments to describe a decision.
