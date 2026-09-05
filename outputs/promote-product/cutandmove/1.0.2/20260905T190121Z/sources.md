# Sources and verification — September 5, 2026

- Product and workflow: [README](https://github.com/ChiefInnovator/cutandmove/blob/3f85acf9a42c5d815162f0ea51a835d313850630/README.md).
- Released, not preview: [v1.0.2 release](https://github.com/ChiefInnovator/cutandmove/releases/tag/v1.0.2), verified through GitHub API: draft false, prerelease false.
- New capabilities: [v1.0.2 release notes](https://github.com/ChiefInnovator/cutandmove/blob/3f85acf9a42c5d815162f0ea51a835d313850630/docs/RELEASE_NOTES_1.0.2.md). Slides 3–5 describe changes from v1.0.1; slide 2 explains the existing core workflow. Signing/notarization preceded this release and are not described as new.
- [Previous v1.0.1 notes](https://github.com/ChiefInnovator/cutandmove/blob/3f85acf9a42c5d815162f0ea51a835d313850630/docs/RELEASE_NOTES_1.0.1.md) contain historical private-repository access information. Current repository and release are public; the campaign uses the current verified destination.
- Primary CTA and messaging: https://chiefinnovator.github.io/cutandmove/ — live page checked this session.
- Direct asset: https://github.com/ChiefInnovator/cutandmove/releases/download/v1.0.2/CutAndMove.dmg
- Icon provenance: existing product artwork, `CutAndMove/Assets.xcassets/AppIcon.appiconset/512.png`; its origin is documented in `docs/icon.md`. Reused without redesign. No screenshots or invented app UI.
- Branding assumption: typographic Inventing Fire with AI treatment, not an invented official logo. Navy/blue from the product page with a warm orange brand accent. Original editable SVG composition; no newly generated photographic imagery.

## Instagram publishing route

Official Meta pages read live in browser (web fetch was rate-limited):

- https://developers.facebook.com/documentation/instagram-platform/content-publishing (updated June 30, 2026).
- https://developers.facebook.com/documentation/instagram-platform/instagram-graph-api/reference/ig-user/media (updated August 12, 2026).

Verified requirements: JPEG, sRGB, maximum 8 MB, width 320–1440, aspect ratio 4:5–1.91:1; up to 10 carousel children. Export: six ordered 1080 × 1350 JPEG slides, all 4:5. Image alt text supports up to 1000 characters; caption limit 2200 characters. `user_tags` supports public usernames with fractional x/y coordinates. Current reference uses Graph API v26.0 and Bearer authorization.

Live read-only v26.0 account lookup confirmed `inventingfire_with_ai`, name `Inventing Fire with AI`, ID `17841472905022055`. Required `instagram_basic`, `instagram_content_publish`, and `pages_read_engagement` permissions were granted. Publishing quota was 3 of 100 before this campaign. Credentials stay outside the repository and are never logged.

Hosting: immutable raw GitHub URLs in this authorized product repository, pinned to the campaign asset commit. Only these six JPEGs are submitted. Caption visibly mentions @richcrane; every image also requests his person tag. No collaborators, paid-partnership tags, profile changes, or schedules.
