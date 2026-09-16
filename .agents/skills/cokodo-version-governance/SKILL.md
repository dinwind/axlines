---
name: cokodo-version-governance
description: |
  Cut a release, bump a version, write release notes, or audit version drift in a cokodo
  project. Keeps version-state.toml, tags, and release docs consistent.
paths:
  - "**/version-state.toml"
  - "**/versioning.md"
---

<!-- generated-by: co skills export -->

# Cokodo Version Governance

## When to use

Any release, version bump, tag, rollback, or release-note task.

## Read first

1. `.agent/core/workflows/version-governance-workflow.md` — the procedure.
2. `.agent/project/versioning.md` — this project's policy: tracks, canonical sources.
3. `.agent/project/version-state.toml` — machine-readable current facts.
4. `.agent/project/sop/release.md` — the release checklist.

## Helpers

- `co version audit` — detect drift between canonical sources
- `co release` — Conventional-Commits driven release planning
- `co start-next-version` / `co open-next-version`

## Rule

The canonical source named in `versioning.md` wins. Never hand-edit a derived version
string to make a check pass; fix the canonical source and regenerate.
