---
name: pr-body
description: Write a pull request title and body. Use when you open a PR, when a push changes what a PR does, or when asked to describe a PR.
---

# PR Body

The reader is a reviewer who has not seen the work. Give them what the diff
cannot: why, the shape of the change, the evidence, and the risk. GitHub shows
checks, commits and review threads live, so the body links to them.

Based on `show-me` by Dex Horthy (HumanLayer) and `pr` by Matt Pocock.

## Steps

1. Read the whole diff against the base branch, the intent or issue, and the
   review findings. Write the body new from the current diff each time.
2. Write the title in the style of `git log --oneline -20`.
3. Write the body in the shape below. A one-idea PR gets one paragraph and
   Evidence.
4. Publish with `gh pr create --body-file` or `gh pr edit --body-file`. In a
   repo with `scripts/gate/gate`, then run `gate card`; it appends the gate
   record.
5. Done when each claim traces to the diff, a test or a command output, and a
   reviewer can answer from the body alone: why, what changed, how do we know,
   and what can break.

## Shape

```markdown
<One or two sentences: what was wrong before this PR, and what is true after.>

## What changed

<The smallest sketch that shows the change: before-and-after text, a short diff
excerpt, pseudocode, or a mermaid diagram. Link the files. For a PR across
several subsystems, add a mermaid map and say where to start reading.>

## Evidence

<Before and after: a named test that fails on the base and passes here, a
number with the command that made it, a screenshot, or a transcript. Name what
you did not check.>

## Merge danger

**Door:** one-way or two-way, and how to undo it.
**Blast radius:** what breaks, and for whom, if this is wrong.

## Attention

<One to three items for the reviewer: an open or deferred review finding, the
riskiest file, an assumption. Link each one.>

Writer: <model>
```
