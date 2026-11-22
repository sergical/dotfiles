# Repository Instructions

This is the public Chezmoi source for `sergical/dotfiles`. Keep every commit
safe for immediate public disclosure. Do not add credentials, account IDs,
private hostnames, work-only configuration, licensed skill contents, sessions,
caches, generated databases, or private repository topology.

## Change Something

Follow these steps for every change. They are the whole path from an idea to
a machine that runs it.

1. Run `scripts/status.sh`. It prints which machine this is (personal or
   work, and its profile flags), whether the source is in step with GitHub,
   and which files on this machine differ from the source. Clear up anything
   it lists before you start, or say why you leave it.
2. Run `git switch -c <topic> origin/main`. The pre-commit hook refuses a
   commit on `main`.
3. Edit the source files. To try the change on this machine, read
   `chezmoi diff <target>` and then run `chezmoi apply <target>` for each
   target you changed. Never run a bare `chezmoi apply`.
4. Run the checks under Validation, commit, push, and open a pull request.
   Merge it when both jobs in `.github/workflows/validate.yml` pass.
5. Run `git switch main && git pull --ff-only`, then `chezmoi apply <target>`
   again for each changed target. A LaunchAgent that is new also needs
   `launchctl bootstrap gui/$(id -u) <plist>` once.
6. Run `scripts/status.sh` again. The change is done when it shows no
   commits that are not on GitHub, no source edits, and no differing file
   that belongs to your change.

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

## Sources Of Truth

Before a change, identify the system that owns each value:

| System | Owns | Rule |
| --- | --- | --- |
| `origin/main` | Portable configuration for every machine | Run `git pull --ff-only` before you edit. If the branches diverge, stop. Keep unknown local commits on a backup branch. Never force-push. |
| Other machines | Their own render of the same source | A shared template change applies to every machine. Render the template with the data that other machines have today. A missing key must give their current result. |
| Local Chezmoi config | Profile flags and machine data | A new prompt needs a default that keeps other machines unchanged, a flag in `.github/workflows/validate.yml`, and a row in `docs/profiles.md`. |
| Live targets | Drift from apps and installers | Read `chezmoi diff` before `chezmoi apply`. Capture an intended change by named path. Otherwise, apply the source. |

## Trace A Change To Its Machine

Each commit has a `Machine-Profile: personal`, `work` or `unknown` trailer.
`.githooks/prepare-commit-msg` adds it from the local Chezmoi config, and CI
fails a pull request with a commit that has none. To find where a rendered line
came from:

```sh
git log --format='%h %ad %(trailers:key=Machine-Profile,valueonly) %s' \
  --date=short -S'<text of the line>' -- .chezmoitemplates/
```

Commit a change on the machine where it was made. An uncommitted edit that
another machine commits gets the wrong profile.

## Update Agent Routing

Read `docs/agent-routing.md` before changing a shared instruction, custom agent,
model route, permission, or the `simplify-code` skill. Run
`scripts/check-agent-routing.sh` before applying or committing the change.

## Update Skill Inventory

Read `docs/skills.md` before renaming an installed skill or changing installer
ownership. Preserve third-party canonical IDs unless the installer supports an
alias. Run the rendered `skill-inventory` command and account for every
override before committing an installer change.

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
keys. Codex ignores all three and hides a skill only when `agents/openai.yaml`
sets `policy.allow_implicit_invocation: false`;
`scripts/normalize-opencode-user-skills.rb` writes that file for every user-only
skill. It also stops on a repeated frontmatter key, because Codex skips a skill
whose frontmatter repeats a key. If an upstream public skill has the Claude field but cannot be edited to
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
sh -n scripts/check-source.sh scripts/install-public-skills.sh .githooks/pre-commit .githooks/prepare-commit-msg
./scripts/check-agent-routing.sh
ruby -c scripts/normalize-opencode-user-skills.rb
npm ci --ignore-scripts
npx --no-install prettier --check \
  "private_Library/private_Application Support/private_Cursor/private_User/settings.json" \
  "private_Library/private_Application Support/private_Cursor/private_User/keybindings.json"
./scripts/install-public-skills.sh
chezmoi status
chezmoi diff
```

A push is done when the Linux and macOS jobs in
`.github/workflows/validate.yml` pass on its commit.
