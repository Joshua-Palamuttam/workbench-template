#!/bin/bash
# wt-status.sh - Show status of all worktrees across all repos
# Usage: wt-status [repo_name]

WORKTREE_ROOT="${WORKTREE_ROOT:-C:/worktrees-SeekOut}"
repo_filter=""
dirty_only=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --dirty) dirty_only=true; shift ;;
        *) repo_filter="$1"; shift ;;
    esac
done

cd "$WORKTREE_ROOT"

echo "📊 Worktree Status Report"
echo "========================="
echo ""

for repo in *.git/; do
    repo_name="${repo%.git/}"

    # Skip if filter specified and doesn't match
    if [ -n "$repo_filter" ] && [ "$repo_name" != "$repo_filter" ]; then
        continue
    fi

    echo "📁 ${repo_name}"
    echo "─────────────────────────────"

    cd "$WORKTREE_ROOT/$repo"

    # List worktrees with branch info
    git worktree list --porcelain | while read -r line; do
        if [[ "$line" == worktree* ]]; then
            wt_path="${line#worktree }"
            wt_name=$(basename "$wt_path")
        elif [[ "$line" == branch* ]]; then
            branch="${line#branch refs/heads/}"

            # Check for uncommitted changes
            if [ -d "$wt_path" ]; then
                changes=$(cd "$wt_path" && git status --porcelain 2>/dev/null | wc -l)
                if [ "$changes" -gt 0 ]; then
                    status="⚠️  ${changes} changes"
                else
                    status="✓ clean"
                fi

                # Check ahead/behind
                ahead_behind=$(cd "$wt_path" && git rev-list --left-right --count HEAD...@{upstream} 2>/dev/null || echo "0 0")
                ahead=$(echo "$ahead_behind" | awk '{print $1}')
                behind=$(echo "$ahead_behind" | awk '{print $2}')

                sync=""
                [ "$ahead" -gt 0 ] && sync+=" ↑${ahead}"
                [ "$behind" -gt 0 ] && sync+=" ↓${behind}"

                if [ "$dirty_only" = true ] && [ "$changes" -eq 0 ]; then
                    continue
                fi
                printf "  %-20s %-30s %s%s\n" "$wt_name" "$branch" "$status" "$sync"
            fi
        fi
    done

    echo ""
    cd "$WORKTREE_ROOT"
done
