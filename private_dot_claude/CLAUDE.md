@~/.agents/AGENTS.md

# Claude Code

`general-purpose` runs on the session model, so it is the most expensive
helper. Use it only when one task needs web access and repo edits together.

# Code Review

Review with a Codex session through `delegate_task` (provider `codex`), in the
branch worktree, against `origin/main`. For risky changes, ask it for an
adversarial review. Give the reviewer the request and the diff, not your
reasoning. Run `/code-review` only when the user asks, from an Opus session.
One reviewer per diff; a second reviewer needs the user's ask.

Do at most two review rounds for one diff: the first review, then one re-check
of the fixes. If findings stay open after the re-check, stop and give them to
the user.

# Implementation Helpers

Give a delegated implementation task to a Codex session through
`delegate_task` (provider `codex`, model `gpt-6.1-sol`). Use a Claude model
only when the user asks for one. Before you delegate a ticket, make sure that
no other thread or open PR has it.
