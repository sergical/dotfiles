# Skill Inventory

Skill IDs are invocation contracts. Keep upstream-managed IDs unchanged so
package updates, cross-skill references, and health checks continue to work.
Use provenance inventory instead of renaming vendor skills merely to group the
catalog.

Run the installed inventory command to group the effective catalog by source:

```sh
skill-inventory
skill-inventory matt
skill-inventory --model-visible
skill-inventory --manual-only matt
skill-inventory plannotator
skill-inventory private
```

`--model-visible` shows skills advertised for automatic model invocation.
`--manual-only` shows skills retained for explicit invocation but omitted from
the automatic listing. These filters compose with the provenance substring.

The command reconciles four local sources:

- `~/.agents/agents.lock` for commit-pinned dotagents skills;
- `~/.agents/.agent-skills-private` for the owner-only private installer;
- `~/.agents/.agent-skill-sources-private.json` for private upstream families;
- `~/.agents/.skill-lock.json` for installer-managed skills such as
  Plannotator;
- repository-owned or otherwise unmanaged installed directories.

Private ownership wins when two installers use the same ID. The report marks
the masked source explicitly. It also shows when a directory ID and the
frontmatter `name` differ.

## Naming Policy

Use a source prefix for a new skill when the source owns the ID and the prefix
improves discovery. Existing `emil-*`, `uish-*`, `plannotator-*`, and `cmux-*`
families follow this pattern.

Preserve a third-party canonical ID when an installer owns the directory. Add a
prefix only after the installer and every consuming harness support aliases, or
after deliberately vendoring the skill and migrating every cross-reference.
Matt Pocock's public pack currently falls into this category; use `ask-matt` as
its router and `skill-inventory matt` as its provenance view.

When adding, removing, or changing an installer, verify that every installed
skill appears under a known source and review any override before accepting it.
