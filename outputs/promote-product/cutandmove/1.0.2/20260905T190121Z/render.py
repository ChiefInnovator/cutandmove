"""Editable vector campaign layout; requires ImageMagick and macOS Arial fonts."""
from pathlib import Path
import html
import json
import subprocess
import base64

ROOT = Path(__file__).resolve().parent
ICON = base64.b64encode((ROOT.parents[4]/'CutAndMove/Assets.xcassets/AppIcon.appiconset/512.png').read_bytes()).decode()
SLIDES = [
    dict(label="NEW RELEASE", title=["Cut & Move", "v1.0.2"], body=["Your fingers know Cmd+X.", "Now Finder does too."], key="Cmd+X  →  Cmd+V", note="Familiar file moves. Sharper Finder safeguards."),
    dict(label="THE EVERYDAY WORKFLOW", title=["Cut. Paste.", "Keep moving."], body=["Select files in Finder. Press Cmd+X.", "Open the destination. Press Cmd+V."], key="SELECT  →  CUT  →  MOVE", note="Finder handles the move and any file conflicts."),
    dict(label="NEW IN v1.0.2", title=["Rename a file.", "Not your habits."], body=["Finder search and rename fields", "keep their native text editing."], key="TEXT STAYS TEXT", note="Unknown or inaccessible controls stay unchanged."),
    dict(label="NEW IN v1.0.2", title=["Fresh copy.", "Then move."], body=["Paste becomes a move only after", "a fresh file copy. Switch apps", "and pending cut mode clears."], key="FINDER-FOCUSED", note="Stale or replaced clipboards do not become moves."),
    dict(label="NEW IN v1.0.2", title=["Full icon.", "No inset border."], body=["Updated artwork at every icon size.", "A small menu bar utility", "with no analytics or network requests."], key="NATIVE SWIFT", note="macOS may apply its own icon mask."),
    dict(label="GET Cut & Move v1.0.2", title=["Less remembering.", "More moving."], body=["Download the signed, notarized DMG.", "Drag to Applications. Open the app.", "Grant Accessibility access."], key="chiefinnovator.github.io/cutandmove/", note="Download v1.0.2 and follow the setup guide."),
]
CAPTION = """Your fingers know Cmd+X. Now Finder does too. ✂️

Cut & Move v1.0.2 is out: familiar Cmd+X → Cmd+V file moves in a native Mac menu bar app.

This release adds Finder search and rename protections, fresh-clipboard checks, cut-mode cancellation when switching apps, and a full-bleed icon without the old inset border.

Finder still handles the actual move and file-conflict dialogs. No keystroke recording, analytics, or app network requests.

Download v1.0.2 and see setup details:
https://chiefinnovator.github.io/cutandmove/
(Type or copy the URL into your browser.)

Requires macOS 26.1+ and Accessibility permission. Apple silicon and Intel. Developer ID signed and Apple notarized; no Mac App Store version. Free for uses permitted by PolyForm Strict 1.0.0.

Built by @richcrane. Share this with a Mac user whose fingers still reach for Cmd+X.

#MacProductivity #macOS #Finder #CutAndMove #InventingFireWithAI"""

def text(lines, x, y, size, color="#f5f5f8", weight="normal", step=None):
    return ''.join(f'<text x="{x}" y="{y+i*(step or size*1.2)}" font-size="{size}" font-weight="{weight}" fill="{color}">{html.escape(line)}</text>' for i,line in enumerate(lines))

alts=[]
for i,s in enumerate(SLIDES,1):
    # Every line is explicit so the source and exported copy are identical.
    design = f'''<svg xmlns="http://www.w3.org/2000/svg" width="1080" height="1350" viewBox="0 0 1080 1350">
<defs><linearGradient id="bg" x2="1" y2="1"><stop stop-color="#090d18"/><stop offset="1" stop-color="#172442"/></linearGradient></defs>
<rect width="1080" height="1350" fill="#090d18"/>
<path d="M760 0 L1080 0 L1080 470" fill="#263f69"/>
<rect x="76" y="85" width="48" height="6" fill="#ff9a57"/>
<g font-family="Arial">
{text(['INVENTING FIRE WITH AI'],76,135,26,'#d7dfef','bold')}
{text([s['label']],76,245,25,'#ffad75','bold')}
{text(s['title'],76,370,78 if i!=6 else 70,weight='bold',step=92)}
{text(s['body'],76,640,35,'#d7dfef',step=51)}
<rect x="76" y="867" width="928" height="166" rx="24" fill="#263f69"/>
{text([s['key']],110,960,36 if i==6 else 44,weight='bold')}
{f'<image x="760" y="840" width="200" height="200" href="data:image/png;base64,{ICON}"/>' if i==5 else ''}
{text([s['note']],76,1102,32 if i==6 else 27,'#d7dfef')}
{text(['macOS 26.1+  ·  Accessibility access required'] if i==6 else ['Cut & Move v1.0.2'],76,1190,25,'#d7dfef')}
<path d="M76 1230 H1004" stroke="#40516a"/>
{text(['@richcrane'],76,1280,24,'#ffad75')}
{text([f'{i:02d} / 06'],904,1280,24,'#d7dfef')}
</g></svg>'''
    svg=ROOT/f'slide-{i:02d}.svg'
    svg.write_text(design)
    subprocess.run(['magick','-font','/System/Library/Fonts/Supplemental/Arial.ttf',str(svg),'-colorspace','sRGB','-strip','-quality','94',str(svg.with_suffix('.jpg'))],check=True)
    alts.append(f"Slide {i} of 6. Navy background, blue panel, orange accents. Inventing Fire with AI. " + ' '.join([s['label'],*s['title'],*s['body'],s['key'],s['note']]) + (' The actual app icon shows black scissors and a smiling white face with a blue corner.' if i==5 else '') + ' Cut & Move v1.0.2. @richcrane.')
subprocess.run(['magick','montage','-font','/System/Library/Fonts/Supplemental/Arial.ttf',*[str(ROOT/f'slide-{i:02d}.jpg') for i in range(1,7)],'-thumbnail','360x450','-tile','3x2','-geometry','+8+8','-background','#090d18',str(ROOT/'preview.jpg')],check=True)
(ROOT/'caption.txt').write_text(CAPTION+'\n')
(ROOT/'alt-text.json').write_text(json.dumps(alts,indent=2)+'\n')
(ROOT/'campaign.md').write_text('# Cut & Move v1.0.2 — new-release campaign\n\nSix-slide carousel for Inventing Fire with AI.\n\n## Final slide copy\n\n'+ '\n\n'.join(f"### {i}. {s['label']}\n\n"+' / '.join(s['title'])+'\n\n'+' '.join(s['body'])+'\n\n'+s['key']+' — '+s['note'] for i,s in enumerate(SLIDES,1))+'\n\n## Caption\n\n'+CAPTION+'\n\n## Alt text\n\n'+'\n\n'.join(alts)+'\n\n## Design and limitations\n\nOriginal typographic/vector composition; wordmark is a campaign treatment, not an official logo. No simulated product UI. Navy and blue borrow from the marketing page; warm orange identifies Inventing Fire with AI. Every slide is 1080 × 1350 JPEG. Editable SVGs and this renderer are included. Caption URLs are not assumed clickable. No reach or performance guarantees. Publication is recorded separately.\n')
