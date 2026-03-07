---
name: plan-create
description: Create a strategic feature plan with work breakdown and a handoff prompt for the target repo. Interviews for ambiguities, reads research/analysis artifacts if available. Use after research and refinement, or standalone when you already have context.
argument-hint: <plan-name>
---

# Plan Create

Create a strategic feature plan with work breakdown and a handoff prompt ready to paste into the target repo. This skill interviews the user to resolve all ambiguities, synthesizes research and analysis artifacts, and produces two deliverables: a `plan.md` (strategic plan) and a `handoff.md` (ready-to-paste prompt for implementation).

## Process

### Step 1: Load Context

1. **Read `config.yaml`** from the repository root for user identity, GitHub repos, Jira projects, and Confluence spaces.
2. **Determine the plan name** from the first argument (`$0`). If no argument, use `AskUserQuestion` to get it.
3. **Check for existing artifacts** at `context/plans/active/<plan-name>/`:
   - `research.md` — evidence base from the researcher
   - `analysis.md` — critical analysis from the sounding board
   - `state.md` — current phase tracking
4. If neither `research.md` nor `analysis.md` exists, that's fine — the user may have context from other sources or wants to plan from scratch. Note this and proceed.

### Step 2: Initialize Plan Directory

If `context/plans/active/<plan-name>/` doesn't exist, create it with a `state.md`:

```markdown
# Feature Plan State: <plan-name>
## Status
- Current phase: plan
- Created: YYYY-MM-DD
- Last updated: YYYY-MM-DD
## Phase History
| Phase | Status | Started | Completed | Notes |
|-------|--------|---------|-----------|-------|
| plan | in-progress | YYYY-MM-DD | — | — |
## Checkpoint Log
- [YYYY-MM-DD] Plan creation started
```

If `state.md` already exists, update it to reflect plan phase.

### Step 3: Interview the User

**This is the most important step. Do not skip or rush it.**

Resolve all ambiguities through an iterative interview using `AskUserQuestion`. The goal is to capture every decision needed to produce a complete plan.

**Interview topics** (adapt to the feature):
- **Existing context pointers**: Are there specific Slack threads, Jira tickets, Confluence docs, or codebase files I should read before planning? The user often knows exactly where the relevant discussion or prior art lives — ask first, search later.
- **Scope**: What's in? What's explicitly out? What's "nice to have" vs required?
- **Users**: Who uses this? What are their key workflows?
- **Technical constraints**: Target repo, existing patterns to follow, performance requirements
- **Dependencies**: What must exist first? What teams need to be consulted?
- **Risks**: What could go wrong? What's the blast radius of failure?
- **Timeline**: Any hard deadlines? What's driving the urgency?
- **Success criteria**: How do we know this is done? How do we know it's working?

**Interview rules**:
- Ask up to 4 questions at a time (respects `AskUserQuestion` limits)
- Continue iterating until all ambiguities are resolved — there is no limit on rounds
- If the user says "whatever you think is best", provide your recommendation and get explicit confirmation
- If research/analysis artifacts exist, reference specific findings when asking questions
- Don't ask questions that are already answered in `research.md` or `analysis.md`

### Step 4: Create the Plan

Produce `context/plans/active/<plan-name>/plan.md` using the plan template from `references/plan-template.md`.

The plan must include:
- **Overview**: What this is, why it matters, current state
- **Clarifications table**: Every decision made during the interview
- **User stories**: Concrete workflows per user type
- **Scope**: In-scope, out-of-scope, stretch goals
- **Risk assessment**: Risks with severity, likelihood, and mitigations
- **Work breakdown**: PR-level scope with dependencies and target repo
- **Design decisions**: Key choices with rationale
- **Open questions**: Anything that needs codebase exploration in the target repo

### Step 5: Create the Handoff Prompt

Produce `context/plans/active/<plan-name>/handoff.md` using the handoff template from `references/handoff-template.md`.

The handoff prompt is a self-contained document designed to be pasted into a Claude Code session in the target repo. It contains:
- Strategic context (what, why, key decisions) — so the implementation session doesn't need to re-derive intent
- User stories and acceptance criteria — concrete definition of done
- Work breakdown with PR-level scope — ready for implementation planning
- Decisions locked in during refinement — prevents re-opening settled questions
- Open technical questions — things that need codebase exploration
- Progress tracking section — tells the implementing agent where and how to write back progress
- Suggested next step: run `/plan-create` in the target repo for implementation-level planning

**Template variables to fill in**:
- Replace `[COMMAND_CENTER_PATH]` with the absolute path to the command center repo root (read from the current working directory)
- Replace `[PLAN_NAME]` with the plan name from Step 1

### Step 6: Update State and Present

1. Update `state.md`:
   - Set phase to `completed`
   - Log the completion timestamp
2. Present a summary to the user:
   - Plan overview (2-3 sentences)
   - Key decisions made
   - Work breakdown summary (number of PRs, estimated scope)
   - Next step: copy `handoff.md` to the target repo

## Key Principles

- **Interview depth over speed.** A 15-minute interview saves days of wrong-direction implementation. Don't rush it.
- **PR-level granularity.** The work breakdown should be specific enough that each item maps to a single PR. Vague items like "implement the feature" are useless.
- **The handoff is the product.** The plan is for the user. The handoff is for the implementation session. Both must be complete and self-contained.
- **Reference the evidence.** When making claims in the plan, reference findings from `research.md` and `analysis.md`. Don't assert things that weren't established during research.
- **Decisions are final.** Once captured in the clarifications table, decisions don't get re-opened in the handoff. The implementation session should not re-litigate what was decided here.

## Important Notes

- **This is a principal engineer.** Plans should be at the architecture level, not the code level. Focus on what and why, not how (the implementation session handles how).
- **Use `AskUserQuestion` for all clarification.** Never assume. If something could go two ways, ask.
- **The target repo may be different.** The handoff prompt will be used in a different Claude Code session, possibly a different codebase. It must be self-contained.
