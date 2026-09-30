# Communication
- Always follow ISO 24495-1 and ASD-STE100 Simplified Technical English

# cmux Scope

Apply cmux instructions and load cmux skills only when the agent was launched
inside a cmux terminal. Use the session context and caller-provided
`CMUX_WORKSPACE_ID` / `CMUX_SURFACE_ID` as evidence. An installed or open cmux
app is not evidence that the agent runs inside it.

In Codex desktop/GUI or any session outside a cmux terminal, skip cmux
instructions, skills, discovery, socket access, and pane operations. Shell
tools and tool-created PTYs do not make a GUI session a cmux terminal session.
Do not fall back to the focused cmux workspace or ask the user to start cmux.

# Dev Servers

Never start dev servers as background processes on localhost ports. Orphaned
children occupy ports and cannot be seen or managed. Instead, run dev servers
through `portless` for stable named `.localhost` URLs without port conflicts.
Inside a cmux terminal, run them in a separate pane in the current workspace:
load the `cmux` and `cmux-workspace` skills first, create the pane additively,
and never steal focus.
Outside cmux, use the current environment's managed terminal or process
session so the server remains visible and can be stopped. Do not block server
startup or verification on cmux access.

# No Embedded cmux Browser

The cmux embedded browser is disabled in settings and must never be used.
Never create browser panes or surfaces (`cmux new-pane --type browser`,
`cmux new-surface --type browser`): cmux won't create an embedded pane — it
silently opens the URL in the system default browser and reports OK, so
retrying just opens duplicate tabs. To show the user a URL, print it once in
the response and let them open it. (`agent-browser` for automated QA is
separate and still fine.)

# Verification Loops

Verify with the cheapest proof that can go red: a test, `curl`, or a typecheck.
Use `agent-browser` when the proof exists only in a rendered page: layout at
set widths, focus and keyboard flow, computed styles, console errors, media
playback, charts, or a multi-step UI flow. For a refactor, one page load with a
clean console is the proof. Read docs with web fetch; use the user's Chrome for
sites that need their login. While the user iterates with you on a page they
have open, let them check it.

Run each browser check as a probe with one question:
- Name the session, and write down what you need to see before the first `open`.
- Take one snapshot or screenshot per question. After a fix, re-check only what
  the fix changed.
- When a call hangs, the browser cannot start, the dev server is down, or the
  sandbox blocks the socket, stop and report the blocker.
- Close the session (`agent-browser --session <name> close`) before you report.
  The check is done when `agent-browser session list` no longer shows it.

Run the acceptance checks once, after the last edit of a batch. A repeat run
needs a new edit in between; a green result stays green until the code changes.
For a change of three edits or fewer, run the scoped check for the changed
files (one lint or typecheck command) and skip the full suite and the
simplification pass. Prototype and throwaway routes get the scoped check only.

# Post-green Simplification

After a task adds or materially changes production or test code, first make the
acceptance checks green. Then run one fresh-context simplification pass before
the final independent review. Give the simplifier the request, comparison base,
changed paths, and exact passing commands; do not give it the implementer's
reasoning. Use the `simplify-code` skill, rerun the same checks after its edits,
and accept a no-op when the diff is already simple. Keep one writer active at a
time. Skip this stage for documentation-only, generated, vendored, snapshot,
lockfile, formatting-only, and mechanical configuration changes.

# Comments

Code should be self-documenting. Comments should be additive in value.
Not describing a decision that was made. But provide more context to the code,
that otherwise would be hard to infer.
