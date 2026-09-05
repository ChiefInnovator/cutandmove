#!/usr/bin/env python3
"""Offline regression coverage for automatic release promotion."""
import copy
import importlib.util
import json
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

spec = importlib.util.spec_from_file_location("release_sync", Path(__file__).with_name("sync-release.py"))
sync = importlib.util.module_from_spec(spec)
spec.loader.exec_module(sync)


class ReleaseSyncTests(unittest.TestCase):
    def release(self, version="1.0.3"):
        base = f"https://github.com/{sync.REPOSITORY}/releases"
        return dict(tag_name="v" + version, html_url=f"{base}/tag/v{version}", draft=False, prerelease=False,
                    published_at="2026-09-05T20:00:00Z", assets=[dict(name=name, state="uploaded", size=100,
                    browser_download_url=f"{base}/download/v{version}/{name}") for name in sync.REQUIRED_ASSETS])

    def test_promotion_and_repeat_are_safe(self):
        for recorded in ["1.0.2", "1.0.3"]:
            self.assertEqual(sync.validated_version(self.release(), recorded, "1.0.3"), "1.0.3")

    def test_invalid_releases_are_rejected(self):
        for changes in [dict(draft=True), dict(prerelease=True), dict(published_at=None),
                        dict(tag_name="v1.0"), dict(tag_name="v1.0.3;echo bad"),
                        dict(html_url="https://example.com/release"), dict(assets=[])]:
            with self.subTest(changes=changes), self.assertRaises(ValueError):
                sync.validated_version(self.release() | changes, "1.0.2", "1.0.3")

    def test_incomplete_or_wrong_assets_are_rejected(self):
        for changes in [dict(state="new"), dict(size=0), dict(browser_download_url="https://example.com/a.dmg")]:
            release = copy.deepcopy(self.release())
            release["assets"][0].update(changes)
            with self.subTest(changes=changes), self.assertRaises(ValueError):
                sync.validated_version(release, "1.0.2", "1.0.3")

    def test_no_downgrade_or_unpushed_source(self):
        for recorded, source in [("1.0.4", "1.0.4"), ("1.0.2", "1.0.2")]:
            with self.assertRaises(ValueError):
                sync.validated_version(self.release(), recorded, source)

    def test_versions_compare_numerically(self):
        self.assertEqual(sync.validated_version(self.release("1.0.10"), "1.0.9", "1.0.10"), "1.0.10")

    def test_release_updates_page_readme_and_metadata_idempotently(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            for name in ["marketing.json", "index.html", "README.md", "llms.txt", "CutAndMove.xcodeproj/project.pbxproj",
                         "scripts/sync-release.py", "scripts/sync-marketing.py"]:
                target = root / name
                target.parent.mkdir(parents=True, exist_ok=True)
                shutil.copy2(sync.ROOT / name, target)
            # A fixture release uses the checkout's source version, not a hardcoded future version.
            import re
            source = re.search(r"MARKETING_VERSION = ([^;]+);", (root / "CutAndMove.xcodeproj/project.pbxproj").read_text())[1]
            release = root / "release.json"
            release.write_text(json.dumps(self.release(source)))
            command = ["python3", str(root / "scripts/sync-release.py"), str(release)]
            subprocess.run(command, check=True, capture_output=True)
            page = (root / "index.html").read_text()
            self.assertIn(f'/releases/download/v{source}/CutAndMove.dmg', page)
            self.assertIn(f'"softwareVersion": "{source}"', page)
            for name in ["index.html", "README.md", "llms.txt"]:
                self.assertIn(f'Published download: v{source}', (root / name).read_text())
            before = {name: (root / name).read_bytes() for name in ["marketing.json", "index.html", "README.md", "llms.txt"]}
            subprocess.run(command, check=True, capture_output=True)
            self.assertEqual(before, {name: (root / name).read_bytes() for name in before})


if __name__ == "__main__":
    unittest.main()
