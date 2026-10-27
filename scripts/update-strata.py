#!/usr/bin/env python3
"""Update Strata's cask only after verifying the latest stable release download."""
import hashlib
import json
import os
from pathlib import Path
import re
import urllib.request

ROOT = Path(__file__).resolve().parents[1]
REPOSITORY = "cristipufu/strata-files"
API = f"https://api.github.com/repos/{REPOSITORY}/releases/latest"
DOWNLOADS = f"https://github.com/{REPOSITORY}/releases/download"
VERSION = r"(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)"
MAX_DOWNLOAD = 512 * 1024 * 1024


def read(url, limit):
    headers = {"User-Agent": "strata-homebrew-tap"}
    # The repository token is used only for GitHub's API, never for release downloads.
    if url == API and os.environ.get("GH_TOKEN"):
        headers["Authorization"] = "Bearer " + os.environ["GH_TOKEN"]
    with urllib.request.urlopen(urllib.request.Request(url, headers=headers), timeout=60) as response:
        data = response.read(limit + 1)
    if len(data) > limit:
        raise ValueError("Response exceeds its size limit")
    return data


def download_sha256(url):
    digest = hashlib.sha256()
    count = 0
    with urllib.request.urlopen(url, timeout=60) as response:
        while chunk := response.read(1024 * 1024):
            count += len(chunk)
            if count > MAX_DOWNLOAD:
                raise ValueError("DMG exceeds its size limit")
            digest.update(chunk)
    return digest.hexdigest()


def release_version(release):
    tag = release.get("tag_name", "")
    if release.get("draft") is not False or release.get("prerelease") is not False:
        raise ValueError("Only published stable releases are accepted")
    if not re.fullmatch("v" + VERSION, tag):
        raise ValueError("Expected a stable vX.Y.Z release tag")
    return tag[1:]


def asset_url(release, name):
    expected = f"{DOWNLOADS}/{release['tag_name']}/{name}"
    matches = [asset for asset in release.get("assets", []) if asset.get("name") == name]
    if len(matches) != 1 or matches[0].get("browser_download_url") != expected:
        raise ValueError(f"Missing or unexpected release asset: {name}")
    return expected


def dmg_checksum(data):
    matches = []
    for line in data.decode("utf-8").splitlines():
        match = re.fullmatch(r"([0-9a-f]{64}) [ *]Strata\.dmg", line)
        if match:
            matches.append(match[1])
    if len(matches) != 1:
        raise ValueError("Expected exactly one SHA-256 entry for Strata.dmg")
    return matches[0]


def update(path=ROOT / "Casks/strata.rb"):
    release = json.loads(read(API, 1024 * 1024))
    version = release_version(release)
    source = path.read_text()
    versions = re.findall(r'^  version "(' + VERSION + r')"$', source, re.M)
    checksums = re.findall(r'^  sha256 "([0-9a-f]{64})"$', source, re.M)
    if len(versions) != 1 or len(checksums) != 1:
        raise ValueError("Expected one version and one SHA-256 in the cask")
    current = versions[0][0]
    if tuple(map(int, version.split("."))) <= tuple(map(int, current.split("."))):
        print(f"Strata {current} is already current")
        return False
    checksum_url = asset_url(release, "SHA256SUMS.txt")
    dmg_url = asset_url(release, "Strata.dmg")
    checksum = dmg_checksum(read(checksum_url, 64 * 1024))
    if download_sha256(dmg_url) != checksum:
        raise ValueError("DMG SHA-256 does not match SHA256SUMS.txt")
    updated = source.replace(f'  version "{current}"', f'  version "{version}"', 1)
    updated = updated.replace(f'  sha256 "{checksums[0]}"', f'  sha256 "{checksum}"', 1)
    path.write_text(updated)
    print(f"Updated Strata from {current} to {version}")
    return True


if __name__ == "__main__":
    update()
