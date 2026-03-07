---
name: setup
description: Run one-command workbench setup. Creates junctions, configures shell profile, sets up global skills.
---

# Setup

Run the interactive setup for the workbench environment.

## Instructions

1. Run `bash scripts/setup.sh` to start setup
2. The script handles:
   - Platform detection
   - Config bootstrap (creates config.yaml from template if needed)
   - Junction and symlink creation
   - Shell profile configuration
   - Global skills setup
   - Context directory creation
   - Verification (runs doctor)
3. If any step fails, explain the issue and suggest remediation
4. On Windows, if the CLAUDE.md file symlink fails (requires admin), provide the exact PowerShell command to run in an admin terminal

## Example Invocation

User: /setup
Agent: Runs scripts/setup.sh, monitors output, helps resolve any issues
