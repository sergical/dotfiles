#!/usr/bin/env python3
"""PostToolUse hook: remind the agent to review UI and motion changes.

Reads the hook JSON on stdin (Claude Code or Codex). When a tool call changes
a UI file, it adds context once per session. When the change also touches
motion code, it adds a second reminder once per session.
"""

import json
import os
import re
import sys
import tempfile

UI_FILE = re.compile(r"\.(tsx|jsx|css|scss|sass|less|svelte|vue|astro|html|mdx)$")
SKIP_FILE = re.compile(r"(\.test\.|\.spec\.|\.stories\.|/node_modules/|/dist/|/build/)")
MOTION = re.compile(
    r"@keyframes|animation\s*:|transition\s*[:=]|cubic-bezier|will-change|"
    r"motion/react|framer-motion|AnimatePresence|layoutId|useSpring|useAnimate|"
    r"\banimate\s*=|whileHover|whileTap|\bspring\b|view-transition|startViewTransition"
)

UI_NOTE = (
    "UI files changed in this session. Before you report the work done, run "
    "the emil-ui-review skill on the changed UI and fix what it finds."
)
SKILLS = os.path.expanduser("~/.agents/skills")
REVIEW_ANIMATIONS = next(
    (name for name in ("review-animations", "emil-review-animations")
     if os.path.exists(os.path.join(SKILLS, name, "SKILL.md"))),
    "review-animations",
)
MOTION_NOTE = (
    "Motion code changed in this session. Before you report done, also read "
    f"~/.agents/skills/{REVIEW_ANIMATIONS}/SKILL.md and follow it on the changed "
    "motion (it is manual-only, so read the file instead of calling the Skill tool)."
)


def strings(value):
    if isinstance(value, str):
        yield value
    elif isinstance(value, dict):
        for item in value.values():
            yield from strings(item)
    elif isinstance(value, list):
        for item in value:
            yield from strings(item)


def main():
    try:
        event = json.load(sys.stdin)
    except ValueError:
        return
    tool_input = event.get("tool_input") or {}
    if not isinstance(tool_input, dict):
        tool_input = {"command": tool_input}
    text = "\n".join(strings(tool_input))
    # Changed files only: the path fields of Edit/Write, and the file headers
    # of an apply_patch body. File content that names a UI file does not count.
    paths = [str(tool_input.get(k)) for k in ("file_path", "path") if tool_input.get(k)]
    paths += re.findall(r"^\*\*\* (?:Add|Update) File: (.+?)\s*$", text, re.M)
    paths = [p for p in paths if UI_FILE.search(p)]
    paths = [p for p in paths if not SKIP_FILE.search(p)]
    if not paths:
        return

    session = re.sub(r"[^\w-]", "", str(event.get("session_id") or "unknown"))
    state_dir = os.path.join(tempfile.gettempdir(), "ui-review-reminder")
    os.makedirs(state_dir, exist_ok=True)
    notes = []
    for kind, note, wanted in (
        ("ui", UI_NOTE, True),
        ("motion", MOTION_NOTE, bool(MOTION.search(text))),
    ):
        marker = os.path.join(state_dir, f"{session}.{kind}")
        if wanted and not os.path.exists(marker):
            open(marker, "w").close()
            notes.append(note)
    if notes:
        print(json.dumps({
            "hookSpecificOutput": {
                "hookEventName": "PostToolUse",
                "additionalContext": " ".join(notes),
            }
        }))


if __name__ == "__main__":
    main()
