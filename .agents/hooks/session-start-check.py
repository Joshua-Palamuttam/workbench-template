#!/usr/bin/env python3
"""SessionStart hook: Check if daily and weekly plans exist and are current."""

import os
import sys
from datetime import datetime, date

# Compute repo root from script location (.claude/hooks/ -> repo root)
REPO_ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

def main():
    today = date.today()
    today_str = today.strftime("%Y-%m-%d")
    messages = []

    # Check daily plan
    daily_path = os.path.join(REPO_ROOT, "context", "active", "daily.md")
    if os.path.exists(daily_path):
        with open(daily_path, "r", encoding="utf-8") as f:
            first_lines = f.read(500)
        if today_str in first_lines:
            # Extract a quick summary — look for Capacity and Top Priorities
            lines = first_lines.split("\n")
            for line in lines:
                if "Committed:" in line or "Remaining:" in line:
                    messages.append(f"Daily plan ({today_str}): {line.strip()}")
                    break
            else:
                messages.append(f"Daily plan exists for {today_str}.")
        else:
            messages.append(f"Daily plan exists but is NOT for today ({today_str}). Consider running morning-triage to create today's plan.")
    else:
        messages.append("No daily plan found. Run the morning-triage agent to create one.")

    # Check weekly plan
    weekly_path = os.path.join(REPO_ROOT, "context", "active", "weekly.md")
    if os.path.exists(weekly_path):
        with open(weekly_path, "r", encoding="utf-8") as f:
            first_lines = f.read(500)
        # Check if it mentions this week (by checking for a recent date)
        week_number = today.isocalendar()[1]
        year = today.year
        week_str = f"W{week_number:02d}"
        year_str = str(year)
        if week_str in first_lines or today_str in first_lines:
            messages.append(f"Weekly plan is current ({year_str}-{week_str}).")
        else:
            messages.append(f"Weekly plan may be stale (expected {year_str}-{week_str}). Consider running weekly-plan agent.")
    else:
        messages.append("No weekly plan found. Run the weekly-plan agent to create one.")

    if messages:
        print("\n".join(messages))

if __name__ == "__main__":
    main()
