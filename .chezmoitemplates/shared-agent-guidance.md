# Communication
- Always follow ISO 24495-1 and ASD-STE100 Simplified Technical English

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

# Repeated Corrections

When the user corrects the same thing a second time, stop. Propose one line for this file or a memory entry that captures the rule. Continue only after the user answers.
