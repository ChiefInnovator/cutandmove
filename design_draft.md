# Cut & Move: governed delivery and existing-product design

## Overview

Cut & Move is a Swift/SwiftUI macOS menu-bar utility. It adds Cmd+X followed
by Cmd+V file moves to Finder and supplies a Finder Sync context menu, toolbar,
and pending-cut badges. The repository also contains a static download website,
release scripts, tests, and historical social-campaign output.

This design records the existing product and defines the requested delivery
controls, installed design tooling, and corrections to branch CI, release
marketing delivery, permission recovery, and website accessibility found in review. It preserves the native interface and the existing website identity.
It is not a replacement product or a speculative feature roadmap.

## The Problem

The repository previously allowed unrestricted main updates, had no develop
branch, and allowed release automation to commit directly to main. Future work
needs an enforced integration route and a shared, evidence-based design reference.
The app handles real files, so UI and workflow changes must preserve its safety
checks and must distinguish tests from signed-app acceptance.

## Goals

- Require same-repository feature/* PRs into develop and develop PRs into main.
- Block direct/force pushes and deletion on both branches with no bypass actors.
- Enable automatic cloud GitHub Copilot reviews only for develop PRs and pushes.
- Install the complete Google EGM runtime and Impeccable project-locally.
- Document app, extension, keyboard/bridge/move paths, website, and release CI.
- Run all five EGM Goldfish stages in fresh contexts; implement actionable feedback.
- Record Impeccable product, design, extension tokens, and surface context;
  review the actual rendered interface and implement findings within the correction categories above.
- Keep existing file-move behavior and published release facts intact.

## Non-Goals

No new storage service, cloud app, analytics, paid dependencies, account system,
mobile port, or visual rebrand. Do not alter historic campaign outputs or publish
new binaries. No real-file desktop automation without disposable fixtures.
No manually requested GitHub reviews or empty pushes to provoke one.

## Evidence and Current Boundaries

Source baseline: 96b288e (governance bootstrap), whose product source is v2.0.1.
README.md records Apple silicon, macOS 26.1+, Developer ID distribution, and
PolyForm Strict licensing. docs/REVIEW_VERIFICATION.md contains historical live
Finder evidence for v2.0.0, not acceptance of this working tree or a new release.
Existing build/ output is untracked historical evidence, not current validation.

Architecture: docs/architecture.md; source of truth: CutAndMove/*.swift,
Shared/FinderBridge.swift, CutAndMoveFinder/FinderSync.swift,
Config/*, CutAndMove.xcodeproj/project.pbxproj, and Makefile.
Tests: CutAndMoveTests/*.swift, CutAndMoveUITests/*.swift, scripts/test-*,
and scripts/sync-marketing.py. Web: index.html, share.js, marketing.json,
llms.txt, scripts/sync-release.py, and the marketing workflows.

## Review Tools and Required Records

Google's Elephant-Goldfish Model (EGM) separates the drafting agent, which knows
the project history, from fresh-context Goldfish reviewers that receive only the
document, linked source, their persona, and their review standard. The installed
pipeline is [.agents/skills/egm-review/SKILL.md](.agents/skills/egm-review/SKILL.md):

1. Stage 5: initial high-level architecture check (zoom_out persona and standard).
2. Stage 6: comprehension paraphrase (comprehension persona, no standard).
3. Stage 7: feature critique (design_critic and structural against feature-spec;
   style checks clarity without a separate standard).
4. Stage 8: another high-level check including earlier findings and corrections.
5. Stage 9: implementation_readiness and codebase_details against the
   implementation-readiness standard, plus style; each reviewer starts fresh.

Personas live in .agents/agents; standards in .agents/resources/document_standards.
Impeccable is the installed interface design/review skill. Its
[document reference](.agents/skills/impeccable/reference/document.md) defines
DESIGN.md tokens and the .impeccable/design.json sidecar: extra design values
such as shadows, motion, and breakpoints that do not fit the frontmatter schema.
Its [init reference](.agents/skills/impeccable/reference/init.md) defines PRODUCT.md.
Surface briefs describe each surface's audience, task, constraints, and visitor
mode: Operate for completing native tasks; Persuade for the download website.
They are stored under .impeccable/surfaces without duplicating global product facts.
The [critique reference](.agents/skills/impeccable/reference/critique.md) defines
independent human-style and deterministic assessments. Native AppKit inspection
must not be mislabeled as web detector or mobile-device acceptance.

## Critical User Journeys (CUJs)

### CUJ 1: Keyboard move

Given Finder has file focus, Accessibility access is granted, and no move is
running, when a user cuts a selection and pastes in another folder, Finder's
native Move Item Here command moves it. Ordinary copy remains copy. Rename,
search, text fields, unknown Accessibility (AX) focus, and other apps retain normal shortcuts.
The pending-cut state clears on cancellation or clipboard replacement.

### CUJ 2: Finder menu move and recovery

Given the extension is enabled and the host is available, when a user cuts via
the Finder menu and chooses Move Here, the host validates the request and moves
without overwriting. Keyboard and menu cuts share state. A partial failure shows
the moved count and retains only remaining items. Restart cannot replay a move.

### CUJ 3: Permissions and login

Given Accessibility is absent or revoked, when the app opens its permission
window, it names the permission, explains Finder-only use, and offers System
Settings. Ready means a working event tap, not merely permission granted.
Login approval and errors remain visible and recoverable. Finder-menu operation
does not falsely require Accessibility when only keyboard monitoring needs it.

### CUJ 4: Download and install

Given a visitor on desktop or a narrow browser, when they inspect the site,
requirements and published version are readable, download controls work with
keyboard input, and the download targets the verified released version.
Reduced-motion preference and focus visibility must be respected.

### CUJ 5: Deliver a change

Given a feature branch in this repository, when its PR targets develop, the
source check passes and automatic Copilot review is eligible to run. A feature
PR targeting main, a non-feature PR targeting develop, or a fork PR fails.
A develop-to-main promotion passes. No one pushes directly to either branch.

## Technical Plan (Architecture)

```text
Finder keyboard -> GlobalKeyboardHandler -> ShortcutState -> Finder native move
Finder extension -> FinderBridge request -> FinderIntegration -> FileMoveService
                                    <- atomic status / pending cut / message
feature/* -> PR + branch check + automatic Copilot -> develop
          -> develop promotion PR + branch check -> main -> Pages / release
```

The synchronous shortcut state machine owns paired key events, clipboard
freshness, repeat suppression, and cancellation. The event tap limits interception
to Finder file views. The app-group bridge uses atomic local request/status files;
the host owns a filesystem lock, expires requests, and claims before execution.
The extension snapshots menu actions and registers local/mounted roots without
obtaining extra filesystem permission. FileMoveService validates selection,
source identity, destination, collisions, overlapping paths, and partial failures.

The menu shows keyboard and extension readiness separately, pending count,
operation messages, launch-at-login status, permission recovery, About, and Quit.
SwiftUI/AppKit semantic styles remain authoritative for the native interface.
The static website keeps its current dark neutral/blue-violet identity; fixes
should address accessibility and actual usability without replacing its design.

Repository rulesets require a PR and the GitHub Actions Branch source check.
Use distinct main/develop check names to avoid reusing a passing check after
retargeting a PR. The check runs trusted base-branch JavaScript on pull_request_target, reads live
PR metadata, requires the source repository to match, and never checks out head
code. Develop additionally enables Copilot automatic review on new pushes.
The account must have eligible Copilot access; configuring a rule does not prove
that a review actually completed. Copilot comments are advisory, not approvals. Personal account automation is an
independent review source: initial live inspection found it enabled account-wide. A
repository ruleset cannot turn that source off on main. The owner explicitly authorized disabling that global setting; a refreshed
GitHub settings page now shows it off. Repository-triggered reviews are
restricted to develop, with no independent personal automatic-review source.
Only merge commits are enabled; develop is retained after promotions.

## Alternatives Considered

- Document-only branch conventions: simpler, but do not prevent accidental merges.
- Require a second human approval: provides independent approval, but a solo author cannot
  approve their own PR; this would block ordinary work. Require conversations
  resolved and use automatic review without a human approval count.
- Run source validation from feature code: easy to alter in the very PR being
  checked. Trusted pull_request_target metadata validation avoids executing it.
- Give the release bot a main bypass: keeps the old workflow but violates the
  requested route. Release marketing must produce reviewable feature work.
- Rebrand or change the file-move architecture: would require new interaction
  and filesystem regression acceptance without a stated product requirement.

## Non-Functional Requirements

Keep all app communications local. Do not add telemetry or file-content uploads.
Never execute PR head code with a privileged target-event token. Do not store
credentials in docs or skill provenance. Exclude machine-specific tool binaries
from Git; preserve source launchers, checksums, and portable runtime instructions.
GitHub rules cannot stop a repository administrator from editing the rules.
A writer who replaces trusted checks is outside accidental-misroute protection;
the owner must verify workflow event, permissions, checkout ref, action pins,
and required-check names whenever CI changes.

## Detailed Implementation Plan

### Phase 1: Branch bootstrap and portable tooling

Bootstrap completed at 96b288e: install the trusted branch workflow on main,
create develop at that same commit, then enable no-bypass rulesets requiring the
existing `Branch source` check. Do not switch required names before their workflow
lands. Both branches require PRs, resolved threads, no deletion/force push, zero
human approvals, GitHub Actions integration 15368, and non-strict status checks.
Only merge commits are allowed; develop is retained. Ruleset IDs are 26359272
(main) and 26359276 (develop). Only develop has the Copilot review rule.

Install seven EGM skills plus personas, resources, docs, license, and upstream
revision 403d8881d62022490637d740657b33f01e321ea8 in .agents. Install Impeccable
4.8.0 using its Codex project installer without hooks. Preserve launchers and
checksums, ignore downloaded scripts/bin engines and Python cache. Keep runtime
SKILL.md prompts/personas/standards byte-identical. Adapt consumer documentation
links only where upstream development paths do not exist in this application;
record each adaptation in provenance.

### Phase 2: Documentation and source change inventory

Create these files: design_draft.md; AGENTS.md; .agents/egm-source.json;
.agents/impeccable-source.json; the installed .agents runtime trees;
PRODUCT.md; DESIGN.md; .impeccable/design.json; two surface briefs created by
`impeccable surface-brief write` for index.html and CutAndMove/CutAndMoveApp.swift;
scripts/test-branch-policy.cjs; scripts/test-governance.cjs;
docs/reviews/egm/{zoom_out_report,comprehension_report,critic_report,
intermediate_zoom_out_report,implementation_readiness_report,
consolidated_review_report,goldfish_review_report}.md;
docs/reviews/impeccable-review.md; docs/reviews/verification.md.

Create .gitattributes to preserve vendored runtime whitespace/Windows CRLF bytes.
Modify .gitignore (local engine/cache exclusions), .github/workflows/branch-policy.yml
(target-specific source check and stale-event validation), marketing.yml (run
new governance regression scripts), release-marketing.yml (read-only patch
artifact), docs/branch-policy.md (final names and bootstrap sequence),
docs/marketing.md (patch application and deployment procedure),
CutAndMove/PermissionsView.swift (permission-state recovery and persistent success),
CutAndMove/CutAndMoveApp.swift (matching window title/default dimensions), and
index.html (measured text/button contrast and neutral shadows replacing the
Impeccable hook's confirmed decorative-glow findings). Further Impeccable corrections must
first be named in its report and this inventory; no unexplained refactoring.
Impeccable accepted additions: Modify AboutView.swift to open the product
homepage, CutAndMoveApp.swift recovery label and singular cut count, FinderSync.swift
singular/plural menu labels, scripts/sync-marketing.py for download-adjacent
hardware requirements and published/preview integration FAQ, scripts/test-marketing.py
for those generated contracts, and generated README.md/llms.txt/index.html. Keep
only semantic ordered-list numbering in the how-to and provide static manual-copy
guidance for share fallback. Expand design frontmatter to cover observed scales;
retain explicitly triaged incumbent pattern advisories without suppression.
Add canonical .agents/assets, .agents/LICENSE, and a consumer .agents/README.md;
redirect EGM development-only test/build links to the pinned upstream checkout,
recording the adapted documentation paths in egm-source.json.
Delete no existing files. Leave core keyboard/bridge/file-move logic, signing,
project deployment targets, generated product facts, and historical output intact.

### Phase 3: Exact branch-check change and rollout

Keep an always-running validator job `source`; use the check name
`Branch source to ${{ github.event.pull_request.base.ref }}`. It emits exactly
`Branch source to main` or `Branch source to develop`. Add a compatibility job
named `Branch source`, with `needs: source` and `if: always()`. It runs
`test "$SOURCE_RESULT" = success`, where SOURCE_RESULT is needs.source.result.
Failure, cancellation, skipped, and missing source results all fail the legacy
context. This preserves bootstrap protection until ruleset migration; it is a
forwarding check, not an inactive-target job or bypass. Keep pull_request_target,
branches main/develop, opened/synchronize/reopened/edited/ready_for_review,
read-only contents/PR permissions, pinned github-script, and no checkout.

Fetch current PR metadata and require same repository plus develop→main or a
nonempty feature/ suffix→develop. Additionally require the live base ref,
head ref, source repository identity, and head SHA to equal the event snapshot;
a retarget/rename/new push while a run executes must fail the older event.

Create scripts/test-branch-policy.cjs to extract the actual inline script from
branch-policy.yml, execute it in a Node VM with mocked pulls.get/context/core,
and assert allow/reject outcomes. Cases: both legal routes, main/docs/feature
misroutes, empty suffix, same-name fork and missing fork repo, deleted head repo,
head SHA mismatch, changed head ref, changed base ref in both directions, and
changed source repository. Run the script in marketing.yml alongside existing
marketing tests. `Branch source` remains required during this feature PR because
the trusted base still contains the bootstrap workflow.

After the feature PR merges into develop, verify its new source workflow is
present, run a real subsequent feature PR to register `Branch source to develop`,
and update only develop's ruleset to require that name. Promote develop to main
under main's still-required bootstrap `Branch source` check. After promotion,
register the new main check on a real promotion PR when there are real changes,
then update main's ruleset. For either branch, changing the required name after
the new workflow is installed is fail-closed: pending PRs remain blocked until
GitHub reports the new named check. The compatibility alias never bypasses validation, whether retained or removed
   after migration.
Read the effective rules after each migration. No empty commit/no-op push is
permitted to register checks. Do not falsely report unexecuted live route tests.

### Phase 4: Read-only release patch producer and handoff

In release-marketing.yml keep the stable-release/workflow_dispatch triggers,
concurrency, main checkout, latest-stable-release read, existing sync-release.py,
and all generated-content tests. Reduce top-level permissions to contents: read.
Remove bot identity, commit, push, Pages rebuild, and pre-merge live polling.
Use `git diff --binary -- marketing.json index.html README.md llms.txt` to write
release-marketing.patch in RUNNER_TEMP/release-marketing, alongside base-sha.txt
(the checked-out main commit) and release.json (validated release metadata).
If the patch is empty, write an already-current job summary and upload nothing.
Otherwise upload `release-marketing` with pinned actions/upload-artifact v4,
retention seven days, and if-no-files-found: error. The summary links the
application instructions in docs/marketing.md and never claims a deployment.

The promotion operator downloads the artifact from the successful run, fetches
origin, creates feature/release-marketing-<version> from origin/develop, and runs
`git apply --check <patch>` followed by `git apply <patch>`. Run marketing checks,
commit, push, and open a develop PR; then promote develop to main. If patch
application fails because develop/main diverged, do not force apply: rerun the
existing sync-release.py against the artifact release.json on the feature branch
and inspect the generated four-file diff before tests. No PAT or bot exemption.

After the main promotion is merged, that operator waits for the legacy Pages
build (source main:/), checks its commit via `gh api .../pages/builds/latest`,
and fetches the live page to a temporary file with curl. Compare it with the
main checkout's index.html using cmp and verify the expected published DMG link.
Retry after the pending Pages build completes; a stale page is pending deployment,
not success. This manual post-merge step replaces the old workflow's premature
polling. No current source version or binary-release fact changes in this task.

Create scripts/test-governance.cjs to enforce security contracts from workflow
source: branch validator remains target-event/read-only/no-checkout, target names
are distinct, new tests run in marketing CI, and release producer cannot commit,
push, call Pages build endpoints, or poll unapplied content. Assert read-only
permissions, four-file patch scope, empty-patch branch, artifact retention, and
metadata handoff. These protect boundaries absent from release-generator tests.

### Phase 5: Permission recovery and measured website accessibility

Reuse GlobalKeyboardHandler's existing hasPermissions/isMonitoring/error state;
do not introduce another monitor or alter monitoringAction/LaunchManager.
PermissionsView maps states explicitly: untrusted→Accessibility Permission Required
and Finder-only explanation/settings instructions; trusted but tap unavailable→
Keyboard Monitoring Unavailable, existing diagnostic and Retry Monitoring action
calling checkPermissions; monitoring→Keyboard Shortcuts Ready and persistent Done
button. Revocation returns to the untrusted view. Keep settings available for
untrusted/trusted failure and remove the delayed success dismissal. Use semantic
secondary text, decorative-symbol accessibilityHidden, and content-sized vertical
layout so multiline diagnostics are not clipped in a fixed 360-point height.
Set the app window's stable title to Keyboard Shortcuts and default 400×360.
Verify all three conditional states by source inspection and native rendering
where available. Build and run existing monitoring/shortcut/login unit tests.

The existing web focus-visible and reduced-motion rules are accepted and retained.
Measured defect: faint #6b6b76 text has only 3.51:1 against #13131a; white CTA text
has 3.68:1 at #3b82f6 and 4.23:1 at #8b5cf6. Set faint text to #90909c (5.86:1 on
panel), add separate action gradient #1d4ed8→#6d28d9 (white endpoints 6.70/7.10:1),
and use it only on nav/download CTA backgrounds. Keep accent-gradient display
colors separate so improving button contrast does not darken headings. Check
intermediate gradient samples as well as endpoints. Preserve generated text,
release/download URLs, responsive layout, existing focus, and reduced-motion.

### Phase 6: Impeccable review, verification, and promotion

Write the product/design/sidecar/surface records from incumbent source before
production corrections, then reconcile them after fixes. Do not invent a new
visual world or persist a comp/code build-path preference that the owner never
selected. Keep macOS AppKit semantics separate from web literals; do not label
macOS as iOS merely to satisfy a mobile platform classifier.

Run native design assessment (source evidence explicitly labeled if the menu-bar
app cannot be captured). For index.html, run two independent fresh assessments:
design judgment with rendered Chrome inspection, then source detector evidence;
withhold detector results from the design assessor. Record findings with severity,
file/line, remedy, and outcome in impeccable-review.md. The user has requested
implementation of all actionable feedback; scope additions must still be named.
Verify desktop/narrow rendering, keyboard traversal/FAQ actions, and final source.
Use disposable fixtures only if any file-move change becomes necessary.

Run actionlint, git diff --check, both new Node tests, marketing check, all three
existing marketing/release/share suites, and unit-only xcodebuild with isolated
derived data and no desktop-controlling UI tests. Record counts, logs, limitations.
Push actual changes, open develop PR, wait for exact-head CI and automatic Copilot
review, address its findings with real changes, and resolve reviewed threads.
Never manually request/re-request a review. Merge with a merge commit only after
gates pass. Promote through develop→main, verify effective rules and Pages.
The owner authorized disabling account-wide Copilot automation; refreshed
GitHub UI verification shows Automatic Copilot code review off.

## Validation and Acceptance

Branch-policy cases must cover same-repo develop→main and feature/x→develop
(success), plus main→develop, docs/x→develop, feature/x→main, forks, empty
feature suffix, and event/live-head mismatch (failure). Read back live rules.
When a real PR is available, verify rejected/accepted routes through its
checks; account-wide review scope must be settled before intentionally targeting
main. Read back no-bypass PR/update rules for direct-push protection; do not
claim a rejected direct push unless an actual rejection was observed.

Run python3 scripts/sync-marketing.py --check, python3 scripts/test-marketing.py,
python3 scripts/test-release-sync.py, and node scripts/test-share.cjs. Run
xcodebuild unit tests with isolated derived data; do not run desktop-controlling
UI tests in parallel with browser/native inspection. Inspect the local site at
wide and narrow sizes and keyboard focus/reduced-motion states. For native UI,
inspect the built app or clearly label source-only findings if unavailable.
File-move changes require disposable fixtures and byte/source/destination checks.

A successful build is not signed-package, Gatekeeper, notarization, real Finder,
or newly published-release acceptance. Historical proof stays dated. Repository
rules applied live and CI passing are separate from deployment and UI acceptance.

## Risks and Open Evidence

Source-name checks depend on GitHub Actions availability and trusted workflow
integrity. Automatic review availability depends on account eligibility.
The patch-artifact release route adds a human PR step; docs must explain it.
Do not claim all runtime edge cases are resolved from document review alone.
Any discovered issue outside these bounded corrections must be recorded with
its impact and disposition rather than silently expanded into a redesign.
