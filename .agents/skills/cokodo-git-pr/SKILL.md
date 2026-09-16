---
name: cokodo-git-pr
description: |
  Follow cokodo git and pull-request rules when creating a branch, opening or merging a
  PR, or cleaning up after a merge. Covers the three hard rules and the status.md/journal
  split.
---

<!-- generated-by: co skills export -->

# Cokodo Git Pr

## Three hard rules

1. **One PR per branch.** After merge run `co branch cleanup <head>` — deleting the
   remote head is mandatory, not optional.
2. **Product PRs must not edit `status.md`.** Write `- [x]` fragments to
   `.agent/project/journal.d/` instead, and sync them on a `chore/agent-status-*`
   branch with `co journal-flush`.
3. **Integrate the latest default branch before merge.** The PR must be mergeable, and
   re-approval may be required after new pushes.

## Helpers

- `co branch start <name>` / `co branch cleanup <head>`
- `co git hygiene` — check working-tree and branch state
- `co journal-flush` — fold journal fragments into `status.md`

## Windows / PowerShell

Use `-F` with a temp file for any multi-line commit message; PowerShell does not
support `<<'EOF'` heredoc:

```powershell
"feat: subject`n`nBody" | Out-File -Encoding utf8 .git/COMMIT_MSG_TMP
git commit -F .git/COMMIT_MSG_TMP
Remove-Item .git/COMMIT_MSG_TMP
```

## Full reference

`.agent/project/AGENT-GIT-PR-WORKFLOW.md` and
`.agent/project/sop/agent-git-pr-collaboration.md`.
