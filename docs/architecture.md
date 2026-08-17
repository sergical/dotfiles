# Architecture

Chezmoi owns portable configuration. Git synchronizes source; Chezmoi renders
machine-local data and applies reviewed target changes.

The public boundary contains shell behavior, Git defaults, package intent,
selected editor preferences, portable routing and agent definitions for Claude,
Codex, OpenCode2, and Pi, a repository-owned simplification skill, and
commit-pinned public skill declarations. Application auth, sessions, generated
state, work configuration, and licensed skill contents remain outside this
repository.

Tool-owned auth, MCP server definitions, and runtime state remain outside
Chezmoi so this repository never competes with application-owned auth or
runtime files.

Routing is policy-driven inside each harness. Chezmoi provides the same
deterministic definitions on every machine; it does not provide a cross-harness
runtime or move authentication between providers. See `docs/agent-routing.md`
for the configuration boundaries and release procedure.

Normal synchronization uses `chezmoi update`, whose generated local config runs
`git pull --ff-only` before apply. High-churn package upgrades and skill installs
remain explicit commands. The public skill installer also translates upstream
user-only metadata for OpenCode without changing model-invoked skills.
