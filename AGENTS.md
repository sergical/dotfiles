# Repository Instructions

This is the public Chezmoi source for `sergical/dotfiles`. Keep every commit
safe for immediate public disclosure. Do not add credentials, account IDs,
private hostnames, work-only configuration, licensed skill contents, sessions,
caches, generated databases, or private repository topology.

## Working Rules

- Edit individual Chezmoi source files. Never run blanket `chezmoi re-add`.
- Keep machine-specific values in the generated local Chezmoi config or an
  unmanaged local include.
- Preserve unrelated target state. Do not make a directory exact unless removal
  of unmanaged children is intentional.
- Pin executable dependencies: GitHub Actions use commit SHAs, Chezmoi uses a
  checked SHA-256, npm uses `package-lock.json`, and dotagents sources use full
  Git commit SHAs.
- Run `scripts/check-source.sh` before every commit. If a new public source path
  is intentional, add its exact path to that script's allowlist.

## Add A Public Skill

Only add a skill here when its source and license permit public use. Paid,
internal, private, or redistribution-restricted skills do not belong in this
repository.

1. Review the skill, its repository ownership, and its license.
2. Resolve and record a full 40-character commit SHA. Never use a branch, tag,
   wildcard ref, or floating default branch as the reproducibility boundary.
3. Add the source organization or repository to `[trust]` in
   `dot_agents/agents.toml` when it is not already trusted.
4. Add a `[[skills]]` entry with `name`, `source`, `ref`, and `path`. Use
   `exclude` for reviewed wildcard packs.
5. Decide whether the skill is model-visible or explicitly user-invoked.
6. Run `scripts/install-public-skills.sh` and verify the installed skill.
7. Update every public-skill count in `README.md`, `docs/profiles.md`, and
   `.github/workflows/validate.yml`.
8. Run all checks, commit, push, and require green public CI.

Example declaration:

```toml
[[skills]]
name = "example-skill"
source = "owner/repository"
ref = "0123456789abcdef0123456789abcdef01234567"
path = "skills/example-skill"
```

## Invocation Mode

Model-visible skills need no compatibility metadata.

An explicitly user-invoked skill must declare:

```yaml
disable-model-invocation: true
metadata:
  opencode/autoinvoke: false
  opencode/slash: true
```

Claude and Pi honor `disable-model-invocation`. OpenCode honors the two metadata
keys. If an upstream public skill has the Claude field but cannot be edited to
add OpenCode metadata, add its ID to `USER_INVOKED_SKILLS` in
`scripts/normalize-opencode-user-skills.rb`. That list is strict: every listed
skill must be installed, remain user-only upstream, and pass `--check` after
normalization.

## Update Or Remove A Public Skill

For an update, review the upstream diff, replace only the exact `ref`, reinstall,
and run the same checks as a new skill.

For removal, delete the declaration and any trust entry used only by that skill.
Update all documented and CI counts. Dotagents owns public installation state;
run the public installer after changing the manifest.

## Validation

Run from the repository root:

```sh
./scripts/check-source.sh
git diff --check
sh -n scripts/check-source.sh scripts/install-public-skills.sh .githooks/pre-commit
ruby -c scripts/normalize-opencode-user-skills.rb
npm ci --ignore-scripts
npx --no-install prettier --check \
  "private_Library/private_Application Support/private_Cursor/private_User/settings.json" \
  "private_Library/private_Application Support/private_Cursor/private_User/keybindings.json"
./scripts/install-public-skills.sh
chezmoi status
chezmoi diff
```

After pushing, verify both Linux and macOS jobs in `.github/workflows/validate.yml`.
