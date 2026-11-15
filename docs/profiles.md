# Profiles

Initialization stores profile choices in the machine-local Chezmoi config.

| Profile | Contents |
| --- | --- |
| Base | Zsh, Git, GitHub CLI behavior, Homebrew intent |
| AI | Shared instructions, Claude/Codex/OpenCode2/Pi routing, one repository-owned skill, and 14 public dotagents pins |
| Editor | Cursor preferences, cmux shortcuts, cspell dictionary |
| AWS | Locally rendered SSO profiles from prompted account metadata |
| Personal | Pi models for personal subscriptions, Bedrock and Workers AI; the Sentry, Plannotator and Codex Claude plugins; the Plannotator Codex Stop hook; Claude auto memory. Off by default, so a machine without the flag keeps the default Pi models, has those plugins and auto memory off, and on macOS gets the hourly `t3-fork-sync` LaunchAgent |

The macOS-only Brewfile, Cursor paths, and cmux configuration are ignored on
other operating systems.
