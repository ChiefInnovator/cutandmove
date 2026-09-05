#!/usr/bin/env python3
"""Generate static, crawlable marketing facts from Xcode and the published-release record."""
import argparse
import html
import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def replace_block(text, name, content):
    start, end = f"<!-- {name}:start -->", f"<!-- {name}:end -->"
    pattern = re.escape(start) + r".*?" + re.escape(end)
    updated, count = re.subn(pattern, lambda _: f"{start}\n{content}\n{end}", text, flags=re.S)
    if count != 1:
        raise ValueError(f"Expected exactly one {name} block, found {count}")
    return updated


def outputs():
    settings = (ROOT / "CutAndMove.xcodeproj/project.pbxproj").read_text()
    versions = set(re.findall(r"MARKETING_VERSION = ([^;]+);", settings))
    if len(versions) != 1:
        raise ValueError("All Xcode marketing versions must match")
    current = versions.pop()
    config = json.loads((ROOT / "marketing.json").read_text())
    released, site = config["released_version"], config["site_url"]
    for version in (current, released):
        if not re.fullmatch(r"\d+\.\d+\.\d+", version):
            raise ValueError(f"Use the full major.minor.patch version: {version}")
    if not site.startswith("https://") or not site.endswith("/"):
        raise ValueError("site_url must be an HTTPS directory URL ending in /")
    repo = "https://github.com/ChiefInnovator/cutandmove"
    release = f"{repo}/releases/tag/v{released}"
    preview = current != released
    status = "development preview; not yet published" if preview else "published release"
    version_fact = f"Current source: v{current} ({status}). Published download: v{released}."
    title = f"Cut & Move v{released} — Cmd+X Cut and Paste for Mac Finder"
    description = f"Cut and paste files in macOS Finder with Cmd+X and Cmd+V. Cut & Move v{released}: a native menu bar app with launch at login. Requires macOS 26.1+."
    questions = [
        ("What is Cut & Move?", "Cut & Move is a native macOS menu bar utility that adds Cmd+X followed by Cmd+V for moving files in Finder. It uses Finder's built-in Move Item Here command rather than replacing Finder."),
        ("How do I cut and paste files on a Mac?", "Without an app, select files in Finder, press Cmd+C, open the destination, then press Cmd+Option+V to move them. With Cut & Move running, use Cmd+X followed by Cmd+V instead."),
        ("Which version can I download?", f"The published download is Cut & Move v{released}, available as a Developer ID signed, Apple-notarized DMG or ZIP on GitHub Releases. The current source is v{current} ({status}). It is not distributed through the Mac App Store."),
        ("What are the macOS and hardware requirements?", "Cut & Move requires macOS 26.1 or later. The universal macOS app supports Apple silicon and Intel Macs that can run the required macOS version."),
        ("Why does Cut & Move need Accessibility permission?", "Accessibility permission lets the app intercept and modify keyboard events for Finder shortcuts. The app does not record keystrokes, collect analytics, or transmit file contents. You can revoke access in System Settings > Privacy & Security > Accessibility."),
        ("Does Cut & Move change shortcuts in other apps?", "Cut & Move targets Finder. Other apps keep their normal Cmd+X and Cmd+V behavior. Finder performs the actual file move and presents any file-conflict dialogs."),
        ("How do I cancel cut mode?", "Press Escape or Cmd+C to cancel a pending cut. The menu bar scissors icon indicates whether cut mode is active."),
        ("Is Cut & Move free or open source?", "Cut & Move is free for uses permitted by PolyForm Strict 1.0.0. Its source is available on GitHub, but it is not offered under an unrestricted open-source license. Read LICENSE for use, modification, and distribution restrictions."),
        ("Who makes Cut & Move and how do I get support?", "Cut & Move was created by Richard Crane, Microsoft MVP and founder of MILL5. Contact rich@mill5.com for support."),
    ]
    faq = {"@type": "FAQPage", "@id": site + "#faq", "mainEntity": [
        {"@type": "Question", "name": q, "acceptedAnswer": {"@type": "Answer", "text": a}} for q, a in questions
    ]}
    graph = {"@context": "https://schema.org", "@graph": [
        {"@type": "WebPage", "@id": site, "url": site, "name": title, "description": description,
         "inLanguage": "en", "about": {"@id": site + "#app"}, "mainEntity": {"@id": site + "#app"}},
        {"@type": "SoftwareApplication", "@id": site + "#app", "name": "Cut & Move",
         "alternateName": "Cut and Move", "softwareVersion": released,
         "applicationCategory": "UtilitiesApplication", "operatingSystem": "macOS 26.1 or later",
         "description": description, "url": site, "downloadUrl": release,
         "image": site + "CutAndMove/Assets.xcassets/AppIcon.appiconset/512.png",
         "license": repo + "/blob/main/LICENSE", "releaseNotes": release,
         "featureList": ["Cmd+X / Cmd+V file moves in Finder", "Menu bar cut-mode indicator", "Optional launch at login", "Escape or Cmd+C cancellation", "No analytics or third-party dependencies"],
         "author": {"@id": site + "#creator"}},
        {"@type": "Person", "@id": site + "#creator", "name": "Richard Crane", "url": "https://inventingfirewith.ai",
         "sameAs": ["https://github.com/ChiefInnovator", "https://mvp.microsoft.com/en-US/MVP/profile/10ce0bc0-7536-43f6-b28c-e9601a4a0d0d"],
         "worksFor": {"@type": "Organization", "name": "MILL5", "url": "https://mill5.com"}}, faq
    ]}
    esc = html.escape
    metadata = f'''  <title>{esc(title)}</title>
  <meta name="description" content="{esc(description)}">
  <meta name="author" content="Richard Crane">
  <meta name="robots" content="index, follow, max-snippet:-1, max-image-preview:large">
  <meta name="theme-color" content="#0a0a0c">
  <meta name="application-name" content="Cut &amp; Move">
  <link rel="canonical" href="{site}">
  <link rel="alternate" type="text/plain" href="llms.txt" title="Cut &amp; Move product facts">
  <link rel="icon" type="image/png" href="CutAndMove/Assets.xcassets/AppIcon.appiconset/512.png">
  <link rel="apple-touch-icon" href="CutAndMove/Assets.xcassets/AppIcon.appiconset/512.png">
  <meta property="og:type" content="website">
  <meta property="og:site_name" content="Cut &amp; Move">
  <meta property="og:title" content="{esc(title)}">
  <meta property="og:description" content="{esc(description)}">
  <meta property="og:url" content="{site}">
  <meta property="og:image" content="{site}og-image.png">
  <meta property="og:image:width" content="1200">
  <meta property="og:image:height" content="630">
  <meta property="og:image:alt" content="Cut &amp; Move: Cmd+X file moves in macOS Finder">
  <meta property="og:locale" content="en_US">
  <meta name="twitter:card" content="summary_large_image">
  <meta name="twitter:title" content="{esc(title)}">
  <meta name="twitter:description" content="{esc(description)}">
  <meta name="twitter:image" content="{site}og-image.png">
  <meta name="twitter:image:alt" content="Cut &amp; Move: Cmd+X file moves in macOS Finder">
  <script type="application/ld+json">{json.dumps(graph, ensure_ascii=False, indent=2)}</script>'''
    page = (ROOT / "index.html").read_text()
    page = replace_block(page, "seo", metadata)
    page = replace_block(page, "version", f'<p class="version-summary">{esc(version_fact)}</p>')
    page = replace_block(page, "nav-download", f'<a href="#download" class="nav-cta">Download v{released}</a>')
    page = replace_block(page, "hero-download", f'Download v{released} for macOS')
    page = replace_block(page, "download", f'<a href="{release}" class="btn btn-primary">Download Cut &amp; Move v{released} for macOS</a>')
    page = replace_block(page, "download-version", f'<p class="version-summary">Signed and notarized DMG or ZIP. {esc(version_fact)}</p>')
    page = replace_block(page, "preview-version", f'<h3>What\'s {"coming in" if preview else "new in"} v{current}?</h3>\n<p>{esc(status.capitalize())}. See the <a href="{repo}/blob/main/docs/RELEASE_NOTES_{current}.md">v{current} release notes</a>.</p>')
    page = replace_block(page, "faq", '\n'.join(f'<details class="faq-item"><summary>{esc(q)}</summary><p class="faq-item-body">{esc(a)}</p></details>' for q, a in questions))
    readme = (ROOT / "README.md").read_text()
    readme = replace_block(readme, "overview", f'''# Cut & Move v{current} — Cmd+X Cut and Paste for macOS Finder

Cut & Move is a native macOS menu bar app that adds **Cmd+X → Cmd+V file moves to Finder**. Use familiar cut-and-paste shortcuts while Finder handles the actual move and any conflicts.

**{version_fact}**

[Download v{released}]({release}) · [Marketing page]({site}) · [Setup guide](docs/setup.md) · [v{current} release notes](docs/RELEASE_NOTES_{current}.md)

| Product fact | Details |
| :--- | :--- |
| Published version | v{released} — signed and notarized DMG / ZIP |
| Current source | v{current} — {status} |
| Compatibility | macOS 26.1 or later; Apple silicon and Intel |
| Permission | Accessibility access for Finder keyboard shortcuts |
| License | Free for uses permitted by [PolyForm Strict 1.0.0](LICENSE) |
| Distribution | GitHub Releases; no Mac App Store version |
| Privacy | No keystroke recording, analytics, or application network requests |
| Creator and support | Richard Crane, MILL5 · [rich@mill5.com](mailto:rich@mill5.com) |''')
    readme = replace_block(readme, "faq", '## Frequently asked questions\n\n' + '\n\n'.join(f'### {q}\n\n{a}' for q, a in questions))
    readme = replace_block(readme, "preview-version", f'## {"Coming in" if preview else "New in"} v{current}\n\n{status.capitalize()}. The enhancements below describe the current source, not an older download.')
    llms = f'''# Cut & Move

> Native macOS menu bar app for Cmd+X followed by Cmd+V file moves in Finder. By Richard Crane at MILL5.

## Version and availability

{version_fact}

- Canonical marketing page: {site}
- Published download v{released}: {release}
- Current source v{current}: {repo}
- Requirements: macOS 26.1+, Apple silicon or Intel, Accessibility permission.
- Distribution: Developer ID signed and Apple-notarized DMG/ZIP releases, not the Mac App Store. Do not describe an unpublished source version as a notarized download.
- License: PolyForm Strict 1.0.0; free only for permitted uses, not unrestricted open source.
- Privacy: no keystroke recording, telemetry, or application network requests.

## Direct answers

''' + '\n\n'.join(f'### {q}\n\n{a}' for q, a in questions) + f'''

## Source and documentation

- [README]({repo}/blob/main/README.md): Features, compatibility, version status, installation.
- [Setup]({repo}/blob/main/docs/setup.md): Permissions and troubleshooting.
- [Architecture]({repo}/blob/main/docs/architecture.md): Keyboard processing and safety boundaries.
- [Current release notes]({repo}/blob/main/docs/RELEASE_NOTES_{current}.md): Current-source changes; check availability above.
- [License]({repo}/blob/main/LICENSE): Complete terms.

Current-source enhancements include Finder text-field guards, clipboard freshness checks, mouse-switch cancellation, disabled-tap recovery, login-item approval guidance, and a full-bleed icon. If the current source differs from the published version, treat these as preview features, not download guarantees.
'''
    return {"index.html": page, "README.md": readme, "llms.txt": llms}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true", help="Fail on stale generated content without editing")
    args = parser.parse_args()
    stale = []
    for name, content in outputs().items():
        path = ROOT / name
        if path.read_text() != content:
            stale.append(name)
            if not args.check:
                path.write_text(content)
    if args.check and stale:
        raise SystemExit("Stale marketing content: " + ", ".join(stale) + ". Run python3 scripts/sync-marketing.py")
    print("Marketing version, release facts, metadata, and FAQs are consistent." if not stale else "Updated: " + ", ".join(stale))


if __name__ == "__main__":
    main()
