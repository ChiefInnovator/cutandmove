#!/usr/bin/env python3
"""Offline checks for metadata, FAQ parity, and full-version synchronization."""
import importlib.util
import json
import re
import shutil
import tempfile
import unittest
from html import unescape
from pathlib import Path
from urllib.parse import parse_qs, urlsplit

spec = importlib.util.spec_from_file_location("marketing", Path(__file__).with_name("sync-marketing.py"))
marketing = importlib.util.module_from_spec(spec)
spec.loader.exec_module(marketing)


class MarketingTests(unittest.TestCase):
    def test_hardware_requirements_follow_published_release(self):
        original = marketing.ROOT
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            for name in ["index.html", "README.md", "llms.txt", "marketing.json", "CutAndMove.xcodeproj/project.pbxproj"]:
                target = root / name
                target.parent.mkdir(parents=True, exist_ok=True)
                shutil.copy2(original / name, target)
            config_path = root / "marketing.json"
            config = json.loads(config_path.read_text())
            try:
                marketing.ROOT = root
                for version, expected in [("2.0.0", "Apple silicon and Intel"), ("2.0.1", "Apple silicon only (M1 or later)")]:
                    config["released_version"] = version
                    config_path.write_text(json.dumps(config))
                    for name, text in marketing.outputs().items():
                        self.assertIn(expected, text, name)
                        if name == "index.html":
                            for block in ["hero-requirements", "download-requirements"]:
                                visible = re.search(rf'<!-- {block}:start -->(.*?)<!-- {block}:end -->', text, re.S)[1]
                                self.assertIn(expected, visible, block)
                        if version == "2.0.1":
                            self.assertNotIn("Intel", text, name)
            finally:
                marketing.ROOT = original

    def test_sharing_and_direct_download_use_published_version(self):
        page = marketing.outputs()["index.html"]
        config = json.loads((marketing.ROOT / "marketing.json").read_text())
        version = config["released_version"]
        self.assertEqual(page.count(f'/releases/download/v{version}/CutAndMove.dmg'), 2)
        share = re.search(r'<!-- share:start -->(.*?)<!-- share:end -->', page, re.S)[1]
        links = [unescape(url) for url in re.findall(r'href="([^"]+)"', share)]
        tweet = parse_qs(urlsplit(next(url for url in links if 'twitter.com/' in url)).query)
        self.assertIn('Cut & Move v' + version, tweet['text'][0])
        self.assertIn('Cmd+X', tweet['text'][0])
        self.assertEqual(tweet['url'], [config['site_url']])
        email = next(url for url in links if url.startswith('mailto:'))
        self.assertIn('%20', email)
        self.assertNotIn('+', email)
        self.assertIn('id="copy-share" hidden', share)
        self.assertIn('Select the message above to copy it, or use a sharing link.', share)

    def test_metadata_and_visible_faq_match(self):
        page = marketing.outputs()["index.html"]
        graph = json.loads(re.search(r'<script type="application/ld\+json">(.*?)</script>', page, re.S)[1])["@graph"]
        faq = next(item for item in graph if item["@type"] == "FAQPage")
        visible = re.findall(r'<details class="faq-item"><summary>(.*?)</summary><p class="faq-item-body">(.*?)</p></details>', page)
        self.assertEqual([(unescape(q), unescape(a)) for q, a in visible], [(q["name"], q["acceptedAnswer"]["text"]) for q in faq["mainEntity"]])
        self.assertEqual(page.count('<link rel="canonical"'), 1)
        self.assertEqual(page.count('<h1>'), 1)
        self.assertNotIn("raw.githubusercontent.com", page)
        self.assertNotIn("InStock", page)
        self.assertNotIn('href="/llms.txt"', page)
        released = json.loads((marketing.ROOT / "marketing.json").read_text())["released_version"]
        current = re.search(r"MARKETING_VERSION = ([^;]+);", (marketing.ROOT / "CutAndMove.xcodeproj/project.pbxproj").read_text())[1]
        expected = f'The published v{released} release includes' if current == released else f'The v{current} development preview adds'
        self.assertIn(expected + ' a Finder Sync extension', page)
        self.assertNotIn('These features require the current source version', page)

    def test_version_bump_updates_all_surfaces_without_changing_download(self):
        original = marketing.ROOT
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            for name in ["index.html", "README.md", "llms.txt", "marketing.json", "CutAndMove.xcodeproj/project.pbxproj"]:
                target = root / name
                target.parent.mkdir(parents=True, exist_ok=True)
                shutil.copy2(original / name, target)
            project = root / "CutAndMove.xcodeproj/project.pbxproj"
            released = json.loads((root / "marketing.json").read_text())["released_version"]
            current = re.search(r"MARKETING_VERSION = ([^;]+);", project.read_text())[1]
            preview = f"{max(int(current.split('.')[0]), int(released.split('.')[0])) + 1}.0.0"
            project.write_text(re.sub(r"MARKETING_VERSION = [^;]+;", f"MARKETING_VERSION = {preview};", project.read_text()))
            try:
                marketing.ROOT = root
                output = marketing.outputs()
                self.assertIn(f'The v{preview} development preview adds', output["index.html"])
                self.assertIn('not a guarantee about the published download', output["index.html"])
                for name, text in output.items():
                    self.assertIn("v" + preview, text, name)
                    self.assertIn("v" + released, text, name)
                    (root / name).write_text(text)
                self.assertEqual(marketing.outputs(), output)
                project.write_text(re.sub(r"MARKETING_VERSION = [^;]+;", f"MARKETING_VERSION = {released};", project.read_text()))
                published = marketing.outputs()["index.html"]
                self.assertIn(f'The published v{released} release includes', published)
                self.assertNotIn('not a guarantee about the published download', published)
                project.write_text(re.sub(r"MARKETING_VERSION = [^;]+;", "MARKETING_VERSION = 2.3;", project.read_text()))
                with self.assertRaises(ValueError):
                    marketing.outputs()
            finally:
                marketing.ROOT = original


if __name__ == "__main__":
    unittest.main()
