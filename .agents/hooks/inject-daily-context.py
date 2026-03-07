#!/usr/bin/env python3
"""UserPromptSubmit hook: Inject daily priorities and capacity as ambient context."""

import os
import sys
from datetime import date

# Compute repo root from script location (.claude/hooks/ -> repo root)
REPO_ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

def main():
    daily_path = os.path.join(REPO_ROOT, "context", "active", "daily.md")
    if not os.path.exists(daily_path):
        return

    today_str = date.today().strftime("%Y-%m-%d")

    with open(daily_path, "r", encoding="utf-8") as f:
        content = f.read()

    # Verify it's today's plan
    if today_str not in content[:200]:
        return

    lines = content.split("\n")

    # Extract capacity
    remaining = None
    committed = None
    for line in lines:
        if "Remaining:" in line:
            remaining = line.strip().lstrip("- ")
        if "Committed:" in line:
            committed = line.strip().lstrip("- ")

    # Extract top 3 incomplete priorities
    priorities = []
    in_priorities = False
    for line in lines:
        if "## Top Priorities" in line:
            in_priorities = True
            continue
        if in_priorities and line.startswith("## "):
            break
        if in_priorities and "[ ]" in line:
            # Clean up the line
            clean = line.strip().lstrip("0123456789. ")
            priorities.append(clean)
            if len(priorities) >= 3:
                break

    if not priorities and not remaining:
        return

    output = []
    output.append(f"[Daily context -- {today_str}]")
    if remaining:
        output.append(f"  {remaining}")
    if committed:
        output.append(f"  {committed}")
    if priorities:
        output.append("  Top priorities remaining:")
        for p in priorities:
            output.append(f"    {p}")

    print("\n".join(output))

if __name__ == "__main__":
    main()
