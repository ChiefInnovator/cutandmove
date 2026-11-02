# Stage 9 — Implementation readiness review, round 1

Target: `design_draft.md:185–249`, from `## Detailed Implementation Plan` through end. Earlier sections supplied context only. All three reviewers ran in separate fresh contexts with `fork_turns: none`. No source edits, builds, history retrieval, or memory access were performed.

## Reviewer status

| Reviewer | Status | Raw findings |
| --- | --- | --- |
| implementation_readiness | completed | 3 Major |
| codebase_details | completed | 4 Major |
| style | completed | none |

Result: not clean. Four distinct Major issues after deduplication; no Blockers or Nits. This is one review round, not convergence.

## Consolidated findings

### codebase_details-1-1 — Major — Explicit change inventory missing

Scope: `design_draft.md:187–215`.

The plan has no authoritative Create/Modify/Delete inventory. A fresh implementer must determine the files affected by source fixes, CI migration, documentation, reports, and design records. Existing policy and marketing docs still describe behavior that the plan intends to change.

Remedy: add an operation, purpose, and phase for each affected file, distinguishing proposed files from current files and examined-but-unchanged paths.

### implementation_readiness-1-1 — Major — Accepted corrections need executable tasks

Scope: `design_draft.md:205–212,233–236`. Combines readiness finding 1 and codebase finding 3.

“Implement accepted findings” and “fix concrete accessibility, recovery, layout, and copy problems” leave the corrections to be selected and designed later. The permission UI has several different states but currently shares a permission-required heading, conditionally exposes settings, and dismisses success. The website already has focus-visible and reduced-motion rules; no remaining defect or intended acceptance is identified.

Remedy: enumerate each accepted correction with source file, exact behavior/state/copy/action change, existing seam to reuse, and focused validation. Preserve keyboard/file-move behavior unless a named correction changes it. Disposition additional discoveries rather than expanding scope silently.

### implementation_readiness-1-2 — Major — Release patch handoff undecided

Scope: `design_draft.md:205–208,230–231,246`. Combines readiness finding 2 and codebase finding 2.

“Prefer” a patch artifact leaves an architectural choice. Current automation generates four files, commits and pushes main, requests Pages, and polls the live page. A patch-producing replacement must define what happens to each operation and when deployed content is checked.

Remedy: commit to one route; specify permissions, checkout/base, patch contents and artifact name, upload and no-change behavior, operator feature-branch application and conflict recovery, documentation path, and post-main-merge Pages verification owner/trigger. Add workflow-specific regression checks preventing protected-branch writes and premature deployment assertions.

### implementation_readiness-1-3 — Major — Branch-check migration and test harness unspecified

Scope: `design_draft.md:187–192,213–215,223–228`. Combines readiness finding 3 and codebase finding 4.

The current workflow emits one `Branch source` check; the plan requires target-specific checks without specifying the job structure, exact emitted names, inactive-target behavior, test seam/command, or safe workflow-versus-ruleset rollout sequence.

Remedy: define exact jobs/check names and conditions, deterministic tests of the actual validator, matching documentation changes, successful check registration and ruleset activation checkpoints, and live rejection/retarget verification. Cover event/live base metadata and head changes to prevent stale passing results.

## Complete reviewer outputs

### implementation_readiness

Implementation readiness: fails the zero-decision rule. Three Major findings; no Blockers or Nits.

1. **Major — Steps 5–6, lines 205–212: correction work is deferred instead of specified.** “Implement accepted findings” and “fix concrete accessibility, recovery, layout, and copy problems” do not identify the accepted changes, affected files, intended behavior, or regression assertions. A fresh implementer must select and design those corrections. Earlier CUJs constrain behavior but do not supply implementation instructions. **Remedy:** Replace these umbrella steps with a bounded task list naming each file, required logic or UI change, expected states, and corresponding verification. Keep newly discovered issues in the disposition record specified at lines 248–249.

2. **Major — Step 5, lines 205–208; acceptance lines 230–231; risk line 246: release handoff remains an architectural choice.** “Prefer” a patch artifact leaves the delivery mechanism undecided. The current `.github/workflows/release-marketing.yml` commits to main, requests a Pages rebuild, and polls the live page immediately. Generating a patch changes the timing and ownership of all three operations. The plan does not say which steps disappear, what the artifact contains, how it is applied through develop, or when live-version verification occurs. Existing release-sync tests alone do not verify this workflow handoff. **Remedy:** Commit to one route and specify workflow permissions, artifact contents and naming, no-change behavior, application instructions and documentation path, retained or removed deployment steps, and tests proving generation cannot write protected branches.

3. **Major — Steps 1 and 7, lines 187–192 and 213–215; acceptance lines 223–228: branch-policy implementation and verification checkpoints are incomplete.** The target-specific check requirement and truth table are clear, but the plan does not name the workflow job/check implementation, automated test file or command, or the sequence that makes required check names available on both branches before activating their rulesets. The existing workflow exposes one `Branch source` job, so this requires an explicit change rather than configuration alone. A fresh implementer must design both the test seam and protection activation sequence. **Remedy:** Specify the workflow/job changes and exact required check names, identify where the truth-table tests live and how they run, and order bootstrap, successful check registration, ruleset activation, and live rejection/retarget tests into stable checkpoints.

Complete read list:

- `.agents/agents/implementation_readiness.md` — entire file.
- `.agents/resources/document_standards/implementation-readiness-standard.md` — entire file.
- `design_draft.md` — entire file; findings restricted to lines 185–249.
- `.github/workflows/release-marketing.yml` — entire file.
- `.github/workflows/branch-policy.yml` — entire file.
- `CutAndMove/PermissionsView.swift` — entire file.
- `.agents/skills/impeccable/reference/document.md` — lines 1–180.
- `.agents/skills/impeccable/reference/init.md` — lines 1–100.
- `.agents/skills/impeccable/reference/critique.md` — lines 1–120.

Read-only review; no files modified, builds run, history retrieved, or memory accessed.

### codebase_details

Stage 9 codebase-details review: **FAIL — 4 Major findings; no Blockers or Nits.** Reviewed target: `design_draft.md:185–249`. Earlier sections supplied context only.

1. **Major — Missing explicit change inventory.** **Scope:** `design_draft.md:187–215`. Steps describe installation, documentation, source fixes, and CI repairs without a Create/Modify/Delete inventory. Existing files requiring changes include `.github/workflows/branch-policy.yml` (currently one `Branch source` job), `.github/workflows/release-marketing.yml` (currently pushes directly to main), `docs/branch-policy.md` (still documents the shared check name), and `docs/marketing.md` (still promises direct-main automation). Native and web correction paths remain unspecified. A fresh implementer must determine scope. **Remedy:** Add one authoritative file inventory with operation, purpose, and phase. Include proposed report, design, surface-brief, workflow-test, and production changes; distinguish examined-but-unchanged files.

2. **Major — Release patch delivery remains an architectural preference rather than an executable design.** **Scope:** `design_draft.md:205–208,230–231,246`; `.github/workflows/release-marketing.yml:8–68`; `scripts/sync-release.py:44–56`; `docs/marketing.md:7–9`. “Prefer a read-only generated patch artifact” leaves the producer baseline, artifact contents/name, upload mechanism, no-change outcome, operator application commands, and deployment verification timing undecided. The current workflow checks out main, generates four changed files, commits and pushes main, requests Pages, then polls the live page. Simply replacing its push with artifact upload leaves Pages verification testing unapplied content. Existing release tests exercise Python generation, not this workflow transition. **Remedy:** Specify the exact replacement steps and permissions, patch base and included files, artifact publication/no-op behavior, feature-branch application route, conflict recovery, and the post-main-merge Pages verification owner/trigger. Add workflow-specific regression cases proving no main push or premature deployment assertion.

3. **Major — Accepted permission and accessibility fixes have no concrete implementation contract.** **Scope:** `design_draft.md:205–212,233–236`; `CutAndMove/PermissionsView.swift:20–65`; `CutAndMove/GlobalKeyboardHandler.swift:54–96`; `CutAndMove/CutAndMoveApp.swift:53–99`; `index.html:703–725`. “Fix concrete accessibility, recovery, layout, and copy problems” delegates the behavior and scope to the implementer. Existing permissions UI already has several materially different states: untrusted, trusted with failed tap creation, monitoring enabled, and revoked access. It currently labels all of them “Permission Required,” provides the settings action only while not monitoring, and auto-dismisses success. The website already contains focus-visible and reduced-motion rules; the plan does not identify which remaining defect is to change or whether those existing implementations are accepted. Broad rendering checks do not establish expected state behavior. **Remedy:** Enumerate accepted findings and their exact source changes, expected state/copy/action mapping, and focused validation cases. Preserve existing keyboard/file-move logic unless a named finding requires modifying it. Link the existing test seams (`monitoringAction` and injectable `LaunchManager`) where applicable.

4. **Major — Branch-check migration and its regression harness are unspecified.** **Scope:** `design_draft.md:187–192,213–215,223–228`; `.github/workflows/branch-policy.yml:14–35`; `docs/branch-policy.md:7–9,19–22`. The plan requires target-specific check names, but the existing workflow emits a single `Branch source` check. It does not state the new workflow job/matrix structure, exact emitted names, how inactive target checks behave, or the order of workflow rollout versus required-check updates. It lists truth-table cases but supplies no test file/command or method for exercising the trusted inline JavaScript. The result can strand required checks or accidentally reuse a passing result after retargeting. **Remedy:** Define exact job/check names and conditions, update the corresponding docs, specify a deterministic offline harness for the actual validator, and describe the safe ruleset/check-name migration sequence. Include retargeting with both event/live base metadata and head changes, and verify the final emitted checks on both promotion directions.

Read list:

- Full: `.agents/agents/codebase_details.md`; `.agents/resources/document_standards/implementation-readiness-standard.md`; `design_draft.md`; `.github/workflows/{branch-policy,release-marketing,marketing}.yml`; `Makefile`.
- Full production Swift: `CutAndMove/{AboutView,CutAndMoveApp,FileMoveService,FinderIntegration,GlobalKeyboardHandler,LaunchManager,PermissionsView,ShortcutState}.swift`; `Shared/FinderBridge.swift`; `CutAndMoveFinder/FinderSync.swift`.
- Full: `Config/{App.entitlements,FinderSync.entitlements,FinderSync-Info.plist}`; `scripts/{sync-release.py,test-release-sync.py,test-share.cjs,export-notarized.sh,ExportOptions-export.plist,ExportOptions-upload.plist}`; `share.js`; `marketing.json`; `docs/{architecture,branch-policy,marketing}.md`.
- Test infrastructure inspected: `CutAndMoveTests/FinderIntegrationTests.swift` including disposable filesystem fixture; `CutAndMoveTests/CutAndMoveTests.swift` event helper and injected login-service fixtures; marketing Python temporary-root fixtures; share VM DOM/clipboard mocks; UI-test launch/setup infrastructure.
- Partial reads/searches: `scripts/sync-marketing.py` generation and main/check paths; `scripts/test-marketing.py`; `scripts/test-finder.swift:1–60`; `index.html` accessibility, motion, navigation, generated download/share regions; `CutAndMove.xcodeproj/project.pbxproj` target/build-setting matches; `.agents/skills/egm-review/SKILL.md:1–50`; Impeccable `reference/{document,init,critique}.md` relevant entry sections.

Unread/partially unread paths:

- Unread portions of the partial files above, including full Xcode project wiring and live Finder harness.
- `README.md`, `llms.txt`, `docs/setup.md`, `docs/REVIEW_VERIFICATION.md`, release notes, historical campaign outputs, image contents, skill installer/provenance/runtime files, and prior review reports.
- Proposed `PRODUCT.md`, `DESIGN.md`, `.impeccable/design.json`, and surface briefs were not reviewed as completed artifacts; `.impeccable` is absent. Their proposed absence is not a finding.

No files changed, builds/tests run, history retrieved, or memory consulted.

### style

No Blocker, Major, or Nit findings in `design_draft.md:185–249`. The implementation steps, validation boundaries, and risks use direct, objective language; terminology is explained by the preceding context.

Complete read list:

- `.agents/agents/style.md` — entire file.
- `design_draft.md` — entire file; lines 185–249 audited, earlier sections used only as context.

No linked references were needed. No files were modified.
