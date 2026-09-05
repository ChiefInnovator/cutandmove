"""Editable, deterministic SVG carousel. Uses the real product icon and About capture."""
import base64
import html
import json
from pathlib import Path
import subprocess

ROOT = Path(__file__).resolve().parent
FONT = '/System/Library/Fonts/Supplemental/Arial.ttf'
NAVY, BLUE, ORANGE, WHITE, MUTED = '#101828', '#258cff', '#ffad75', '#f7f9fc', '#bdcbdf'
SLIDES = [
    dict(label='NEW RELEASE', title=['Cut & Move', 'v2.0.1'], body=['Your fingers know Cmd+X.', 'Now Finder does too.'], note='Familiar file moves. Now Apple silicon only.'),
    dict(label='NEW IN v2.0.1', title=['Apple silicon.', 'Only.'], body=['An arm64 app and Finder extension.', 'For M1 and later. macOS 26.1+.'], note='Actual About window · v2.0.1 (build 6)'),
    dict(label='FINDER INTEGRATION · INCLUDED', title=['Right-click.', 'Keep moving.'], body=['Cut, Move Here, and Cancel Cut', 'live in Finder’s contextual menus.'], note='Finder Sync menus were introduced in v2.0.0.'),
    dict(label='KEYBOARD + MOUSE', title=['Two ways.', 'One cut selection.'], body=['Start with a shortcut. Finish with a click.', 'Or switch the order.'], note='Keyboard shortcuts require Accessibility access.'),
    dict(label='NO FOLDER SETUP', title=['Local folders.', 'Mounted drives.'], body=['Enable the Finder extension once.', 'Folder coverage is automatic.'], note='Protected and read-only locations still obey macOS permissions.'),
    dict(label='DOWNLOAD Cut & Move v2.0.1', title=['Less remembering.', 'More moving.'], body=['Get the signed, notarized DMG.', 'Drag to Applications. Open Cut & Move.'], note='Apple silicon only · macOS 26.1 or later'),
]
CAPTION = '''Your fingers know Cmd+X. Now Finder does too. ✂️

Cut & Move v2.0.1 is out for Apple silicon Macs.

NEW IN v2.0.1: an Apple-silicon-only app and Finder extension. No Intel binaries.

INCLUDED FROM v2.0.0: right-click Cut, Move Here, and Cancel Cut; a Finder toolbar menu; pending-cut badges; and one cut selection shared between keyboard shortcuts and contextual menus. Enable the extension once for automatic coverage of local folders and mounted drives.

Menu-driven moves reject existing destinations and changed sources. Normal macOS permissions still apply.

Download v2.0.1 and follow the setup guide:
https://chiefinnovator.github.io/cutandmove/
Type or copy the URL into your browser.

Requires an M1-or-later Mac and macOS 26.1+. Accessibility access enables the keyboard shortcuts; enable the Finder extension for its menus. MILL5 Developer ID signed and Apple notarized. Direct download, not the Mac App Store. Free for uses permitted by PolyForm Strict 1.0.0.

Created by @richcrane. Save this workflow—or send it to a Mac user who still reaches for Cmd+X.

#CutAndMove #MacProductivity #AppleSilicon #Finder #InventingFireWithAI'''


def text(lines, x, y, size, color=WHITE, weight='normal', step=None):
    return ''.join(f'<text x="{x}" y="{y+i*(step or size*1.22)}" font-size="{size}" font-weight="{weight}" fill="{color}">{html.escape(line)}</text>' for i, line in enumerate(lines))


def rect(x, y, w, h, fill, radius=0):
    return f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="{radius}" fill="{fill}"/>'


def image(name, x, y, w, h):
    encoded = base64.b64encode((ROOT / 'assets' / name).read_bytes()).decode()
    return f'<image x="{x}" y="{y}" width="{w}" height="{h}" href="data:image/png;base64,{encoded}" preserveAspectRatio="xMidYMid meet"/>'


def arrow(x, y):
    return text(['→'], x, y+25, 76, ORANGE, 'bold')


alts = []
for i, slide in enumerate(SLIDES, 1):
    light = i in (2, 5)
    ink, secondary, bg = (NAVY, '#48576b', WHITE) if light else (WHITE, MUTED, NAVY)
    accent = '#ae470b' if light else ORANGE
    drawing = rect(0, 0, 1080, 1350, bg)
    drawing += rect(76, 90, 46, 6, accent)
    drawing += text(['INVENTING FIRE WITH AI'], 76, 143, 25, secondary, 'bold')
    drawing += text([slide['label']], 76, 247, 25, accent, 'bold')
    drawing += text(slide['title'], 76, 357, 78 if i not in (4, 6) else 69, ink, 'bold', 93)
    drawing += text(slide['body'], 76, 558, 34, secondary, step=48)
    if i == 1:
        drawing += image('app-icon.png', 720, 695, 280, 280)
        drawing += rect(76, 719, 250, 210, '#243c5c', 26)
        drawing += text(['Cmd+X'], 100, 840, 52, weight='bold')
        drawing += arrow(364, 824)
        drawing += text(['Cmd+V'], 470, 842, 52, weight='bold')
        drawing += text(['CUT', 'THEN MOVE'], 76, 1001, 26, MUTED, 'bold', 39)
    elif i == 2:
        drawing += text(['M1+', 'ARM64'], 76, 804, 97, BLUE, 'bold', 99)
        drawing += text(['App + extension', 'No Intel binaries'], 76, 968, 29, secondary, step=44)
        drawing += image('about.png', 496, 637, 508, 524)
    elif i == 3:
        for n, (heading, detail) in enumerate([('Cut', 'Select the files you want to move.'), ('Move Here', 'Choose the destination in Finder.'), ('Cancel Cut', 'Clear the pending selection.')]):
            y = 733 + n * 134
            drawing += text([f'0{n+1}'], 76, y, 40, ORANGE, 'bold')
            drawing += text([heading], 166, y, 46, WHITE, 'bold')
            drawing += text([detail], 166, y+46, 29, MUTED)
    elif i == 4:
        for y, left, right, label in [(729, 'Cmd+X', 'Move Here', 'KEYBOARD → FINDER MENU'), (935, 'Menu Cut', 'Cmd+V', 'FINDER MENU → KEYBOARD')]:
            drawing += text([label], 76, y-35, 24, ORANGE, 'bold')
            drawing += rect(76, y, 377, 120, '#243c5c', 18) + rect(598, y, 406, 120, '#243c5c', 18)
            drawing += text([left], 108, y+78, 45, weight='bold') + text([right], 628, y+78, 45, weight='bold')
            drawing += arrow(490, y+60)
    elif i == 5:
        drawing += rect(76, 690, 928, 356, '#e6edf6', 25)
        drawing += text(['No folder picker.', 'No allowlist.'], 110, 778, 56, NAVY, 'bold', 75)
        drawing += text(['Menu moves reject existing destinations', 'and changed sources.'], 110, 951, 31, secondary, step=46)
        drawing += text(['Virtual Finder views may not expose a destination.'], 76, 1095, 27, secondary)
    else:
        drawing += rect(76, 687, 928, 203, '#243c5c', 24)
        drawing += text(['chiefinnovator.github.io/', 'cutandmove/'], 110, 771, 49, WHITE, 'bold', 69)
        drawing += text(['Enable Finder extension for menu actions.', 'Grant Accessibility access for shortcuts.'], 76, 964, 32, MUTED, step=46)
        drawing += text(['SAVE THIS · SEND IT TO A MAC USER'], 76, 1089, 26, ORANGE, 'bold')
    drawing += text([slide['note']], 76, 1177, 25 if i == 5 else 27, secondary)
    drawing += f'<path d="M76 1220 H1004" stroke="{secondary}" stroke-opacity="0.4"/>'
    drawing += text(['@richcrane'], 76, 1272, 24, accent)
    drawing += text(['Cut & Move v2.0.1'], 393, 1272, 24, secondary)
    drawing += text([f'{i:02d} / 06'], 904, 1272, 24, secondary)
    svg = ROOT / f'slide-{i:02d}.svg'
    svg.write_text(f'<svg xmlns="http://www.w3.org/2000/svg" width="1080" height="1350" viewBox="0 0 1080 1350"><g font-family="Arial">{drawing}</g></svg>')
    subprocess.run(['magick', '-font', FONT, str(svg), '-colorspace', 'sRGB', '-strip', '-quality', '94', str(svg.with_suffix('.jpg'))], check=True)
    alt = f"Slide {i} of 6. Inventing Fire with AI. " + ' '.join([slide['label'], *slide['title'], *slide['body'], slide['note']])
    alt += [
        ' Keyboard workflow diagram: Cmd+X then Cmd+V. Real app icon: black scissors and a smiling white face with a blue corner.',
        ' M1+, arm64. Real light-theme About screenshot shows version 2.0.1 (6), the current icon, Richard Crane attribution, and copyright 2025–2026.',
        ' Three steps: Cut selects the files; Move Here chooses the destination; Cancel Cut clears the selection.',
        ' Two workflow diagrams: Cmd+X to Move Here; Menu Cut to Cmd+V.',
        ' No folder picker or allowlist. Menu moves reject existing destinations and changed sources. Virtual Finder views may not expose a destination.',
        ' Download: chiefinnovator.github.io/cutandmove/. Enable the Finder extension for menus and Accessibility for shortcuts. Save or share with a Mac user.',
    ][i-1] + ' Cut & Move v2.0.1. @richcrane.'
    alts.append(alt)
subprocess.run(['magick', 'montage', '-font', FONT, *[str(ROOT / f'slide-{i:02d}.jpg') for i in range(1, 7)], '-thumbnail', '360x450', '-tile', '3x2', '-geometry', '+8+8', '-background', NAVY, str(ROOT / 'preview.jpg')], check=True)
(ROOT / 'caption.txt').write_text(CAPTION + '\n')
(ROOT / 'alt-text.json').write_text(json.dumps(alts, indent=2) + '\n')
(ROOT / 'campaign.md').write_text('# Cut & Move v2.0.1 — new-release campaign\n\nSix-slide portrait carousel for Inventing Fire with AI.\n\n## Final slide copy\n\n' + '\n\n'.join(f"### {i}. {s['label']}\n\n" + ' / '.join(s['title']) + '\n\n' + ' '.join(s['body']) + '\n\n' + s['note'] for i, s in enumerate(SLIDES, 1)) + '\n\n## Caption\n\n' + CAPTION + '\n\n## Alt text\n\n' + '\n\n'.join(alts) + '\n\n## Design and limitations\n\nOriginal vector/type composition reuses the preceding campaign’s navy, blue, and orange direction, with light slides for hardware and folder coverage. The typographic Inventing Fire with AI treatment is not an official logo. The actual icon and unaltered About capture are embedded. Diagrams illustrate workflows, not simulated app UI. Every image is a 1080 × 1350 sRGB JPEG. SVGs, renderer, and source assets are editable/reproducible. The title/product/version remain inside a centered square crop. Footer details may be cropped in grid previews. No engagement guarantees; caption URLs are not assumed clickable. Apple-silicon-only distribution is new in 2.0.1; the described Finder extension features arrived in 2.0.0. Publication recorded separately.\n')
