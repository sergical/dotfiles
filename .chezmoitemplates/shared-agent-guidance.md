# Communication
- Always follow ISO 24495-1 and ASD-STE100 Simplified Technical English
- Decide and act. When a choice is not truly the user's, pick the best option, do it, and report why. Do not hand back option menus.

# Where Things Live

- Machine config: `sergical/dotfiles` (chezmoi). Before you change a managed
  file, read `~/.local/share/chezmoi/AGENTS.md`.
- Agent rules, skills, hooks and proofs: `~/.agents`, written from the
  dotfiles source.
- Machines, servers, routes and access: `sergical/fleet` (`~/src/fleet`).
  Change cloud resources only in `fleet/cloud`, with `pnpm deploy`.
- Each line in fleet has a check. Run it before you say that something works.

# Rex and Dev Servers

Never send input to `REX_BLOCK`, and never send keys to, focus, or kill a Rex
session that you did not create, unless its worktree is gone or its PR is
merged. Never run a dev server as a background shell command. Before you start a dev server or run any `rex` command, load the
`dev-servers` skill. If the harness has not loaded it, read
`~/.agents/skills/dev-servers/SKILL.md`.

# Executor

The `executor` MCP server holds the user's connected accounts: Cloudflare,
Sentry, Vercel, Linear, Notion, Google Docs and Sheets, Mobbin, Excalidraw,
Ahrefs, Profound, Plausible, Motion, and Kody. Before you use a CLI, ask for a
login, or say that you cannot access one of these services, run
`tools.executor.coreTools.connections.list({})` in `execute`. Use a CLI only
when Executor does not have the operation. Pick the connection that matches the
account the user names.

# Verification

Prove each change before you call it done. Use a number where one exists (test result, count, timing, before and after) and a direct observation where one does not (command output, screenshot, transcript). If you cannot get proof, the work is not done: say what blocks the proof and what would give it.

For a PR, done means that the required checks pass on the head commit and the PR body shows the proof for that commit. Green CI alone is not proof, because CI tests only what it already covers. When the repo has a risk gate, follow it: its scripts decide the tier, and AI review and your evidence only add input.

On a stop-tier PR, add the `gate:approved` label yourself when the head commit has a passing `gate/review` with `0 open` from a reviewer of a different provider, each CI job except `risk` passes, and the proof card shows that head. Do not wait for the user. Add the label after the last push.

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

Filter shell output at the source with `head`, `wc`, `grep`, or a field
selector.

# Helpers and Review

Use a helper only for:

- Parallel read-only search across several unknown areas, one helper per area,
  all in one message.
- Open-ended web research across several sources.
- A summary of a large log, test run, or file.
- A review of a finished diff.

For search, research, and summaries, give the helper a cheaper model than your
own when the tool lets you set one.

Before you review a finished diff or delegate an implementation task, load the
`diff-review` skill. If the harness has not loaded it, read
`~/.agents/skills/diff-review/SKILL.md`.

Check a helper's claims against the real diff and command output.

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
