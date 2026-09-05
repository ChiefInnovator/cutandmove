#!/usr/bin/env python3
"""Promote a verified GitHub stable release into the marketing release record."""
import argparse
import json
from pathlib import Path
import re
import subprocess

ROOT = Path(__file__).resolve().parents[1]
REPOSITORY = "ChiefInnovator/cutandmove"
REQUIRED_ASSETS = {"CutAndMove.dmg", "CutAndMove.zip", "SHA256SUMS", "LICENSE"}


def version_tuple(version):
    if not re.fullmatch(r"\d+\.\d+\.\d+", version):
        raise ValueError("Release versions must use major.minor.patch")
    return tuple(map(int, version.split(".")))


def validated_version(release, recorded, source):
    if release.get("draft") is not False or release.get("prerelease") is not False or not release.get("published_at"):
        raise ValueError("Only published stable releases can update downloads")
    tag = release.get("tag_name", "")
    if not tag.startswith("v"):
        raise ValueError("Release tag must start with v")
    version = tag[1:]
    number = version_tuple(version)
    if number < version_tuple(recorded):
        raise ValueError("Refusing to downgrade the published download")
    if number > version_tuple(source):
        raise ValueError("Release is newer than main; push its source before publishing")
    expected = f"https://github.com/{REPOSITORY}/releases"
    if release.get("html_url") != f"{expected}/tag/{tag}":
        raise ValueError("Release belongs to an unexpected repository")
    assets = {asset["name"]: asset for asset in release.get("assets", [])}
    for name in REQUIRED_ASSETS:
        asset = assets.get(name, {})
        if asset.get("state") != "uploaded" or asset.get("size", 0) <= 0:
            raise ValueError(f"Missing or incomplete release asset: {name}")
        if asset.get("browser_download_url") != f"{expected}/download/{tag}/{name}":
            raise ValueError(f"Unexpected asset destination: {name}")
    return version


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("release_json", type=Path)
    args = parser.parse_args()
    config_path = ROOT / "marketing.json"
    config = json.loads(config_path.read_text())
    versions = set(re.findall(r"MARKETING_VERSION = ([^;]+);", (ROOT / "CutAndMove.xcodeproj/project.pbxproj").read_text()))
    if len(versions) != 1:
        raise ValueError("All source versions must agree")
    config["released_version"] = validated_version(json.loads(args.release_json.read_text()), config["released_version"], versions.pop())
    config_path.write_text(json.dumps(config, indent=2) + "\n")
    subprocess.run(["python3", str(ROOT / "scripts/sync-marketing.py")], check=True)


if __name__ == "__main__":
    main()
