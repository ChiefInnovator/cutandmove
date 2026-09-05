# Sources and verification — September 5, 2026

## Product and release claims

- [Published v2.0.1](https://github.com/ChiefInnovator/cutandmove/releases/tag/v2.0.1): GitHub API confirmed latest, published stable, not draft or prerelease. Published 2026-09-05T23:02:05Z.
- [v2.0.1 release notes](https://github.com/ChiefInnovator/cutandmove/blob/c33c1e88269a0e2699cc8f9851d6228d22873b5d/docs/RELEASE_NOTES_2.0.1.md): Apple-silicon-only app and Finder extension, build 6, M1 or later and macOS 26.1+. This is the new change promoted on slides 1–2.
- [Previous v2.0.0 notes](https://github.com/ChiefInnovator/cutandmove/blob/c33c1e88269a0e2699cc8f9851d6228d22873b5d/docs/RELEASE_NOTES_2.0.0.md): Finder Sync contextual actions, toolbar menu, pending badges, shared keyboard/menu state, automatic mounted-drive/local-folder coverage, and file-move safeguards. Slides 3–5 describe included features, not changes first introduced by v2.0.1.
- [README](https://github.com/ChiefInnovator/cutandmove/blob/c33c1e88269a0e2699cc8f9851d6228d22873b5d/README.md): keyboard workflow, installation, permissions, license and distribution. No claims of unrestricted open-source licensing or guaranteed engagement.
- [Live marketing page and primary CTA](https://chiefinnovator.github.io/cutandmove/): fetched this session; full version 2.0.1, Apple-silicon-only requirement, and v2.0.1 DMG link confirmed.
- [Direct DMG](https://github.com/ChiefInnovator/cutandmove/releases/download/v2.0.1/CutAndMove.dmg): verified release asset. Earlier release checks downloaded the DMG, verified its checksum, mounted it read-only, and validated arm64 architecture for both binaries, MILL5 signatures, stapled notarization, and Gatekeeper acceptance.
- Copyright in the real About capture is 2025–2026 Richard Crane. The visible app version is 2.0.1 (6).

## Visual provenance

- `assets/app-icon.png` is an unchanged copy of `CutAndMove/Assets.xcassets/AppIcon.appiconset/512.png`. [Icon provenance](https://github.com/ChiefInnovator/cutandmove/blob/c33c1e88269a0e2699cc8f9851d6228d22873b5d/docs/icon.md) records the earlier AI-assisted artwork. It has no baked-in outer tile; macOS may apply its own icon presentation.
- `assets/about.png` is an unchanged copy of the verified real light-theme `About Image.png` at commit c33c1e88269a0e2699cc8f9851d6228d22873b5d. Not generated or simulated UI. The full screenshot is proportionally placed on slide 2.
- Original SVG/type layouts use the established campaign navy, blue and warm orange, plus light feature slides. Inventing Fire with AI is a typographic campaign treatment, not a fabricated official logo. No new generated photos or illustrations. Keyboard diagrams are explanatory graphics, not screenshots.
- Six final JPEGs and the ordered preview were inspected; an initially missing arrow rendering was corrected before publication. Source PNG color-profile warnings did not affect visible rendering; exported JPEG metadata was stripped and sRGB verified.

## Official Meta requirements checked live

The web fetcher was rate-limited; the same official pages were retrieved successfully through HTTPS from the local environment on September 5, 2026:

- [IG User Media reference](https://developers.facebook.com/documentation/instagram-platform/instagram-graph-api/reference/ig-user/media): JPEG, sRGB, maximum 8 MB, width 320–1440 pixels, aspect ratio 4:5–1.91:1, alt text up to 1000 characters, public-username person tags with fractional x/y coordinates, and caption maximum 2200 characters. Current examples use v25.0.
- [Content Publishing guide](https://developers.facebook.com/documentation/instagram-platform/content-publishing): create children, create carousel, check status, publish. Up to ten children; common crop follows first image. The guide permits AI disclosure on the parent carousel, not child items.
- [Instagram Media reading reference](https://developers.facebook.com/documentation/instagram-platform/reference/instagram-media): read published caption, owner/username, children, media URLs, and image alt text for verification.

Export is six ordered 1080 × 1350 portrait (4:5) sRGB JPEGs, each below 200 KB. Caption is below 2200 characters and every alt description below 1000. Full version appears on every slide. Caption URLs are explicitly presented for copying/typing, not assumed clickable.

## Account and hosting

Live read-only Graph v25.0 lookup verified account `17841472905022055`, username `inventingfire_with_ai`, name `Inventing Fire with AI`. Required `instagram_basic`, `instagram_content_publish`, and `pages_read_engagement` scopes are granted. Reported publishing usage was 4 before this campaign. The credential file remains outside the repository; no credential values are recorded here.

Assets are hosted at immutable raw GitHub URLs in this authorized product repository, pinned to the campaign commit. Only the six slide JPEGs are uploaded to Meta. Caption visibly mentions @richcrane, and all six child containers request his image person tag. No collaborators, paid partnership, profile edits, schedules, or extra posts. Prior campaigns are preserved. Publication results and any verification limitations are recorded separately in `publication.md`.
