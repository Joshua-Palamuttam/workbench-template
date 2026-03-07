---
name: ticket-breakdown
description: Decompose a Jira epic or story into estimated subtasks including hidden work. Uses calibration data for realistic estimates. Optionally creates subtasks in Jira.
argument-hint: <ticket-id>
---

# Ticket Breakdown

Decompose a Jira epic or story into estimated implementation subtasks, including the hidden work that people always forget.

## Input

The user provides a Jira ticket ID. Optionally they may specify:
- Whether to create subtasks in Jira (default: no, just show the plan)
- Focus area (if only part of the epic needs decomposition)

## Process

### Step 1: Gather Full Context

1. Fetch the ticket using `mcp__claude_ai_Atlassian__getJiraIssue`
2. Read linked Confluence docs if any are referenced
3. Check for linked tickets (dependencies, related work)
4. Search Slack for recent discussion about this ticket

### Step 2: Understand the Scope

Identify: what needs to be built/changed, which systems/repos are affected, who else is involved, what's unclear.

### Step 3: Decompose into Subtasks

Break into all categories:

**Implementation tasks**: discrete code changes, DB changes, API changes, UI changes

**Quality tasks**: unit tests, integration tests, manual testing

**Coordination tasks**: design review, Slack discussions, cross-team coordination

**Hidden work** (always include): context gathering, PR creation, review cycles (1-2 rounds), merge conflicts, deploy + verification, documentation

### Step 4: Estimate Each Subtask

1. Read `context/calibration.md` for calibrated multipliers and pace factor
2. Assign raw hour estimates, classify familiarity, note which repo
3. Apply appropriate multiplier
4. Apply pace factor if below 1.0

### Step 5: Produce the Breakdown

```
## Ticket Breakdown: [TICKET-ID] — [Title]

### Context
- Epic/Story: [title]
- Systems affected: [repos]
- Open questions / Dependencies

### Subtask Breakdown
| # | Subtask | Category | Raw Est | Multiplier | Adjusted | Notes |
|---|---------|----------|---------|------------|----------|-------|

### Summary
- Raw total / Adjusted total / Calendar days / Confidence range

### Risks
- [Risk that could blow up the estimate]

### Recommended Sequencing
1. Start with X because...
```

### Step 6 (Optional): Create in Jira

If the user asks, create subtasks via `mcp__claude_ai_Atlassian__createJiraIssue`, link to parent, and set estimates.

## Important Notes

- The "hidden work" section is non-negotiable.
- If the ticket is vague, flag it as "needs refinement" and estimate the refinement work.
- Cross-repo changes multiply complexity.
- Note the calibration category for each subtask so actuals can be tracked later.
