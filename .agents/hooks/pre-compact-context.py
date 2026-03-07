#!/usr/bin/env python3
"""PreCompact hook: Extract critical context from daily plan before context compression."""

import os
import re
import sys

# Compute repo root from script location (.claude/hooks/ -> repo root)
REPO_ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

def main():
    daily_path = os.path.join(REPO_ROOT, "context", "active", "daily.md")
    if not os.path.exists(daily_path):
        return

    with open(daily_path, "r", encoding="utf-8") as f:
        content = f.read()

    sections = {}
    current_section = None
    current_lines = []

    for line in content.split("\n"):
        if line.startswith("## "):
            if current_section:
                sections[current_section] = "\n".join(current_lines)
            current_section = line[3:].strip()
            current_lines = []
        else:
            current_lines.append(line)
    if current_section:
        sections[current_section] = "\n".join(current_lines)

    output = []
    output.append("=== Daily Plan Context (preserved across compaction) ===")

    # Extract date from title
    for line in content.split("\n"):
        if line.startswith("# Daily Plan"):
            output.append(line)
            break

    # Capacity
    if "Capacity Today" in sections:
        output.append("\n## Capacity Today")
        output.append(sections["Capacity Today"].strip())

    # Top Priorities (only incomplete ones)
    if "Top Priorities" in sections:
        output.append("\n## Top Priorities (remaining)")
        for line in sections["Top Priorities"].split("\n"):
            line = line.strip()
            if line and "[ ]" in line:
                output.append(f"  {line}")

    # Blockers
    if "End of Day" in sections:
        for line in sections["End of Day"].split("\n"):
            if "Blockers:" in line and line.strip() != "- Blockers: any":
                output.append(f"\n## Blockers\n  {line.strip()}")

    # DMs needing response
    if "DMs and @Mentions" in sections:
        dm_lines = [l.strip() for l in sections["DMs and @Mentions"].split("\n") if "[ ]" in l]
        if dm_lines:
            output.append("\n## Unanswered DMs")
            for line in dm_lines:
                output.append(f"  {line}")

    output.append("\n=== End preserved context ===")
    print("\n".join(output))

if __name__ == "__main__":
    main()
