---
name: diff-review
description: Use before reviewing a finished diff.
---

# Diff Review

Review the complete diff against the intended merge base with a model from a
different provider than the writer: Codex `gpt-6.1-sol` for Claude-written code,
and Claude Opus for Codex-written code. If the required provider is unavailable,
report the independent review as incomplete instead of silently substituting
another reviewer.

Run the reviewer in a fresh session in the branch worktree. Give it the request,
comparison base and changed paths. Keep the implementer's reasoning out so its
read is independent. Ask for correctness findings, not style; for a risky
change, ask for an adversarial review.

When the diff changes UI files (`.tsx`, `.jsx`, `.css`, `.vue`, `.svelte`) and the
`emil-ui-review` skill is installed, also run it on those files. Read
`~/.agents/skills/emil-review-animations/SKILL.md` too when motion changed.

Ask whether the diff adds a workaround that later code would copy. Check each
finding against the actual code and command output before accepting it.

Use one reviewer and at most two rounds: the initial review and one re-check
if fixes need it. A second reviewer needs the
user's request. If a blocking finding remains, report it to the user.
