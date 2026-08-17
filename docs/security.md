# Security Boundary

Tracked files are an explicit allowlist enforced by `scripts/check-source.sh`.
The pre-commit hook also runs Gitleaks against staged content.

Never track:

- API keys, OAuth tokens, cookies, private keys, or credential helpers with
  embedded secrets
- GitHub `hosts.yml`, Claude local permissions, MCP auth state, or agent
  sessions
- AWS account IDs and SSO URLs as repository literals
- private skill contents, internal prompts, conversations, caches, or databases

Portable public agent prompts and the repository-owned `simplify-code` skill are
allowed. Review every new prompt for machine paths, private repository names,
customer data, and internal-only operating details before adding it.

Chezmoi's `private_` source prefix controls target permissions only. It does not
encrypt source and must not be treated as a secrecy boundary.

Homebrew tap trust is granted narrowly. The setup trusts only Bun's official
formula rather than the entire tap, and never disables Homebrew's trust checks.
