# Axline Chat Center-Screen Layout — Feasibility Research

> **Status**: Draft
> **Date**: 2026-09-18
> **Type**: Codebase architecture research / option analysis
---

## 1. Research Question

Can the AxLines (VS Code fork) Workbench layout be restructured so that:

- **Left (Primary Side Bar)** shows the workspace file explorer
- **Center (Editor Area)** hosts the Axline Chat webview dialog
- **Right (Secondary Side Bar)** hosts the code Editor, Terminal, and Git

---

## 2. Scope

**In scope**: Code-level analysis of Grid layout engine (`layout.ts`), Part system (`Parts` enum, `IWorkbenchLayoutService`), Axline extension webview mechanism (`axline.SidebarProvider`), view container location mappings, EditorPart / AuxiliaryBarPart / SidebarPart wiring.
---

## 3. Sources and Method

| Source | Type | Credibility |
|--------|------|-------------|
| `src/vs/workbench/browser/layout.ts` (3247 lines) | Primary - source | **High**: authoritative, current |
| `src/vs/workbench/services/layout/browser/layoutService.ts` (805 lines) | Primary - source | **High**: defines `Parts` enum |
| `.build/builtInExtensions/axline.axline/package.json` (564 lines) | Primary - manifest | **High**: authoritative |
| `src/vs/workbench/contrib/axline/browser/axlineStartup.contribution.ts` | Primary - source | **High**: own contribution |
| `src/vs/sessions/browser/singlePaneWorkbench.ts` | Primary - source | **High**: custom-view pattern |
| `src/vs/workbench/browser/parts/editor/editorPart.ts` | Primary - source | **High**: authoritative |
| `src/vs/sessions/browser/workbench.ts` (1856+ lines) | Primary - source | **High**: session grid logic |

**Method**: Codebase static analysis (grep + file read). No runtime profiling. No external libraries.

---

## 4. Current State

### 4.1 Default Grid Layout

VS Code uses a `SerializableGrid` to manage Workbench parts, registered via the `Parts` enum:

```
Parts.TITLEBAR_PART       = 'workbench.parts.titlebar'
Parts.ACTIVITYBAR_PART    = 'workbench.parts.activitybar'
Parts.SIDEBAR_PART        = 'workbench.parts.sidebar'        (Primary Side Bar)
Parts.PANEL_PART          = 'workbench.parts.panel'          (Bottom panel)
Parts.AUXILIARYBAR_PART   = 'workbench.parts.auxiliarybar'   (Secondary Side Bar)
Parts.EDITOR_PART         = 'workbench.parts.editor'         (Editor Area)
Parts.STATUSBAR_PART      = 'workbench.parts.statusbar'
```

Default horizontal order (`layoutService.ts` lines 205-207): **Activity Bar > Side Bar > Editor > Auxiliary Bar**.

### 4.2 Current Axline Location

Axline registers its webview as `axline.SidebarProvider` inside view container `axline-ActivityBar` (`viewsContainers.activitybar`). It lives inside the **Primary Side Bar**. `axlineStartup.contribution.ts` auto-reveals it on startup.

### 4.3 Part Dependency Summary

| Part | Owner type | Min width | Collapses? |
|------|-----------|-----------|------------|
| Activity Bar | Own Part | ~48px | Yes (auto-hide) |
| Primary Side Bar | PaneComposite | ~170px | Yes |
| Editor Area | EditorPart | ~300px | Yes (not with panel) |
| Secondary Side Bar | AuxiliaryBarPart | ~300px | Yes |
| Panel | PanelPart | Varies | Yes |



---

## 5. Options Analyzed

### 5.1 Option A: Pure config swap (no code changes)

**Approach**: Set `workbench.sideBar.location: "right"` to swap Side Bar positions.

**Assessment**: Does **not** achieve the goal. Editor stays in center; Axline webview is still a sidebar card. Only visual left/right swapping.

**Score**: 1/5 — Not viable.

### 5.2 Option B: Axline Webview as Custom EditorInput (Recommended)

**Approach**: Create `AxlineChatEditorInput extends EditorInput` so Axline Chat occupies a full Editor Group tab. Code editors remain in other groups / docked in Secondary Side Bar.

**Key changes**:

| File | Change |
|------|--------|
| New `axlineChatEditorInput.ts` | EditorInput subclass rendering webview |
| New `axlineChatEditor.ts` | IEditorPane hosting webview chrome |
| `axlineStartup.contribution.ts` | Register editor, open on startup |
| `*.contribution.ts` (terminal/git) | Move view container: `panel`/`activitybar` -> `auxiliarybar` |

**Pros**: Does not touch Grid engine. Uses standard extension points. Chat gets dedicated editor group (maximizable).

**Cons**: Chat shares Tab bar with code editors. Some shortcuts/toolbar items may target wrong editor. Must prevent accidental Chat close.

**Score**: 4/5 — Best effort/value ratio.

### 5.3 Option C: Full-surface Custom View

**Approach**: Use `ICustomViewService` and `Parts.CUSTOM_VIEW_GRID_PART` to overlay Chat view on Editor Part.

**Key changes**: New `axlineChatCustomView.ts` (`ICustomView` impl), `singlePaneWorkbench.ts` modifications.

**Pros**: Takes full center area cleanly. Existing infrastructure exists. Sidebars visible.

**Cons**: Editor is hidden (not moved to right). Custom views mutually exclusive with Editor Part. State transitions needed.

**Score**: 3/5 — Partial fit, misses core goal.

### 5.4 Option D: Full Grid Layout Refactor

**Approach**: Modify `layout.ts` deserialization to insert a new Axline Chat Part in center, move Editor Part into AuxiliaryBar branch.

**Key files (minimum)**:

1. `layout.ts` lines ~1050-1700: `_deserializeGrid()`, grid tree construction
2. `layout.ts` lines ~1680-1730: `_createGridDescriptor()`
3. `layout.ts` lines ~1840-1930: `setEditorHidden()`, visibility rules
4. `layoutService.ts` Parts enum: new `AXLINE_CHAT_PART`
5. `layoutService.ts` lines ~200-300: part ordering
6. `workbench.ts` (sessions browser): parallel grid
7. `editorPart.ts`: minimum width / snap constraints

**Risks**:

| Risk | Sev | Detail |
|------|-----|--------|
| Editor snap/min-width | High | Editor expects ~300px min; sidebar nodes differ |
| Editor-panel mutual exclusion | High | `layout.ts` L1922: both cannot be hidden |
| Grid serialization | High | Part IDs must be in predictable positions |
| Context keys | Med | Part visibility tied to command activations |
| Session layout restore | Med | Session `workbench.ts` mirrors layout |
| Upstream rebase | High | ~2000+ lines changed in hot path |

**Pros**: Exact architectural match. Chat is its own Part. Sidebars independent.

**Cons**: Massive refactor, high regression. Every rebase conflicts on ~2000+ lines. Many consumers assume center Editor.

**Score**: 2/5 — Correct but unsustainable for upstream rebase.
---

## 6. Comparison Matrix

| Dimension | Option A | Option B | Option C | Option D |
|-----------|:-------:|:-------:|:-------:|:-------:|
| Achieves goal? | No | Partially | Partially | **Yes** |
| Changes layout.ts? | No | No | Light | **Heavy** |
| Rebase risk | None | Low | Low | **Very High** |
| Effort (person-days) | 0.5 | 3-5 | 5-7 | 15-25 |
| Regression risk | None | Low | Medium | **Very High** |
| Extensibility | N/A | Good | Good | Best |

---

## 7. Recommendation

### 7.1 Phase 1 (Recommended — Option B)

Implement Axline Chat as a custom `EditorInput` / `IEditorPane`:

1. Create `AxlineChatEditorInput` and `AxlineChatEditor` in `src/vs/workbench/contrib/axline/`
2. Register the editor contribution to host the Axline webview
3. On startup, open Axline Chat as the default editor (occupying Center area)
4. Set `workbench.editor.showTabs: "none"` to hide Tab bar when Chat is the only editor
5. Move Terminal, Git, Debug view containers from `panel` / `activitybar` to `auxiliarybar`

**Expected result**: Visual layout matches the goal — Chat in center, Explorer left, Editor/Terminal/Git right.

### 7.2 Phase 2 (If needed — Option D lite)

If Phase 1 proves the layout concept but the "Editor in sidebar" constraint is too limiting, consider a lighter version of Option D: swap the Editor Part into the AuxiliaryBar Part's physical position in the Grid tree, without adding a new Part. This keeps the Grid tree binary, reducing diff surface.

---

### 7.3 Deferred

- **Option C**: Defer until custom-view use case emerges independently
- **Option A**: Not applicable

---

## 8. Limitations

1. **No runtime testing**: Static code analysis only. Actual behavior may differ due to CSS constraints, event ordering, or undocumented assumptions.
2. **Terminal in Secondary Side Bar**: Terminal's Panel-based architecture (tab system, maximize, inline chat) may not cleanly transfer to a side bar view. Separate spike needed.
3. **Git SCM in Secondary Side Bar**: SCM commit message box expects minimum width; sidebar widths may compress it.
4. **Single source (codebase)**: No external references or prior art; all conclusions from this fork's source.
5. **Upstream drift**: VS Code code-oss-dev upstream may change layout internals; valid for v1.139.0 only.

---

## 9. References

| Ref | File | Lines |
|-----|------|-------|
| R1 | `src/vs/workbench/browser/layout.ts` | 1-3247 |
| R2 | `src/vs/workbench/services/layout/browser/layoutService.ts` | 1-805 |
| R3 | `.build/builtInExtensions/axline.axline/package.json` | 1-564 |
| R4 | `src/vs/workbench/contrib/axline/browser/axlineStartup.contribution.ts` | 1-22+ |
| R5 | `src/vs/workbench/browser/parts/editor/editorPart.ts` | — |
| R6 | `src/vs/sessions/browser/singlePaneWorkbench.ts` | — |
| R7 | `src/vs/workbench/common/editor/editorInput.ts` | — |