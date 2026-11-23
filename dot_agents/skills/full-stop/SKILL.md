---
name: full-stop
description: "Trigger when the user says 'full stop', asks to hold before merge, or when full-send falls back on an unasked one-way door. Drives the PR to green and verified, then hands off without merging."
---

# Full Stop

Do the exact same implementation, direct proof, `diff-review`, `pr-body`, and `babysit-pr` workflow as `full-send`, with one hard override: **stop with the PR open, green, and ready for the user to merge. Never merge it.**

Follow `full-send` for testing permission, proof standards, `diff-review`, `pr-body`, and `babysit-pr`, subject to the overrides below.

## No merging

- Never run `gh pr merge`, never enable `gh pr merge --auto`, never enter a merge queue, and never bypass branch protection.
- If auto-merge is already enabled on the PR, disable it (`gh pr merge --disable-auto <pr>`) before pushing and confirm again before handoff.
- You may commit, push, rebase, fix conflicts, and force-push only the PR's own branch (`--force-with-lease`).

## Stop at the gate

Once CI, bots, and review threads are clean on the latest head:

1. Fetch the target branch and inspect the live PR (`gh pr view <pr> --json state,isDraft,autoMergeRequest,mergeStateStatus,statusCheckRollup,headRefOid,baseRefName,url`).
2. Confirm the PR is open, not a draft, has no auto-merge enabled, has all required checks green, has no unresolved review threads, and is mergeable against the latest base.
3. **Call `unwatch_pull_request` before handing off or asking any question.** A watched thread stays in Working and hidden from the user's inbox.
4. End the reply with a `Needed from you and why` section containing:
   - The PR link and final head SHA, plus explicit confirmation that the PR is open and unmerged.
   - The one-line decision (and any `scripts/gate/gate risk --json` `ask`/`why` if `stop` triggered).
   - Direct proof summary, `diff-review` verdict, and any remaining risks, with your recommended pick and why.
