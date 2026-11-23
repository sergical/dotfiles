---
name: babysit-pr
description: Monitor a pull request through CI and review. Use whenever calling watch_pull_request, or when watching, monitoring, or babysitting a PR.
---

# Babysit PR

## Waiting

Never write your own watcher, polling loop, or `sleep` loop. Use `watch_pull_request` in T3 Code; handle existing checks and comments first, then call `watch_pull_request` and end your turn. T3 Code wakes you when a check fails, required checks pass, someone comments or reviews, or the branch conflicts.

- **Only the thread that owns the PR watches it.** Delegated child tasks (`delegate_task` reviewers or workers) never call `watch_pull_request`. Do not watch PRs you do not own.
- **A wake is news, not a merge decision.** Check the full merge gate yourself before acting or reporting ready.
- **Unwatch when you hand off.** A watched thread stays in Working and out of the user's inbox. Whenever you stop (ready to review/merge, blocked, or asking the user a question), call `unwatch_pull_request` first. Never leave a PR watched with `until: "merged"` when waiting on the owner. A merge or close ends the watch on its own.
- **"Stopped watching, could not read it"** usually means GitHub's GraphQL rate limit is used up. Check `gh api rate_limit --jq .resources.graphql` before watching again; use REST (`gh api repos/<owner>/<repo>/pulls/<n>` and `.../commits/<sha>/check-runs`) when GraphQL is low. Never watch again in a tight loop.
- When an event needs no action, end your turn without filler status messages.

## Reviews

Act only on checks and comments newer than the latest push. Verify every bot finding against the source code before changing code.

- Fix real bugs in the intended case and CI failures with the smallest change, re-checking before you push.
- Reply with a written reason when declining false positives or nits, and resolve the thread.
- Keep the PR scoped to the user's goal. List out-of-scope improvements or rare-case ideas as follow-ups instead of expanding the diff.
- Treat advisory bots (such as CodeRabbit when non-required) on their merits, and do not hold a merge waiting on optional bots.

## Base branch and merging

`watch_pull_request` reports conflicts only, so check whether the PR is behind before calling it ready or merging:

```sh
git fetch origin && gh pr view <pr> --json mergeStateStatus,baseRefName,headRefOid
```

If the branch is `DIRTY` or `BEHIND` on files touched by base commits that affect this PR, rebase onto the latest default branch, re-run covering checks, push (`--force-with-lease`), and wait for green CI again.

Merge only when authorized (`full-send` or explicit user request in the thread). Otherwise report the PR ready, call `unwatch_pull_request`, and hand back cleanly.
