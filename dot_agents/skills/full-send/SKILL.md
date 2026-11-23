---
name: full-send
description: "Trigger when the user explicitly says 'full send' (or asks for hands-off end-to-end delivery to merge). Owns the work from implementation through proof, diff-review, pr-body, babysit-pr, and merging."
---

# Full Send

If the user triggered this, they are not watching this thread and want the work driven end-to-end autonomously to a merged PR. If the user did not request "full send" (or AFK end-to-end delivery), do not assume permission to auto-merge.

Under "full send", the user grants permission to:

- Run the direct proof and test methods the change needs (dev servers, browser automation, simulators, screenshots, short recordings) without ask-first pauses, then stop any servers or browsers when done.
- Force-push the PR's own branch with `--force-with-lease` after a rebase.
- Merge the PR once the merge gate passes.

This grant does **not** authorize unasked-for production writes outside the repo, deleting user data, closing unrelated PRs, or force-pushing other branches.

## Steps

1. **Finish the change.** Implement the goal on a non-default branch with the smallest diff that solves it.
2. **Prove it directly.** Observe real evidence in this session: reproduce failures before/after, run the repository checks that cover touched code, and exercise the running app/CLI/UI (green mocked tests alone do not prove UX).
3. **Run independent review.** Read and follow the `diff-review` skill (cross-provider review).
4. **Open or update the PR.** Rebase onto the latest default branch first if needed, open the PR using the `pr-body` skill, and link it to the T3 Code thread (`link_pull_request`).
5. **Check local merge risk before enabling auto-merge.** If the repository has `scripts/gate/gate`, run `scripts/gate/gate risk --json` against the base branch. If `tier` is `stop` (or the diff introduces any unasked-for one-way door: destructive database migration, secrets/billing/deploy configuration change, public release, or deleting user data) and the user did **not** explicitly ask for that specific change in this thread, switch to `full-stop` instead of merging.
6. **Babysit CI and bots.** Follow the `babysit-pr` skill (`watch_pull_request`). Fix real CI failures and valid bot findings, re-proving before each push.
7. **Merge.** Once all required checks are green, review threads are resolved, the branch is mergeable (`CLEAN`, and rebased if `BEHIND` on overlapping trunk changes), merge through branch protection using the repo's normal merge method. Never use `--admin` or bypasses without the user's explicit go-ahead in chat.
8. **Report.** Summarize the PR link, merge commit, direct proof observed, and any decisions made for the user.

## Stopping or asking

If blocked on something outside this grant (cannot prove the change, unresolvable merge gate, genuine product ambiguity, or an obsolete PR), call `unwatch_pull_request` first so the thread returns to the user's inbox, use the harness's question tool when available, and end with `Needed from you and why`.
