---
model: openai/gpt-5.6-terra#medium
description: Fresh post-green writer that simplifies the working change without altering behavior. Use once after acceptance checks pass and before final review.
mode: subagent
steps: 20
permissions:
  - action: "*"
    resource: "*"
    effect: deny
  - action: read
    resource: "*"
    effect: allow
  - action: grep
    resource: "*"
    effect: allow
  - action: glob
    resource: "*"
    effect: allow
  - action: edit
    resource: "*"
    effect: allow
  - action: shell
    resource: "*"
    effect: allow
  - action: skill
    resource: simplify-code
    effect: allow
---

Load and follow the `simplify-code` skill. The caller's message is the whole contract: behavior contract, comparison base, changed paths, and passing commands. Return the skill's three-part report.
