# AI Agent Entry — Git / PR / Collaboration

> Hand this path to any AI agent as the **single entry** for Git, pull requests, and multi-session collaboration on this repository.

## Read in order

1. [sop/agent-git-pr-collaboration.md](sop/agent-git-pr-collaboration.md) — **operational SOP** (PR tracks, journal.d, merge gates, checklists)
2. [sop/git-workflow.md](sop/git-workflow.md) — commit conventions, branch strategy, PowerShell commit notes
3. [status.md](status.md) — read at **session start**; do **not** edit in product PRs (see hard rules below)
4. [../core/instructions.md](../core/instructions.md) §7 — protocol checkpoints and journal fragment model

## Three hard rules

1. **One PR per branch** — after merge, **delete the remote head branch** (`co branch cleanup <head>` or `scripts/post-merge-cleanup.ps1` — **MANDATORY**); never open a second PR on an already-merged branch name.
2. **Product PRs exclude `status.md`** — record completions in `project/journal.d/`; sync via a dedicated `chore/agent-status-*` PR and `co journal-flush`.
3. **Before merge** — `git fetch` and integrate `origin/main` (rebase or merge); PR must be **mergeable**; re-approve after new pushes if branch protection requires it.

## Branch lifecycle (Agent MUST)

| Step | Command |
|------|---------|
| Start task | `co branch start <branch>` or `scripts/start-task-branch.ps1 -Branch <branch>` |
| Push + open PR | `git push -u origin <branch>` then `*(optional)*` or host UI |
| After merge | `co branch cleanup <branch>` or `scripts/post-merge-cleanup.ps1 -Branch <branch>` (**MANDATORY**) |

Machine-readable settings: [git-config.toml](git-config.toml).

## Customization

Replace placeholders in [sop/agent-git-pr-collaboration.md](sop/agent-git-pr-collaboration.md) (or edit `git-config.toml` after `co init`):

| Placeholder | This project |
|-------------|--------------|
| `main` | `main` |
| `origin` | `origin` |
| `{{PRODUCT_GLOBS}}` | *(set per repo — application source, tests, product docs)* |
| `{{RELEASE_GLOBS}}` | `version-state.toml`, release notes under `docs/operations/` |
| `{{TEST_PRE_PR}}` | *(project test command)* |
| `scripts/start-task-branch.ps1` | `scripts/start-task-branch.ps1` |
| `scripts/post-merge-cleanup.ps1` | `scripts/post-merge-cleanup.ps1` |
| `*(optional)*` | *(optional — e.g. `scripts/push-and-pr.ps1`)* |

---

*Template from Cokodo Agent Protocol — customize remote, trunk, and path tables for your host (Gitea, GitHub, GitLab, etc.).*
