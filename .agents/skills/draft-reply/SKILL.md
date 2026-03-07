---
name: draft-reply
description: Search a Slack channel for a topic, read the thread, gather Jira/Confluence context, and draft a thoughtful response. Arguments are channel-name followed by topic or thread context.
allowed-tools: mcp__claude_ai_Slack_MCP__slack_search_public mcp__claude_ai_Slack_MCP__slack_read_thread mcp__claude_ai_Atlassian__searchJiraIssuesUsingJql mcp__claude_ai_Atlassian__search
---

# Draft a Slack Reply

Search a channel for a topic, read the thread, and draft a response.

**Arguments**: `<channel-name> <topic or thread context>`

## Process

1. Parse the arguments: first word is the channel name, rest is the topic
2. Search the channel using `mcp__claude_ai_Slack_MCP__slack_search_public` with the topic as query
3. Find the most relevant thread and read it using `mcp__claude_ai_Slack_MCP__slack_read_thread`
4. Search Jira and Confluence for related context:
   - Search Jira for the topic keywords using `mcp__claude_ai_Atlassian__searchJiraIssuesUsingJql`
   - Search Confluence using `mcp__claude_ai_Atlassian__search` if the thread references design docs
5. Draft a response that is:
   - Direct and concise (match the style in CLAUDE.md: "Be direct. No fluff.")
   - Backed by data when available (link to tickets/docs)
   - Appropriate for a principal engineer (technical depth, clear recommendations)
6. Present the draft for review

## Output

Show the thread summary, then the draft response. Ask: "Send this reply? (I'll use Slack MCP to post it after your approval)"

Never send without explicit approval.
