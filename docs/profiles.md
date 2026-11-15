# Profiles

Initialization stores profile choices in the machine-local Chezmoi config.

| Profile | Contents |
| --- | --- |
| Base | Zsh, Git, GitHub CLI behavior, Homebrew intent |
| AI | Shared instructions, Claude/Codex/OpenCode2/Pi routing, 4 repository-owned skills, and 10 public dotagents declarations |
| Editor | Cursor preferences, cmux shortcuts, cspell dictionary |
| AWS | Locally rendered SSO profiles from prompted account metadata |
| Personal | Pi models for personal subscriptions, Bedrock and Workers AI; the Sentry and Codex Claude plugins; Claude auto memory. Off by default, so a machine without the flag keeps the default Pi models, has those plugins and auto memory off, and on macOS gets the hourly `t3-fork-sync` LaunchAgent |

Initialization also asks for `executor_url`, the hosted Executor MCP address.
OpenCode and Pi get an `executor` entry only when it is set, so the private
address stays in the machine-local config and out of this repository.

OpenCode also gets local stdio entries for the DaVinci Resolve MCP and the
Blender Lab MCP bridge, each only where that app is installed. They run on the
same machine as the app, so they do not go through the hosted Executor.

The macOS-only Brewfile, Cursor paths, and cmux configuration are ignored on
other operating systems.
