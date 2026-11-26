# Profiles

Initialization stores profile choices in the machine-local Chezmoi config.

| Profile | Contents |
| --- | --- |
| Base | Zsh, Git, GitHub CLI behavior, Homebrew intent |
| AI | Shared instructions, Antigravity/Claude/Codex/Cursor/OpenCode2/Pi routing, 10 repository-owned skills, and 11 public dotagents declarations |
| Editor | Cursor preferences, cmux shortcuts, cspell dictionary |
| AWS | Locally rendered SSO profiles from prompted account metadata |
| Personal | Pi models for personal subscriptions, Bedrock and Workers AI; the Sentry and Codex Claude plugins; Claude auto memory. Off by default, so a machine without the flag keeps the default Pi models, has those plugins and auto memory off, and on macOS gets the hourly `t3-fork-sync` LaunchAgent and the `storage-keeper` LaunchAgent, which every 6 hours removes agent scratch folders and build folders of finished T3 Code threads and logs free space. Every macOS machine, with or without the flag, gets the `cargo-build-gc` LaunchAgent, which every 15 minutes empties old Cargo build folders under `~/.cargo/build` |

Initialization also asks for `executor_url`, the hosted Executor MCP address.
When set, it configures Executor for Antigravity, OpenCode and Pi. The private
address stays in the machine-local config and out of this repository.

OpenCode also gets local stdio entries for the DaVinci Resolve MCP and the
Blender Lab MCP bridge, each only where that app is installed. They run on the
same machine as the app, so they do not go through the hosted Executor.

The macOS-only Brewfile, Cursor paths, and cmux configuration are ignored on
other operating systems.
