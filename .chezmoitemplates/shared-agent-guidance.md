# Communication

- Follow ISO 24495-1 and ASD-STE100 Simplified Technical English.
- Make routine choices and report why. Do not hand back option menus.

# Machine Ownership

- Machine config is in `sergical/dotfiles` (chezmoi). Before changing a managed
  file, read `~/.local/share/chezmoi/AGENTS.md` and edit its source there.
- Agent rules, skills, hooks and proofs live in `~/.agents`, written from dotfiles.
- Machines, servers, routes and access belong in `sergical/fleet` (`~/src/fleet`).
  Change cloud resources only in `fleet/cloud`, with `pnpm deploy`. Run fleet's
  checks before reporting that a change works.

# Rex and Dev Servers

Never send input to `REX_BLOCK`. Only control Rex blocks and sessions you
created, unless their owner T3 thread is settled or archived, or their worktree
is gone. A merged PR is not enough.

Before starting or stopping a dev server, reading its logs, or running `rex`,
load `~/.agents/skills/dev-servers/SKILL.md`. Run dev servers through that
workflow, not as background shell commands.

# Verification

Do not call a change done without a number or direct observation that proves it.
For PRs, required checks must pass on the head commit; use
`~/.agents/skills/pr-body/SKILL.md` to record the evidence.

Run the repository's required checks after the last edit. Use scoped checks for
small changes when the repository permits them. Do not rerun a green check
without a new edit. Batch checks in one command and filter output at the source.

Use `agent-browser` only for proof that requires a rendered page. Use Helium
for sites that need the user's login. Close browser sessions you created when
the check is complete; leave pages the user is actively checking to them.

# Helpers and Review

Delegate only parallel read-only searches across unknown areas, open-ended web
research, large-log or file summaries, or a finished diff review. Use a cheaper
model for searches, research and summaries when available.

For a finished diff review, load `~/.agents/skills/diff-review/SKILL.md`.
For production or test changes with green checks, use
`~/.agents/skills/simplify-code/SKILL.md` before final review. Skip simplification
for changes of three edits or fewer, and for documentation, generated, vendored,
snapshot, lockfile, formatting and configuration-only changes.
