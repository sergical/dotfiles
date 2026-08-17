# Agent Context Loading

`~/.agents/AGENTS.md` is shared source, not a universal runtime location. Each
harness reaches that guidance through its own supported context path.

## Local Wiring

| Harness | Global context target | How shared guidance arrives |
| --- | --- | --- |
| Claude Code | `~/.claude/CLAUDE.md` | Explicit `@~/.agents/AGENTS.md` import, followed by Claude-only policy |
| Codex | `~/.codex/AGENTS.md` | Chezmoi renders the shared template, then appends Codex-only delegation policy |
| OpenCode2 | `~/.config/opencode/AGENTS.md` | Symlink to `~/.agents/AGENTS.md` |
| Pi | `~/.pi/agent/AGENTS.md` | Symlink to `~/.agents/AGENTS.md` |

Nothing discovers `~/.agents/AGENTS.md` by that path. The import, rendered
copy, and symlinks are the compatibility layer.

## Primary-session Order

### Claude Code

Claude loads managed instructions when present, user
`~/.claude/CLAUDE.md`, then project instructions from ancestors down to the
working directory. Project sources include `CLAUDE.md`, `CLAUDE.local.md`,
`.claude/CLAUDE.md`, applicable `.claude/rules/*.md`, and the repository's
auto-memory prefix. Imports inside loaded instruction files are expanded.
Descendant instructions and path-scoped rules may load later when Claude reads
files in their scope.

### Codex

Codex loads `~/.codex/AGENTS.override.md` when it exists and is non-empty;
otherwise it loads `~/.codex/AGENTS.md`. It then walks from the project root to
the working directory and chooses at most one file per directory:

1. `AGENTS.override.md`
2. `AGENTS.md`
3. configured fallback filenames

Nearer project files appear later. Codex custom agent TOML files configure a
spawned child; their full bodies are not primary-session project guidance.

### OpenCode2 V2

OpenCode2 loads `~/.config/opencode/AGENTS.md`, then every literal `AGENTS.md`
from the active Location upward, nearest first. It does not use the V1
`CLAUDE.md` fallback. A descendant `AGENTS.md` is injected after a successful
read in that descendant and is recorded once in the session.

The V2 schema accepts an `instructions` array, but the current beta does not
resolve those entries into model context. The local configuration therefore
does not use that field. The complete routing policy lives directly in the
primary `~/.config/opencode/agents/build.md` profile, where V2 loads it as the
coordinator's system prompt.

### Pi

Pi first selects its base or custom `SYSTEM.md`, then appends
`APPEND_SYSTEM.md`. It adds the global context winner and one winner from every
filesystem directory from root to the working directory. The per-directory
precedence is:

1. `AGENTS.override.md`
2. `AGENTS.md`
3. `AGENTS.MD`
4. `CLAUDE.md`
5. `CLAUDE.MD`

`--no-context-files` disables the AGENTS/CLAUDE layer. Current Pi subagent
profiles use append mode with conversation inheritance disabled. Each fresh
child receives the parent's effective system prompt, including shared and
project instructions, but does not receive the parent's chat history. Its task
prompt must still be self-contained.

## Projects Under `~/src`

There is no shared ancestor context at `~/src`: `~/src/AGENTS.md`,
`~/src/CLAUDE.md`, and `~/src/CLAUDE.MD` are intentionally absent. Project
instructions begin inside each repository. Do not add a `~/src` instruction
file casually: OpenCode2 and Pi can apply it broadly. Codex normally stops at
each repository's Git root.

At a repository root, the intended effective order is global harness guidance,
then that repository's own context. In nested working directories, Claude,
Codex, and Pi layer ancestors toward the working directory. OpenCode2 emits its
initial project files in the reverse direction, from Location upward.

## Verification

- Claude Code: inspect `/context` and use `InstructionsLoaded` when testing lazy
  descendant rules.
- Codex: use `codex debug prompt-input` and search the resulting JSON for unique
  sentinels and custom role names.
- OpenCode2: use disposable global, root, and nested `AGENTS.md` sentinels;
  compare context before and after reading a nested file.
- Pi: compare a disposable fixture with and without `--no-context-files`; test a
  child separately to confirm append mode carries the parent's effective
  shared and project instructions without conversation history.

Primary references: [Claude Code memory](https://code.claude.com/docs/en/memory),
[Codex AGENTS.md discovery](https://developers.openai.com/codex/guides/agents-md),
[OpenCode2 instructions](https://opencode.ai/v2/docs/instructions), and
[Pi context files](https://github.com/earendil-works/pi/blob/main/packages/coding-agent/docs/usage.md#context-files).
