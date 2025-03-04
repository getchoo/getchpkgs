#!/usr/bin/env nix-shell
#! nix-shell --pure -i python3 -p nix python3 python3Packages.requests
import json
import requests
import subprocess
from pathlib import Path

GITHUB_API = "https://api.github.com"
ARKENFOX_REPO = "arkenfox/user.js"
HASHES_FILE = Path("arkenfox-hashes.json")


def get_tags():
    r = requests.get(
        f"{GITHUB_API}/repos/{ARKENFOX_REPO}/releases",
        headers={
            "Accept": "application/vnd.github+json",
            "X-GitHub-Api-Version": "2022-11-28",
        },
    )
    r.raise_for_status()
    releases = r.json()
    return [release["tag_name"] for release in releases]


def get_hash_for_tag(tag: str):
    print(f"❓️ Calculating hash of Arkenfox v{tag}")
    process = subprocess.run(
        [
            "nix",
            "--experimental-features",
            "nix-command flakes",
            "store",
            "prefetch-file",
            "--unpack",
            "--json",
            f"https://github.com/{ARKENFOX_REPO}/archive/refs/tags/{tag}.tar.gz",
        ],
        check=True,
        capture_output=True,
        text=True,
    )
    output = json.loads(process.stdout)
    return output["hash"]


tracked_tags = {}
if HASHES_FILE.exists():
    with open(HASHES_FILE, "r") as f:
        tracked_tags = json.load(f)

upstream_tags = get_tags()
tags_to_update = [tag for tag in upstream_tags if tag not in tracked_tags.keys()]
old_tracked = tracked_tags.copy()

update_len = len(tags_to_update)
if update_len < 1:
    print("😐️ No updates found")
    exit()

print(f"🏃 Updating with {update_len} tag(s)")
for tag in tags_to_update:
    tracked_tags[tag] = get_hash_for_tag(tag)

if tracked_tags != old_tracked:
    with open(HASHES_FILE, "w") as f:
        json.dump(tracked_tags, f, indent=2, sort_keys=True)

print("👍️ Done!")
