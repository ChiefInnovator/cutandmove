# Marketing content and version policy

`index.html` is the GitHub Pages marketing page. Keep important product facts in static visible HTML and mirror direct-answer FAQs into JSON-LD and the README. `llms.txt` is a supplemental summary, not a promise of AI-engine indexing.

- Current source version: Xcode `MARKETING_VERSION`; require all three components (for example, `1.0.2`).
- Published download version: `marketing.json` `released_version`; update only after verifying the matching non-draft GitHub Release and its signed/notarized artifacts.
- Canonical origin: `marketing.json` `site_url`; currently the actual GitHub Pages URL, not an assumed custom-domain route.
- Run `make marketing` after changes. Generated regions are marked with HTML comments. `make marketing-check` and CI detect drift; `python3 scripts/test-marketing.py` tests FAQ parity and future version bumps.
- Keep draft features labeled as previews. SoftwareApplication metadata describes the published version, not unreleased improvements. Never add invented ratings, reviews, stock availability, or security guarantees.
- Social images use the canonical site origin. Relative site links work under the `/cutandmove/` project path.
- No JavaScript is required to read version numbers or product answers. Repository visibility, crawler controls, and hosting permissions are not changed by these scripts.

This follows [Google's AI search guidance](https://developers.google.com/search/docs/appearance/ai-features): helpful crawlable text, clear facts, and structured data consistent with visible content. SEO/AEO/GEO work cannot guarantee ranking, indexing, or AI citations; FAQ markup does not imply rich-result eligibility.
