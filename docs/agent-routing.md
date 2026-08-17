# Agent Routing

Chezmoi owns the portable routing policy, deterministic agent definitions, and
the repository-owned `simplify-code` skill. Provider authentication, OAuth
state, API keys, sessions, transcripts, caches, and application databases stay
outside the repository.

## Managed Layout

| Target | Chezmoi source | Purpose |
| --- | --- | --- |
| `~/.agents/AGENTS.md` | `dot_agents/AGENTS.md.tmpl` | Shared behavior rendered from the common template |
| `~/.agents/skills/simplify-code/` | `dot_agents/skills/simplify-code/` | Shared post-green cleanup contract |
| `~/.claude/` | `private_dot_claude/` | Claude delegation policy and agents |
| `~/.codex/` | `dot_codex/` | Codex global gate and custom agents |
| `~/.config/opencode/` | `private_dot_config/private_opencode/` | OpenCode2 policy and complete roster |
| `~/.pi/agent/` | `private_dot_pi/agent/` | Pi policy, extension settings, and complete roster |

The OpenCode2 and Pi rosters are atomic configuration sets. When a role is
added, renamed, or removed, update the coordinator allowlist, policy text,
agent file, and validation expectations in the same change.

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
chezmoi re-add ~/.config/opencode/agents/build.md
chezmoi re-add ~/.config/opencode/agents/simplify.md
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
agent/model/effort, a persisted child transcript, the same acceptance checks
before and after simplification, and a separate final review.

Commit and push only after the source checks, target diff, and canaries pass.
On another machine, use `chezmoi update`, then run
`scripts/install-public-skills.sh` explicitly to reconcile externally pinned
skills.
