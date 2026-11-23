# Agent Routing

Chezmoi owns the portable routing policy, deterministic agent definitions, and
the repository-owned skills. Provider authentication, OAuth
state, API keys, sessions, transcripts, caches, and application databases stay
outside the repository.

## Managed Layout

| Target | Chezmoi source | Purpose |
| --- | --- | --- |
| `~/.agents/AGENTS.md` | `dot_agents/AGENTS.md.tmpl` | Shared behavior rendered from the common template |
| `~/.agents/skills/babysit-pr/` | `dot_agents/skills/babysit-pr/` | PR watch, bot review, and clean unwatch procedure, loaded on demand |
| `~/.agents/skills/simplify-code/` | `dot_agents/skills/simplify-code/` | Cleanup of a passing change; runs when the user asks or a review flags unneeded code |
| `~/.agents/skills/dev-servers/` | `dot_agents/skills/dev-servers/` | Rex and dev server procedure, loaded on demand |
| `~/.agents/skills/diff-review/` | `dot_agents/skills/diff-review/` | Cross-provider diff review procedure, loaded on demand |
| `~/.agents/skills/full-send/` | `dot_agents/skills/full-send/` | Hands-off end-to-end implementation, proof, PR, and merge when requested |
| `~/.agents/skills/full-stop/` | `dot_agents/skills/full-stop/` | Same workflow as `full-send`, holding before merge and unwatching once green |
| `~/.agents/skills/pr-body/` | `dot_agents/skills/pr-body/` | Pull request title and body, loaded on demand |
| `~/.agents/skills/video-context/` | `dot_agents/skills/video-context/` | Video transcript and frames through `summarize`, loaded on demand |
| `~/.agents/skills/testing/` | `dot_agents/skills/testing/` | Which tests to write, skip and run, loaded on demand |
| `~/.agents/skills/test-audit/` | `dot_agents/skills/test-audit/` | User-invoked audit that deletes junk tests and adds missing ones |
| `~/.agents/hooks/machine-load-gate.py` | `dot_agents/hooks/executable_machine-load-gate.py` | Check before each shell command: heavy jobs (tests, builds, type checks) wait until fewer than a set number run on the machine. Wired into Claude (`settings.json`), Codex (`hooks.json`, after the user trusts it) and Cursor (`~/.cursor/hooks.json`). OpenCode and Pi have no working adapter yet; they get only the worker limit below |
| `~/.cursor/hooks.json` | `private_dot_cursor/hooks.json` | Calls the check above before each Cursor shell command |
| `~/.zshenv` (one block) | `modify_dot_zshenv` | Worker limit for each test run and build, about a third of the cores |
| `~/.cursor/rules/shared-agent-guidance.mdc` | `private_dot_cursor/rules/shared-agent-guidance.mdc.tmpl` | Always-applied rule rendered from the common template |
| `~/.gemini/AGENTS.md` | `dot_gemini/symlink_AGENTS.md` | Antigravity global context symlink to `~/.agents/AGENTS.md` |
| `~/.gemini/config/skills` | `dot_gemini/config/symlink_skills` | Antigravity global skills symlink to `~/.agents/skills` |
| `~/.claude/` | `private_dot_claude/` | Claude instructions and settings |
| `~/.codex/` | `dot_codex/` | Link to the shared instructions, hooks, and `model_reasoning_effort` in `config.toml`. Codex owns the rest of that file. |
| `~/.config/opencode/` | `private_dot_config/private_opencode/` | OpenCode2 settings and the `plan` agent |
| `~/.pi/agent/` | `private_dot_pi/agent/` | Pi settings and the link to the shared instructions |

The source does not hold custom helper-agent sets for Claude, Codex, OpenCode2
or Pi. Each harness uses its built-in agents. If you add a custom agent again,
add its file to `scripts/check-source.sh` and its rules to
`scripts/check-agent-routing.sh` in the same change.

Context files are not portable by filename alone. See
[agent context loading](context-loading.md) for the supported global path,
project order, nested behavior, and child-context rules in each harness.

## Source-first Update

Prefer source-first changes for normal maintenance:

```sh
chezmoi edit ~/.config/opencode/agents/build.md
chezmoi diff
chezmoi apply ~/.config/opencode/agents/build.md
```

Use the same pattern for Claude, Codex, Pi, and shared skill targets. Source-first
editing keeps the Git review boundary visible before the live configuration
changes.

## Capture A Tested Target

An agent-routing experiment may need to run from the target path first. After
the canary passes, capture only the named files:

```sh
chezmoi re-add ~/.config/opencode/agents/plan.md
```

Use `chezmoi add` once for a new target. Never capture a whole application
directory: it may contain credentials, sessions, transcripts, and caches.
`scripts/capture.sh` also commits and pushes, so use it only when that remote
write is intended.

## Validation And Release

From the source repository:

```sh
./scripts/check-agent-routing.sh
./scripts/check-source.sh
git diff --check
chezmoi diff
```

Review every diff before `chezmoi apply`. For a model, permission, or routing
change, run one disposable canary in the affected harness. For a shared policy
or skill change, run one canary in each affected harness. Require the expected
agent/model/effort, a persisted child transcript, passing acceptance checks,
and a separate final review.

Commit and push only after the source checks, target diff, and canaries pass.
On another machine, use `chezmoi update`, then run
`scripts/install-public-skills.sh` explicitly to reconcile externally pinned
skills.

## Shared Instruction Budget

Keep personal preferences, machine ownership, Rex ownership constraints and
pointers to local workflows in the shared template. Executor supplies its own
MCP instructions; do not copy its tool discovery procedure or account inventory
into global instructions. The same applies to generic coding advice and the
steps already owned by a referenced skill.

Audit rules against the current harness instructions and observed mistakes,
not against the previous file as a required baseline. Use
[Codex best practices](https://learn.chatgpt.com/docs/learn/best-practices) and
[Claude Code best practices](https://code.claude.com/docs/en/best-practices).
A context-loading check proves delivery, not that a rule improves task success.
