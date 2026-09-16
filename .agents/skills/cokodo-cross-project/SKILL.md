---
name: cokodo-cross-project
description: |
  Read context from another project on this machine — integration, API docking, migration,
  or referencing external docs — using Cokodo MCP tools instead of file-system search.
---

<!-- generated-by: co skills export -->

# Cokodo Cross Project

## When to use

The task involves a project other than the current one.

## Prefer MCP over file search

| Need | Tool |
|------|------|
| Discover projects on this machine | `list_global_projects` |
| Read another project's `.agent/` context | `get_global_project_context(project)` |
| Read another project's status | `get_global_project_status(project)` |
| Search across all projects | `global_search(keyword)` |
| Declared references and collaborations | `list_relations` |
| Shared cross-project content | `get_related_context` / `get_collaboration_context` |
| Same-machine change notices | `list_project_events` / `get_related_events` |

Typical flow: `list_global_projects` -> `get_global_project_context("X")` -> use the
result. Fall back to direct file access only if these do not cover the need.

## Make it automatic

If the same cross-project lookup recurs, declare it:

- `co ref add <path> --name <name> --use-when session_start` — auto-loaded each session
- `co collab add <partner> --name <name> --role replica` — shared files + drift tracking

## Full reference

`.agent/core/protocol-map.md` §4.
