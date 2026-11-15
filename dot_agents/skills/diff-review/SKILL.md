---
name: diff-review
description: Use before you review a finished diff or delegate an implementation task.
---

# Diff Review

## Review

Review each diff with a model from a different provider than the writer:
Codex `gpt-6.1-sol` for code that a Claude model wrote, and Claude Opus for
code that Codex wrote. Run the reviewer in a fresh session, in the branch
worktree, against `origin/main`. Give it the request and the diff, and keep
your reasoning out, so its read is independent of yours. Tell it to skip
style. For a risky change, ask for an adversarial review.

Check each finding against the code before you fix it: about one finding in
four is wrong. Use one reviewer and at most two rounds per diff: the review,
then one re-check of the fixes. A second reviewer needs the user's ask. If
findings stay open after the re-check, give them to the user.

## Delegate

Give a clear, well-scoped ticket to Codex `gpt-6.1-sol`, and a ticket that
needs design judgment or is hard to check by eye to Claude Opus. Put the
writer model in the PR body as `Writer: <model>`. Before you delegate, confirm
that no other thread or open PR has the ticket.
