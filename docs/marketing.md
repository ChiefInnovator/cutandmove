# Marketing content and version policy

`index.html` is the GitHub Pages marketing page. Keep important product facts in static visible HTML and mirror direct-answer FAQs into JSON-LD and the README. `llms.txt` is a supplemental summary, not a promise of AI-engine indexing.

- Current source version: Xcode `MARKETING_VERSION`; require all three components (for example, `1.0.2`).
- Published download version: `marketing.json` `released_version`; update only after verifying the matching non-draft GitHub Release and its signed/notarized artifacts.
- Release patch preparation: `.github/workflows/release-marketing.yml` runs for stable published releases or manual dispatch. It reads the latest stable release, validates uploaded DMG/ZIP/checksum/license assets, generates the four marketing files, and tests them. With a read-only token, it uploads a `release-marketing` patch artifact retained seven days. It never commits, pushes, or deploys. An already-current run produces a summary and no artifact. Asset presence does not establish signing/notarization; `make release` and `make publish` retain that responsibility.
- Merge source into `main` through `feature/*` → `develop` → `main` before publishing the matching binary release. Drafts/prereleases/tag-only pushes do not promote downloads. Old events cannot downgrade the record. Write release highlights in source; generation synchronizes versions and availability, not new prose.
- Recovery: `gh workflow run release-marketing.yml` repeats preparation after correcting assets or an expired artifact. If a future workflow publishes using `GITHUB_TOKEN`, explicitly dispatch patch preparation because token-created release events do not start another workflow. No PAT or protected-branch bot bypass is needed.
- Canonical origin: `marketing.json` `site_url`; currently the actual GitHub Pages URL, not an assumed custom-domain route.
- Run `make marketing` after changes. Generated regions are marked with HTML comments. `make marketing-check` and CI detect drift; `python3 scripts/test-marketing.py` tests FAQ parity and future version bumps.
- Keep draft features labeled as previews. SoftwareApplication metadata describes the published version, not unreleased improvements. Never add invented ratings, reviews, stock availability, or security guarantees.
- Social images use the canonical site origin. Relative site links work under the `/cutandmove/` project path.
- No JavaScript is required to read version numbers or product answers. Repository visibility, crawler controls, and hosting permissions are not changed by these scripts.

This follows [Google's AI search guidance](https://developers.google.com/search/docs/appearance/ai-features): helpful crawlable text, clear facts, and structured data consistent with visible content. SEO/AEO/GEO work cannot guarantee ranking, indexing, or AI citations; FAQ markup does not imply rich-result eligibility.

## Apply a release patch

The promotion operator owns these steps. Download the successful run's artifact
and inspect its `base-sha.txt`, `release.json`, and `release-marketing.patch`.
Use the actual run ID and version in place of the placeholders below.

```sh
gh run download RUN_ID -n release-marketing -D /tmp/cutandmove-release-patch
git fetch origin
git switch -c feature/release-marketing-VERSION origin/develop
git apply --check /tmp/cutandmove-release-patch/release-marketing.patch
git apply /tmp/cutandmove-release-patch/release-marketing.patch
make marketing-check
python3 scripts/test-marketing.py
python3 scripts/test-release-sync.py
node scripts/test-share.cjs
node scripts/test-branch-policy.cjs
node scripts/test-governance.cjs
git diff --check
git diff --stat
```

Review the four generated files, commit, push the feature branch, and open a PR
to develop. Wait for CI and automatic review, then merge and promote develop to
main with another PR. If `git apply --check` fails on a changed baseline, do not
force apply. On the feature branch run
`python3 scripts/sync-release.py /tmp/cutandmove-release-patch/release.json`,
inspect its four-file diff, and repeat the checks before committing.

## Verify deployment after promotion

Pages serves main at `/`; a successful patch artifact is not a deployment.
After the main PR merges, the promotion operator fetches/checks out that main
commit and checks the legacy Pages build:

```sh
gh api repos/ChiefInnovator/cutandmove/pages/builds/latest --jq '{status,commit,error}'
curl -fsSL 'https://chiefinnovator.github.io/cutandmove/?deployment-check=COMMIT_SHA' -o /tmp/cutandmove-live.html
cmp index.html /tmp/cutandmove-live.html
```

Wait for the build's commit to match the promoted main commit and for `cmp` to
pass; retry after a pending build or stale cache. Confirm the expected published
DMG link and inspect the rendered page. A build failure, stale content, or a
mismatched link remains unresolved deployment evidence. Never poll for unapplied
patch content inside patch preparation or claim a new binary release from it.
