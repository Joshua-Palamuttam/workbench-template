#!/usr/bin/env python3
"""PreToolUse hook: Suggest /review-code before committing large diffs.

Non-blocking suggestion. Only fires on git commit commands with 50+ lines changed
when /review-code has not been run in the current session.

Suppress with: SKIP_REVIEW=1 git commit ...
Disable all hooks: WB_HOOKS_DISABLED=1
"""

import json
import os
import re
import subprocess
import sys

# Kill switch: disable non-safety hooks when WB_HOOKS_DISABLED is set
if os.environ.get("WB_HOOKS_DISABLED"):
    sys.exit(0)

# Skip if explicitly suppressed
if os.environ.get("SKIP_REVIEW"):
    sys.exit(0)


def main():
    # Read the hook input from stdin
    try:
        hook_input = json.loads(sys.stdin.read())
    except (json.JSONDecodeError, Exception):
        sys.exit(0)

    # Only fire on Bash tool calls containing 'git commit'
    tool_name = hook_input.get("tool_name", "")
    tool_input = hook_input.get("tool_input", {})
    command = tool_input.get("command", "")

    if tool_name != "Bash" or "git commit" not in command:
        sys.exit(0)

    # Count staged diff lines
    try:
        result = subprocess.run(
            ["git", "diff", "--cached", "--stat"],
            capture_output=True,
            text=True,
            timeout=5,
        )
        lines = result.stdout.strip().split("\n")
        if not lines or not lines[-1]:
            sys.exit(0)

        summary = lines[-1]
        numbers = re.findall(r"(\d+) (?:insertion|deletion)", summary)
        total_changes = sum(int(n) for n in numbers)
    except Exception:
        sys.exit(0)

    if total_changes < 50:
        sys.exit(0)

    # Suggest review
    print(
        json.dumps(
            {
                "message": (
                    f"\U0001f4dd {total_changes} lines changed without /review-code. "
                    "Consider running it first.\n"
                    "   Suppress: SKIP_REVIEW=1 git commit ..."
                ),
                "blocking": False,
            }
        )
    )


if __name__ == "__main__":
    main()
