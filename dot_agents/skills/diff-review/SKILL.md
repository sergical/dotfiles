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

Ask the reviewer each time: will the next agent copy a workaround in this
diff? The next agent copies the code it finds, so a workaround spreads. Ask it
most for a large diff that no person reviews.

Check each finding against the code before you fix it: about one finding in
four is wrong. Use one reviewer and at most two rounds per diff: the review,
then one re-check of the fixes. A second reviewer needs the user's ask. If
a finding that blocks the merge stays open after the re-check, give it to the
user.

## Delegate

Give a clear, well-scoped ticket to Codex `gpt-6.1-sol`, and a ticket that
needs design judgment or is hard to check by eye to Claude Opus. Put the
writer model in the PR body as `Writer: <model>`. Before you delegate, confirm
that no other thread or open PR has the ticket.

For a bug that is not trivial, ask for two plans before code: the patch, and
the smallest change that removes the cause. Each plan names a regression test
that fails on the base and passes on the head. Choose the plan after which the
next feature needs no new exception for the same problem. A small diff can be
that plan, and a large diff can avoid the cause.
