---
name: pr-body
description: Write a pull request title and body. Use when you open a PR, when a push changes what a PR does, or when asked to describe a PR.
---

# PR Body

Write for a maintainer who has not read the conversation. Follow the repository's
PR template and scale the description to the change.

1. Read the complete diff against the intended PR base, the request, repository
   PR guidance, and any unresolved review findings.
2. Lead with the concrete bug or need and the resulting behavior. Use a title
   that matches the repository's recent history.
3. For a small fix, write one short paragraph and the evidence needed to assess
   it. Add sections only when the repository requires them or the change needs
   more explanation.
4. Report a before-and-after observation or a regression test result. Name checks
   that were blocked or not run. Explain material compatibility or operational
   risks when they exist. Avoid repeating implementation details visible in the
   diff, generic rollback claims, AI approval claims, and writer-model labels.
5. When updating a PR, rewrite the body from the current diff. When asked to
   open or update it, use `gh pr create --body-file` or
   `gh pr edit --body-file` with the exact text in a file. Otherwise return the
   proposed description without publishing it. In a repo with `scripts/gate/gate`,
   follow its README and run `gate card` after publishing.

Done when a maintainer can tell what changes, why it matters, what proves it,
and which material questions remain. Every factual claim needs evidence.
