# Publication — partial delivery

Date: September 5, 2026 (UTC). This campaign is not fully cross-posted yet.

## Repository

- Finished six-slide campaign, editable sources, provenance, caption and alt text committed and pushed to `main` at `ad00b8ef67a7cc0116056b9ae970ef4ff3264753` before upload.
- Hosted assets are pinned to that immutable commit. All six JPEGs are 1080 × 1350 sRGB, under 200 KB; every rendered slide and the complete contact sheet were visually inspected. Secret-value, file-size, caption/alt limits, syntax, and whitespace checks passed.
- Existing campaigns and unrelated `.vscode/` settings were preserved.

## Instagram — published

- Destination: Inventing Fire with AI, `@inventingfire_with_ai`, ID `17841472905022055`.
- Post: https://www.instagram.com/p/Dc7HW4AiUVk/
- Post ID: `18124002169873848`.
- Carousel container: `17919417111430168`.
- Graph API v25.0 publishing completed. Per-child IDs, source URLs/hashes, published child IDs, and the returned caption are in `publication-state.json`.
- Read-back verified exact account, caption, CAROUSEL_ALBUM media type, six children, all six exact alt texts, and slide order. The returned published images were downloaded and their ordered preview visually checked; portrait aspect ratio, text, arrows, icon and real About capture survived publication.
- The public post page independently confirms the account, version 2.0.1 and visible @richcrane caption mention. All six child creation requests included his person tag and were accepted. **The native person-tag overlay remains unverified in the browser**: the current Chrome accessibility view exposes only a media menu and its screenshot capture is unavailable. Do not describe that overlay check as complete.
- AI-content disclosure was requested on the parent carousel because the reused app artwork has documented AI provenance. No collaborators, paid promotion, profile edits or schedules were requested.
- Do not publish this Instagram campaign again while resuming Facebook or the remaining visual tag check.

## Facebook — blocked, not posted

- Assigned destination: [Inventing Fire with AI Page](https://www.facebook.com/525320574007742), ID `525320574007742`. A live read-only lookup verified its name and association with Instagram account `17841472905022055`.
- User clarified during this campaign that promote-product must cross-post to all assigned places. The local skill now includes this Page and the Instagram account, requires per-platform verification, and prohibits declaring success based on account linking alone. The updated skill passed its validator.
- No Facebook publishing attempt was made. The current token has Page-read and Instagram-publishing scopes but lacks `pages_manage_posts`.
- Read-only Page access was validated using its Page token only in process memory. Its 20 returned recent feed entries contain no matching Cut & Move v2.0.1 post; no automatic cross-post was observed. This is a recent-feed check, not proof about all historical posts.
- Native Chrome navigation reached Facebook, but the available accessibility/screenshot interface did not expose a usable Page composer. No Facebook draft or Share action was submitted.
- `facebook-caption.txt` and the same ordered `slide-01.jpg` through `slide-06.jpg` are ready. The Facebook caption removes Instagram's copy/type-URL instruction; required @richcrane text is retained. Use the existing per-slide alt text where the Facebook composer supports it.
- Dependency: user opens the assigned Page's Create post composer in a controllable signed-in browser, or securely provisions the Page's authorized publishing access. Never request credentials in chat or broaden token scopes automatically.
- Before resuming, recheck recent Page posts to avoid duplicates, verify Page identity, and preserve image order. Record the actual Facebook post ID/permalink after publication.
