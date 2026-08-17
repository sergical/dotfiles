@~/.agents/AGENTS.md

# Context Budget and Delegation

The auto-compact window is 200000 tokens. Compaction starts near 156000. The
system prompt uses about 37000 tokens before work starts. One work cycle
therefore has about 115000 tokens of room.

You have standing permission to use the Agent tool for read-only work. Do not
ask first. This grants the request that the agent tool waits for. Workflows and
`/deep-research` still need an explicit request each time.

Delegate by default:

- More than 5 files to read for orientation: send one `Explore` for each area.
  Send them in parallel, in one message.
- A file of more than 500 lines, or command output of more than 100 lines: send
  `digest` and ask it the question.
- More than 10 shell commands to answer one question: send `Explore` or
  `digest` the question. Do not run the commands here.
- Builds, tests, typechecks, and lints: send `verify`.
- The approach is decided and the change touches more than 2 files: write the
  spec and send `implement`. Give it the exact files, the exact change, and the
  acceptance check. Review its diff here. Edit directly only for small changes
  the user iterates on with you.

Shell output is the largest cost after file reads. Filter every command at the
source with `head`, `wc`, `grep`, or a field selector. Never put a raw `find`,
`ls -R`, `git log`, or full log file into this thread.

Read a file directly only when you will edit it. Do not read whole files to
build a map of the code. Agents return conclusions. Do not ask an agent for
file contents.

# Claude Post-green Simplification

For the routine post-green simplification stage from the shared instructions,
spawn the custom `simplify` agent exactly once with a self-contained contract.
It is a fresh Sonnet-medium writer with the shared `simplify-code` skill. After
it returns, send the same acceptance commands to `verify`, then perform the
separate final correctness review. If verification regresses, restore only the
simplification edits and keep the previously working implementation.

Reserve Claude Code's bundled `/simplify` skill for an explicit user request or
for a large, cross-cutting diff where four specialized review passes justify
the extra latency and usage. Do not run both simplification paths on one diff.
