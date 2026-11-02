# Verification — November 2, 2026

Evidence is scoped to the named source/run, not a new binary release. Current
feature delivery is tracked in [PR #4](https://github.com/ChiefInnovator/cutandmove/pull/4).

## Local application and workflow checks

All passed after the final production corrections:

- `make marketing-check`.
- `python3 scripts/test-marketing.py`: 4 tests, including published/preview FAQ,
  release-specific hardware at both download blocks, and static share fallback.
- `python3 scripts/test-release-sync.py`: 6 tests.
- `node scripts/test-share.cjs`: success, denied permission, unsupported API.
- `node scripts/test-branch-policy.cjs`: 17 legal/illegal route, fork/deleted repo,
  source/base/head/SHA stale-event cases against the actual trusted inline script. Five additional actual-shell cases
  verify the legacy compatibility check passes only validator success.
- `node scripts/test-governance.cjs`: privileged-workflow contracts plus execution
  of the actual release patch shell in a disposable Git repository; empty patch,
  changed patch, unchanged HEAD/branch, four-file scope, and apply round trip.
- actionlint 1.7.12: no workflow errors. Official release SHA-256 verified.
- `git diff --check origin/develop`: no whitespace errors in project changes.
  Vendored .agents bytes are intentionally exempt via .gitattributes, including
  upstream Windows CRLF launchers. Upstream runtime prompts were not reformatted.
- Unit-only `xcodebuild -project CutAndMove.xcodeproj -scheme CutAndMove
  -destination platform=macOS -derivedDataPath /tmp/cutandmove-review-derived
  -only-testing:CutAndMoveTests test`: 26 tests / 34 executions, zero failures/skips.
  App and extension compile with the final permission/menu/About/count changes.

Full logs remain outside Git at `/tmp/cutandmove-review-complete-*`. The user's
pre-existing exported app remained running; no test host was left behind.
No desktop-controlling UI suite or Finder fixture harness was run.

## Installed tooling and review evidence

Seven EGM skill entry points, all reviewer personas/standards/support references,
canonical icon/license, and provenance are project-local. EGM revision:
403d8881d62022490637d740657b33f01e321ea8. Thirty core prompt/persona/standard/asset
files and 67 unadapted runtime files match pinned upstream bytes. The local
consumer README and 11 declared documentation adaptations explain/link the full
upstream source checkout for development-only builders and tests. Sixty-four
installed relative Markdown links resolve, excluding illustrative template paths.

Pinned full upstream checkout: 165 offline unit tests pass; OpenAI runtime/ZIP
package each contain 54 files. Logs: /tmp/cutandmove-egm-{unit,pack,installed,parity,diff}.log.
No package was uploaded. These source tests do not establish host-native plugin
installation/picker UI acceptance. Actual fresh-context EGM stages 5–9 plus one
focused recheck completed here; see the individual EGM reports.

Impeccable skill 4.8.0 / engine 0.1.18 is installed with project-local launchers and
checksums; platform-specific binaries remain ignored. PRODUCT.md, DESIGN.md,
sidecar, surface briefs, and closed critique snapshots are present. Web fix
verification passed at desktop and 390×844; native review remains source-only.
Final source detector: 7 unsuppressed pattern warnings, zero inventory advisories.
See impeccable-review.md for findings, scores, triage, contrast, and boundaries.

## Live GitHub branch and review checks

Bootstrap commit 96b288e installed the trusted workflow on main before protection,
and develop was created from the identical commit. Active no-bypass rulesets:
[main 26359272](https://github.com/ChiefInnovator/cutandmove/rules/26359272) and
[develop 26359276](https://github.com/ChiefInnovator/cutandmove/rules/26359276).
They require PRs, source validation from GitHub Actions app 15368, resolved
conversations, no deletion/force pushes, and merge commits. Zero human approvals
supports solo maintenance; Copilot remains advisory.

A real draft PR #4 at head 7f75cd125d6428603a66e0d4f5b59b7c9f8e80e6 targeted main:
Branch policy run 41433053028 failed the required `Branch source` check and GitHub
reported mergeable_state=blocked. The PR had no reviews/requested reviewers.
Retargeting the same real change to develop passed (run 41433113295); ready-state
runs also passed. This is actual route rejection/acceptance, not just VM proof.
No rejected direct-push test was attempted; direct-push protection is supported
by effective active no-bypass PR rules, not a claimed push rejection.

The owner authorized disabling account-wide automatic Copilot reviews. A refreshed
GitHub account settings page showed Automatic Copilot code review off, with its
push/draft controls disabled. Only develop's repository ruleset includes automatic
Copilot review (review_on_push=true; draft reviews=false); main has no such rule.
PR #4 automatically ran Copilot 41433272657 on 7f75cd1 after ready state. It completed
and identified 13 low-severity consumer-documentation/evidence issues. The working
changes add the evidence destination, correct bootstrap wording, and redirect
upstream-source-only testing/packaging instructions without altering runtime
prompts. No review was requested or re-requested manually.

The next automatic review completed on f96acd1 (run41435197517) and identified
one check-name migration hazard. The workflow now retains a legacy compatibility
job that always evaluates the canonical validator result. Actual-shell tests
prove success forwarding and failure on failed/cancelled/skipped/missing results.
This keeps the bootstrap required context enforced while the rulesets switch to
target-specific names. Actionlint and both governance suites pass after the fix.

The following exact-head review completed on 880750e (run41436509292), with no
open inline issues and all14 conversations resolved. Its summary identified stale
setup-guide labels and success-window timing; docs/setup.md now matches Keyboard
Shortcut Settings, persistent Ready/Done, Retry Monitoring, and counted move labels.

## Acceptance boundaries

A passing unit build is not native UI/VoiceOver, real Finder file-operation,
Developer ID, notarization, Gatekeeper, or new-release acceptance. Historical
v2.0.0 signed Finder evidence remains dated in REVIEW_VERIFICATION.md. This task
changes source/docs/site/CI, not the user's installed binary or version record.
Pages deployment and target-specific final check registration must be verified
against actual promotion commits; local tests do not establish either outcome.
