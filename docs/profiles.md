# Profiles

Initialization stores profile choices in the machine-local Chezmoi config.

| Profile | Contents |
| --- | --- |
| Base | Zsh, Git, GitHub CLI behavior, Homebrew intent |
| AI | Shared global agent instructions, Claude portable defaults, and 52 public dotagents pins |
| Editor | Cursor preferences, cmux shortcuts, cspell dictionary |
| AWS | Locally rendered SSO profiles from prompted account metadata |

The macOS-only Brewfile, Cursor paths, and cmux configuration are ignored on
other operating systems. An optional cmux embedded-browser hostname is prompted
during initialization and stored only in machine-local Chezmoi data.
