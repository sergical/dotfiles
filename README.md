# Dotfiles

Portable macOS development configuration managed with
[Chezmoi](https://www.chezmoi.io/). The repository contains reviewed public
intent only: no credentials, OAuth state, account identifiers, private skill
contents, conversations, caches, or generated application databases.

## Install

Install Chezmoi, initialize without applying, inspect the diff, then apply:

```sh
brew install chezmoi
chezmoi init sergical
git -C "$(chezmoi source-path)" config core.hooksPath .githooks
chezmoi diff
chezmoi apply
brew tap oven-sh/bun
brew trust --formula oven-sh/bun/bun
brew bundle install --no-upgrade --file=~/.Brewfile
```

Initialization asks for Git identity and whether to enable AI, editor, and AWS
profiles. AWS account and SSO values are written only to the machine-local
Chezmoi config and rendered into `~/.aws/config`; they never enter this repo.
The shell loads an existing Oh My Zsh installation when present but does not
take ownership of or rewrite that external checkout.

## Update

`chezmoi update` is configured as a fast-forward-only pull followed by apply.
It fails instead of rebasing or autostashing divergent local source changes.

```sh
chezmoi update
"$(chezmoi source-path)/scripts/install-public-skills.sh"
```

The 51 public skills are commit-pinned in `~/.agents/agents.toml`. Shared global
agent instructions live in `~/.agents/AGENTS.md` and are linked into Pi,
OpenCode, and Claude Code's default global instruction paths. The installer
restores user-only OpenCode metadata after every dotagents update.

Package changes remain explicit:

```sh
brew bundle check --no-upgrade --file=~/.Brewfile
brew bundle install --no-upgrade --file=~/.Brewfile
```

The formula-level trust above is intentionally limited to Bun's official
formula. Do not disable Homebrew tap-trust checks or trust unrelated taps.

## Safety

- Edit individual targets with `chezmoi edit`; never run blanket
  `chezmoi re-add`.
- Capture target-side drift with `dotcapture <target-path>...`
  (`scripts/capture.sh`): re-adds only the named paths, runs the allowlist and
  gitleaks checks, then commits and pushes.
- Review `chezmoi diff` before applying.
- Run `scripts/check-source.sh` before committing.
- Keep identities, signing keys, work aliases, secrets, and auth state in local
  includes such as `~/.gitconfig.local` and `~/.zshrc.local`, or in
  application-owned credential stores.

See [architecture](docs/architecture.md), [profiles](docs/profiles.md), and
[security](docs/security.md) for the repository boundaries.
Repository maintenance and skill lifecycle instructions are in
[`AGENTS.md`](AGENTS.md).
