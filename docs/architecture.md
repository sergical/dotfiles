# Architecture

Chezmoi owns portable configuration. Git synchronizes source; Chezmoi renders
machine-local data and applies reviewed target changes.

The public boundary contains shell behavior, Git defaults, package intent,
selected editor preferences, and commit-pinned public skill declarations.
Application auth, sessions, generated state, work configuration, and licensed
skill contents remain outside this repository.

Tool-specific private configuration and local MCP state remain outside Chezmoi
so this repository never competes with application-owned auth or runtime files.

Normal synchronization uses `chezmoi update`, whose generated local config runs
`git pull --ff-only` before apply. High-churn package upgrades and skill installs
remain explicit commands. The public skill installer also translates upstream
user-only metadata for OpenCode without changing model-invoked skills.
