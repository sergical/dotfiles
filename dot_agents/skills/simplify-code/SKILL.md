---
name: simplify-code
description: Simplify a working implementation after its acceptance checks pass. Use for a fresh post-implementation cleanup of changed production or test code before final review, especially after an agent adds modules, abstractions, branching, helpers, or defensive logic. Preserve behavior and rerun the same checks.
---

# Simplify Code

Improve the maintainability of an already-working change without changing what it does. A valid result may be no edits.

## Process

1. Record the comparison base, changed paths, acceptance criteria, and exact checks that already passed. If the relevant checks are not green or the behavior contract is unclear, stop and report that simplification is unsafe.
2. Inspect the diff and enough surrounding code to understand existing conventions. Stay within changed code unless one existing helper is the direct replacement for new duplicate logic.
3. Apply a small coherent cleanup, in this priority order:
   - delete speculative options, unused indirection, one-use pass-throughs, redundant comments, and impossible-state defenses;
   - replace duplicate or roundabout logic with an existing local pattern;
   - flatten control flow and make names reveal intent;
   - reduce what callers must know without creating a new framework or public seam.
4. When the diff adds or changes a module, adapter, interface, or abstraction, load `codebase-design` and apply only its deletion test, depth test, and real-seam rule. Keep broader architectural opportunities as follow-ups.
5. Run the same relevant checks that were green before the cleanup. If a check fails, undo only this pass's edits with targeted patches, rerun the check, and report the rejected simplification.
6. Report changed paths, the complexity removed, and the exact verification result. Say `no worthwhile simplification` when the working diff is already appropriately simple.

## Invariants

- Preserve observable behavior, public interfaces, error contracts, compatibility, security properties, persistence formats, and performance requirements.
- Preserve test coverage and assertion strength. Do not change tests to make a behavior change pass.
- Keep the change focused. Add no dependency, feature, configuration, migration, generalized framework, or drive-by cleanup.
- Prefer deletion and direct code over abstraction. Introduce a helper only when it removes real duplication or hides complexity from multiple callers.
- Leave generated files, vendored code, snapshots, lockfiles, and deliberate migration artifacts alone unless the task explicitly targets them.
- Use targeted edits. Never use reset, checkout, or another broad rollback to undo cleanup in a working tree that may contain someone else's changes.
