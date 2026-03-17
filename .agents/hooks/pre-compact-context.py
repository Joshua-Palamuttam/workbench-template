#!/usr/bin/env python3
"""PreCompact hook: Extract critical context before context compression.

Preserves:
1. Daily plan context (priorities, blockers, DMs)
2. Active /forge session state (phase, decisions, elicited user context)
"""

import glob
import json
import os
import re
import sys
from datetime import datetime

# Kill switch: disable non-safety hooks when WB_HOOKS_DISABLED is set
if os.environ.get("WB_HOOKS_DISABLED"):
    sys.exit(0)

# Compute repo root from script location (.agents/hooks/ -> repo root)
# Also handle .claude/hooks/ junction path
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
if os.path.basename(os.path.dirname(SCRIPT_DIR)) == ".agents":
    REPO_ROOT = os.path.dirname(os.path.dirname(SCRIPT_DIR))
elif os.path.basename(os.path.dirname(SCRIPT_DIR)) == ".claude":
    REPO_ROOT = os.path.dirname(os.path.dirname(SCRIPT_DIR))
else:
    REPO_ROOT = os.path.dirname(os.path.dirname(os.path.dirname(SCRIPT_DIR)))


def extract_daily_plan_context():
    """Extract critical daily plan context."""
    daily_path = os.path.join(REPO_ROOT, "context", "active", "daily.md")
    if not os.path.exists(daily_path):
        return []

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

    for line in content.split("\n"):
        if line.startswith("# Daily Plan"):
            output.append(line)
            break

    if "Capacity Today" in sections:
        output.append("\n## Capacity Today")
        output.append(sections["Capacity Today"].strip())

    if "Top Priorities" in sections:
        output.append("\n## Top Priorities (remaining)")
        for line in sections["Top Priorities"].split("\n"):
            line = line.strip()
            if line and "[ ]" in line:
                output.append(f"  {line}")

    if "End of Day" in sections:
        for line in sections["End of Day"].split("\n"):
            if "Blockers:" in line and line.strip() != "- Blockers: any":
                output.append(f"\n## Blockers\n  {line.strip()}")

    if "DMs and @Mentions" in sections:
        dm_lines = [l.strip() for l in sections["DMs and @Mentions"].split("\n") if "[ ]" in l]
        if dm_lines:
            output.append("\n## Unanswered DMs")
            for line in dm_lines:
                output.append(f"  {line}")

    output.append("\n=== End daily plan context ===")
    return output


def find_active_forge_plan():
    """Find the most recently updated active /forge plan."""
    plans_dir = os.path.join(REPO_ROOT, "context", "plans", "active")
    if not os.path.isdir(plans_dir):
        return None

    latest_plan = None
    latest_mtime = 0

    for plan_dir in glob.glob(os.path.join(plans_dir, "*")):
        state_path = os.path.join(plan_dir, "state.md")
        if os.path.exists(state_path):
            mtime = os.path.getmtime(state_path)
            if mtime > latest_mtime:
                latest_mtime = mtime
                latest_plan = plan_dir

    return latest_plan


def extract_forge_context(plan_dir):
    """Extract /forge session state for preservation across compaction."""
    state_path = os.path.join(plan_dir, "state.md")
    if not os.path.exists(state_path):
        return []

    plan_name = os.path.basename(plan_dir)

    with open(state_path, "r", encoding="utf-8") as f:
        state_content = f.read()

    output = []
    output.append(f"\n=== /forge Plan Context: {plan_name} (preserved across compaction) ===")
    output.append(f"Plan directory: context/plans/active/{plan_name}/")

    # Extract current phase and iteration
    for line in state_content.split("\n"):
        line = line.strip()
        if line.startswith("- Phase:"):
            output.append(f"Current {line}")
        elif line.startswith("- Iteration:"):
            output.append(f"Current {line}")
        elif line.startswith("- Depth:"):
            output.append(f"Current {line}")
        elif line.startswith("- Plan version:"):
            output.append(f"Current {line}")

    # Extract user context section
    in_user_context = False
    user_context_lines = []
    for line in state_content.split("\n"):
        if "User Context" in line and line.startswith("##"):
            in_user_context = True
            continue
        elif in_user_context and line.startswith("##"):
            break
        elif in_user_context and line.strip():
            user_context_lines.append(line)

    if user_context_lines:
        output.append("\n## User Context (from INTAKE)")
        output.extend(user_context_lines)

    # Extract decisions
    in_decisions = False
    decision_lines = []
    for line in state_content.split("\n"):
        if line.strip().startswith("##") and "Decision" in line:
            in_decisions = True
            continue
        elif in_decisions and line.startswith("##"):
            break
        elif in_decisions and line.strip() and "|" in line and "---" not in line and "#" not in line:
            decision_lines.append(line)

    if decision_lines:
        output.append(f"\n## Decisions Made ({len(decision_lines)} total)")
        for line in decision_lines:
            output.append(line)

    # List existing artifacts
    artifacts = []
    for f in os.listdir(plan_dir):
        if f.endswith(".md") and f != "state.md":
            artifacts.append(f)
    if artifacts:
        output.append(f"\n## Artifacts: {', '.join(sorted(artifacts))}")

    # Write continuation.md for session handoff
    continuation_path = os.path.join(plan_dir, "continuation.md")
    continuation = []
    continuation.append(f"# /forge Continuation: {plan_name}")
    continuation.append(f"\nGenerated by PreCompact hook at {datetime.now().isoformat()}")
    continuation.append(f"\nTo resume: `/forge {plan_name}`")
    continuation.append(f"\n## State at compaction time")
    continuation.append(state_content)
    continuation.append(f"\n## Available artifacts")
    for a in sorted(artifacts):
        continuation.append(f"- {a}")

    with open(continuation_path, "w", encoding="utf-8") as f:
        f.write("\n".join(continuation))

    output.append(f"\nContinuation saved to: context/plans/active/{plan_name}/continuation.md")
    output.append(f"To resume this plan: `/forge {plan_name}`")
    output.append(f"\n=== End /forge plan context ===")

    return output


def main():
    output = []

    # 1. Daily plan context
    output.extend(extract_daily_plan_context())

    # 2. Active /forge plan context
    active_plan = find_active_forge_plan()
    if active_plan:
        output.extend(extract_forge_context(active_plan))

    if output:
        print("\n".join(output))


if __name__ == "__main__":
    main()
