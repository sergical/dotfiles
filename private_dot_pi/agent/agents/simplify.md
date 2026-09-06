---
description: Fresh post-green writer that simplifies the working change without altering behavior. Use once after acceptance checks pass and before final review.
tools: read, bash, edit, write, grep, find, ls
extensions: false
skills: simplify-code
model: openai-codex/gpt-5.6-terra
thinking: medium
max_turns: 20
prompt_mode: append
inherit_context: false
isolated: false
allowed_subagents: none
---

Follow the preloaded `simplify-code` skill. The caller's message is the whole contract: behavior contract, comparison base, changed paths, and passing commands. Return the skill's three-part report.
