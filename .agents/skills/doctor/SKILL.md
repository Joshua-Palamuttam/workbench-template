---
name: doctor
description: Run workbench environment diagnostics. Checks config, junctions, worktrees, shell profile, tools, and MCP.
---

# Doctor

Run the diagnostic script and present results conversationally.

## Instructions

1. Run `bash "$REPO_ROOT/scripts/doctor.sh" --json` (where $REPO_ROOT is the workbench repo root) to get diagnostic output
2. If the script doesn't exist yet or --json isn't supported, run `bash "$REPO_ROOT/scripts/doctor.sh"` and parse the text output
3. Present results grouped by category: Config, Junctions, Worktrees, Shell Profile, Tools, MCP
4. For any FAIL or WARN items, explain the issue and offer to fix it:
   - Broken junction? Offer to run setup.sh
   - Missing config? Offer to create from template
   - Stale worktrees? Offer to run wt-cleanup
   - Shell profile not configured? Offer to add the source line
5. If everything passes, confirm the environment is healthy

## Skill Validation

After the environment diagnostics, also run `bash "$REPO_ROOT/scripts/validate-skills.sh"` to check:
- Every skill directory has a SKILL.md with valid frontmatter
- Global skills in config.yaml have matching directories
- No broken symlinks in .claude/skills/
- Python hooks are syntactically valid and have the WB_HOOKS_DISABLED kill switch

Present skill validation results alongside the environment diagnostics.

## Example Invocation

User: /doctor
Agent: Runs scripts/doctor.sh, then scripts/validate-skills.sh, parses output, presents findings with fix suggestions
