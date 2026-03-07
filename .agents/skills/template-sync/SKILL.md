---
name: template-sync
description: Sync safe content to the public template repo using an inverted allowlist.
---

# Template Sync

Sync workbench content to the public template repository.

## Instructions

1. Run `bash scripts/template-sync.sh` to start the sync process
2. The script will:
   - Check for unlisted skills (excluded from template)
   - Show what will be synced
   - Prompt for confirmation
   - Scan for sensitive patterns before pushing
3. If the script finds sensitive patterns, report them and do NOT proceed
4. If the user wants to add a skill to the allowlist first, edit scripts/template-allowlist.yaml
5. Present a summary of what was synced

## Before Syncing

Review the allowlist at scripts/template-allowlist.yaml. Ensure:
- No company-specific skills are listed
- No private content paths are included
- New skills added since last sync are either listed or intentionally excluded

## Example Invocation

User: /template-sync
Agent: Runs the sync script, reviews output, confirms or flags issues
