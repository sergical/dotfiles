# Dev Servers

Never start dev servers as background processes on localhost ports. Orphaned
children occupy ports and cannot be seen or managed. Instead, run dev servers
through `portless` for stable named `.localhost` URLs without port conflicts.
Open them in a separate tab in the current cmux workspace: load the `cmux` and
`cmux-workspace` skills first, create the pane additively, and never steal focus.

# Verification Loops

Use `agent-browser` to verify new end-to-end workflows and when asked to test
autonomously or perform visual QA. Do not start a browser session for every
change. For small iterative changes made while collaborating closely, prefer a
quick implementation and let the user check it unless end-to-end, smoke, or
visual verification is needed.

# Comments

Code should be self-documenting. Comments should be additive in value.
Not describing a decision that was made. But provide more context to the code,
that otherwise would be hard to infer.

# HTML Deliverables

When a skill's instructions say to generate an HTML report, dashboard, or
lesson and open it in a browser (improve-codebase-architecture's HTML report,
teach's lessons), do not use the skill's bundled HTML template or hand off via
`open`/`xdg-open`. Build the document following the `plannotator-visual-explainer`
skill's theming and structure (fall back to the skill's own template only if
that skill is unavailable) and deliver it with `plannotator annotate <file>`,
adding `--gate` when the output needs an approve/deny decision. Plannotator's
annotation UI feeds the reader's feedback back to the agent, which a browser
tab cannot. Keep the originating skill's file locations and archives (e.g.
teach's `./lessons/`) unchanged — only the styling source and delivery change.
