---
name: plan-feature
description: Manage the feature planning pipeline. Shows active plans, checks status, and tells you what to do next. Delegates to researcher and sounding-board agents for heavy lifting. Use when starting a new feature, resuming an existing plan, or checking status.
argument-hint: [plan-name] [archive]
---

# Feature Planning Orchestrator

Lightweight orchestrator that manages the feature planning pipeline. Checks state, routes to agents, and tracks progress across the research → refine → plan lifecycle.

## Usage

- **No arguments**: Show status of all active plans
- **`<plan-name>`**: Check status of a specific plan and recommend next step
- **`<plan-name> archive`**: Move a completed/abandoned plan to the archive

## Process

### No Arguments — Show All Plans

1. Scan `context/plans/active/*/` directories
2. For each plan, determine phase by checking which artifacts exist (same logic as the single-plan check). If `progress.md` exists, read the completion stats from the Progress Overview table.
3. Present as a status table:

```
| Plan | Phase | Last Updated | Next Step |
|------|-------|-------------|-----------|
| search-reranking | research | 2026-02-07 | Run sounding-board agent |
| simple-mcp-server | implementing (5/14) | 2026-02-08 | /plan-resume simple-mcp-server |
| auth-redesign | ready | 2026-02-06 | Copy handoff.md to target repo |
```

If no active plans exist, say so and offer to start one.

### Plan Name — Check Status and Route

1. Read `context/plans/active/<plan-name>/state.md`
   - If it doesn't exist, this is a new plan. Create the directory and `state.md`, then route to research.

2. Determine next step based on which artifacts exist:

| Artifacts Present | Phase | Next Step |
|-------------------|-------|-----------|
| Nothing (new plan) | research | "Use the **researcher** agent to investigate `<plan-name>`: `<description>`" |
| `research.md` exists | refine | "Use the **sounding-board** agent to challenge the `<plan-name>` plan" |
| `analysis.md` exists | plan | "Run `/plan-create <plan-name>` to create the strategic plan" |
| `handoff.md` exists, no `progress.md` | ready | "Plan complete! Copy `handoff.md` to the target repo and start implementation." |
| `handoff.md` + `progress.md` exists, not all steps complete | implementing | Show implementation status (see below), suggest `/plan-resume <plan-name>` |
| `progress.md` exists, all steps complete | done | "Implementation complete! Review the progress log and consider archiving." |

**When phase is `implementing`**, read `progress.md` and present:
- Completion stats (e.g., "5/14 steps done, 3 blocked, 6 pending")
- Current step (the first non-DONE step)
- Last session date (from the most recent Session Log entry)
- Active blocker count (from Active Blockers table)
- Decision change count (number of DC-xxx entries in Decision Changelog)
- "Run `/plan-resume <plan-name>` to generate a continuation prompt for the target repo."

**When phase is `done`**, read `progress.md` and present:
- Final completion stats
- Total sessions logged
- Total decision changes
- "Run `/plan-feature <plan-name> archive` to archive this plan."

3. Present the recommendation with context:
   - Summarize what's been done (e.g., "Research completed on 2026-02-07, covering X sources")
   - State the next step clearly
   - If artifacts exist, briefly summarize their key findings

### Plan Name + Archive

1. Verify `context/plans/active/<plan-name>/` exists
2. Move the entire directory to `context/plans/archive/<plan-name>/`
3. Confirm the archive

## State File Management

When creating a new plan, initialize `state.md`:

```markdown
# Feature Plan State: <plan-name>
## Status
- Current phase: research
- Created: YYYY-MM-DD
- Last updated: YYYY-MM-DD
## Phase History
| Phase | Status | Started | Completed | Notes |
|-------|--------|---------|-----------|-------|
| research | in-progress | YYYY-MM-DD | — | — |
## Checkpoint Log
- [YYYY-MM-DD] Plan created via /plan-feature
```

The orchestrator only reads state — the individual skills (research, sounding-board, plan-create) are responsible for updating `state.md` when they complete their work.

## Key Principles

- **Don't do heavy work.** The orchestrator reads files and routes. The agents and skills do the actual research, analysis, and planning.
- **Be explicit about next steps.** Don't say "continue working on the plan." Say exactly which agent to use and what to ask it.
- **Show progress.** When presenting status, include what's been done, not just what's next.
- **New plans start with research.** Even if the user thinks they know what they want, the research phase surfaces context they didn't have. Skip it only if the user explicitly asks to.

## Important Notes

- The orchestrator doesn't require MCP tools — it only reads local files.
- Plans can be at any phase. The user might jump to `/plan-create` directly if they already have context. That's fine — the orchestrator just reports what exists.
- Abandoned plans should be archived, not deleted. The research may be useful later.
