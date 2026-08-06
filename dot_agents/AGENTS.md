# Dev Servers

Never start dev servers as background processes on localhost ports. Orphaned
children occupy ports and cannot be seen or managed. Instead, run dev servers
through `portless` for stable named `.localhost` URLs without port conflicts.
Run them in a separate terminal pane in the current cmux workspace: load the
`cmux` and `cmux-workspace` skills first, create the pane additively, and never
steal focus.

# No Embedded cmux Browser

The cmux embedded browser is disabled in settings and must never be used.
Never create browser panes or surfaces (`cmux new-pane --type browser`,
`cmux new-surface --type browser`): cmux won't create an embedded pane — it
silently opens the URL in the system default browser and reports OK, so
retrying just opens duplicate tabs. To show the user a URL, print it once in
the response and let them open it. (`agent-browser` for automated QA is
separate and still fine.)

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
