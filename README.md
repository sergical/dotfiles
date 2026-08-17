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

Public external skills are commit-pinned in `~/.agents/agents.toml`, which holds
14 declarations that currently resolve to 36 installed skills. Chezmoi also
owns the repository-local `simplify-code` skill, for 37 portable public skills
in total. Shared global instructions live in `~/.agents/AGENTS.md`; complete
Claude, Codex, OpenCode2, and Pi agent definitions are managed alongside them.
After every dotagents update the installer runs
`scripts/normalize-opencode-user-skills.rb`, which restores the user-only
OpenCode metadata on each skill whose frontmatter carries
`disable-model-invocation: true`.

## Agent Routing

Routing prompts, model/effort choices, permissions, and custom agents are
portable source. Authentication and runtime state are not. Use source-first
`chezmoi edit`, or capture only named target files after a live canary. Run the
routing and public-source checks before applying or committing:

```sh
./scripts/check-agent-routing.sh
./scripts/check-source.sh
chezmoi diff
```

See [agent routing](docs/agent-routing.md) for the managed layout, target-first
canary workflow, release checks, and atomic roster rules. See
[context loading](docs/context-loading.md) for the exact per-harness instruction
order and the role of `~/.agents/AGENTS.md`.

Use `skill-inventory` to group the effective skill catalog by provenance without
renaming upstream invocation IDs:

```sh
skill-inventory
skill-inventory matt
```

See [skill inventory](docs/skills.md) for source precedence, override reporting,
and the naming policy.

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

See [architecture](docs/architecture.md), [profiles](docs/profiles.md),
[agent routing](docs/agent-routing.md), [context loading](docs/context-loading.md),
and [security](docs/security.md) for the repository boundaries.
Repository maintenance and skill lifecycle instructions are in
[`AGENTS.md`](AGENTS.md).
