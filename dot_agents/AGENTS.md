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
