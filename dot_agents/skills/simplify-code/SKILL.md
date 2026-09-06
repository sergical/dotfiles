---
name: simplify-code
description: Simplify a working implementation after its acceptance checks pass. Use for a fresh post-green cleanup of changed production or test code before final review, especially after an agent adds modules, abstractions, branching, helpers, or defensive logic. Preserve behavior and rerun the same checks.
---

# Simplify Code

Improve the maintainability of an already-working change without changing what it does. A valid result may be no edits.

## Inputs

The caller supplies the behavior contract, the comparison base, the changed paths, and the exact commands that passed. Work from those and the repository only. The implementer's reasoning stays out of scope.

## Process

1. Run the supplied commands once. Continue only when every one is green. Otherwise stop and report that simplification is unsafe.
2. Inspect the diff and enough surrounding code to learn the local conventions. Stay within changed code, with one exception: an existing helper that directly replaces new duplicate logic.
3. List every simplification candidate before editing. For each candidate that removes something, check the fence first: find the callers, the tests, and the commit that introduced it. Keep anything a caller, a test, or a documented decision depends on.
4. Apply the candidates that passed the fence check as one small coherent pass, in this priority order:
   - delete speculative options, unused indirection, one-use pass-throughs, redundant comments, and impossible-state defenses;
   - replace duplicate or roundabout logic with an existing local pattern;
   - flatten control flow and make names reveal intent;
   - reduce what callers must know while keeping the public surface as it is.
5. When the diff adds or changes a module, adapter, interface, or abstraction, load `matt-codebase-design` and apply only its deletion test, depth test, and real-seam rule. Record broader architectural opportunities as follow-ups.
6. Rerun the same commands. If one fails, revert only this pass's edits with targeted patches, rerun, and move that candidate to the skipped list with the failure as its reason.
7. Report in three parts:
   - **Applied**: each changed path with the complexity removed, and the exact check results.
   - **Noticed but not applied**: each skipped candidate with one reason, such as a fence dependency, a check failure, or scope.
   - **Follow-ups**: architectural opportunities outside this pass.
   When nothing was applied, the report is the single line `no worthwhile simplification`, plus the skipped list when it is non-empty.

## Invariants

- Observable behavior, public interfaces, error contracts, compatibility, security properties, persistence formats, and performance requirements stay as they are.
- Tests keep their coverage and assertion strength. A test changes only when the code it asserts on was simplified in this pass.
- The change stays focused: the same dependencies, features, configuration, and migrations as before the pass.
- Deletion and direct code win over abstraction. A new helper earns its place only by removing real duplication across multiple callers.
- Generated files, vendored code, snapshots, lockfiles, and deliberate migration artifacts stay untouched unless the task names them.
- Every revert is a targeted patch to this pass's own edits, because the working tree may hold someone else's changes.
