---
name: sync-permissions
description: Scan worktree permissions and promote selected ones to global Claude Code settings. Use when user wants to sync, promote, or consolidate permissions across worktrees.
argument-hint: "[--all]"
---

# Sync Worktree Permissions to Global Settings

Scan `.claude/settings.local.json` across worktrees and promote new permissions to `~/.claude/settings.local.json`.

## Process

1. Determine scope:
   - If `--all` flag is passed (or user says "all repos"): scan all repos under WORKTREE_ROOT
   - Otherwise: auto-detect current repo from working directory
2. Run the sync-permissions script:
   ```bash
   bash C:/worktrees-SeekOut/workbench/scripts/windows/wt-sync-permissions.sh [--all]
   ```
3. The script will:
   - Scan all worktree settings files
   - Present new permissions interactively (y/n/all/quit for each)
   - Merge selected permissions into `~/.claude/settings.local.json`
4. Report what permissions were added to global settings

## Notes

- Global permissions in `~/.claude/settings.local.json` apply to ALL projects
- This is useful after accumulating permissions in feature worktrees via "yes and don't ask again"
- The script uses `node` for reliable JSON reading/writing
