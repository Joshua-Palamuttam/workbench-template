#!/usr/bin/env python3
"""PostToolUse hook: Log Slack message sends to daily plan notes."""

import json
import os
import sys
from datetime import datetime

# Compute repo root from script location (.claude/hooks/ -> repo root)
REPO_ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

def main():
    daily_path = os.path.join(REPO_ROOT, "context", "active", "daily.md")
    if not os.path.exists(daily_path):
        return

    # Read hook input from stdin
    try:
        hook_input = json.loads(sys.stdin.read())
    except (json.JSONDecodeError, Exception):
        return

    tool_input = hook_input.get("tool_input", {})
    channel = tool_input.get("channel", "unknown")
    text = tool_input.get("text", "")

    # Truncate message for the log
    summary = text[:80].replace("\n", " ")
    if len(text) > 80:
        summary += "..."

    timestamp = datetime.now().strftime("%H:%M")
    log_line = f"- [{timestamp}] Sent Slack message to #{channel}: {summary}\n"

    # Read the daily plan
    with open(daily_path, "r", encoding="utf-8") as f:
        content = f.read()

    # Find the Notes section and append
    if "## Notes" in content:
        # Insert before the next section or at the end of Notes
        parts = content.split("## Notes")
        if len(parts) == 2:
            notes_section = parts[1]
            # Find the next ## section
            next_section_idx = notes_section.find("\n## ", 1)
            if next_section_idx != -1:
                before_next = notes_section[:next_section_idx]
                after_next = notes_section[next_section_idx:]
                new_notes = before_next.rstrip() + "\n" + log_line + after_next
            else:
                new_notes = notes_section.rstrip() + "\n" + log_line
            content = parts[0] + "## Notes" + new_notes
    else:
        # No Notes section -- append one
        content = content.rstrip() + "\n\n## Notes\n" + log_line

    with open(daily_path, "w", encoding="utf-8") as f:
        f.write(content)

if __name__ == "__main__":
    main()
