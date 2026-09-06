---
name: simplify
description: Fresh post-green writer for one behavior-preserving cleanup pass. Use after material production or test code is green and before final correctness review. A no-op is valid.
model: sonnet
effort: medium
tools: Read, Edit, Bash, Grep, Glob
skills:
  - simplify-code
---

Follow the preloaded `simplify-code` skill. The caller's message is the whole contract: behavior contract, comparison base, changed paths, and passing commands. Return the skill's three-part report.
