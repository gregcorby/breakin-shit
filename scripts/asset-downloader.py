#!/usr/bin/env python3
"""
Asset Downloader - Downloads free game assets using various methods
"""
import os
import sys
import urllib.request
import urllib.error
import json
from pathlib import Path

# Asset sources with direct download methods
ASSETS = {
    "music": [
        {
            "name": "Cipher by Kevin MacLeod",
            "url": "https://archive.org/download/Kevin-MacLeod_Royalty-Free_2017_FullAlbum/Kevin%20MacLeod%20-%20Cipher.mp3",
            "dest": "godot/assets/audio/music/cipher.mp3"
        },
        {
            "name": "Funky Chunk by Kevin MacLeod",
            "url": "https://archive.org/download/Kevin-MacLeod_Royalty-Free_2017_FullAlbum/Kevin%20MacLeod%20-%20Funky%20Chunk.mp3",
            "dest": "godot/assets/audio/music/funky_chunk.mp3"
        }
    ],
    "models_github": [
        {
            "name": "Kenney City Kit from GitHub",
            "repo": "https://github.com/ETdoFresh/kenney.nl.git",
            "path": "Kenney.nl/cityKit(Commercial)",
            "dest": "godot/assets/models/city/kenney"
        }
    ]
}

def download_file(url, dest):
    """Download a file with proper headers"""
    print(f"Downloading: {url}")
    print(f"To: {dest}")

    # Create directory if needed
    os.makedirs(os.path.dirname(dest), exist_ok=True)

    # Setup request with headers
    headers = {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
        'Accept': '*/*'
    }

    request = urllib.request.Request(url, headers=headers)

    try:
        with urllib.request.urlopen(request, timeout=30) as response:
            data = response.read()

            # Check if we got actual data (not just "Access denied")
            if len(data) < 1000 and b"Access denied" in data:
                print(f"✗ Access denied: {url}")
                return False

            with open(dest, 'wb') as f:
                f.write(data)

            print(f"✓ Downloaded: {os.path.basename(dest)} ({len(data)} bytes)")
            return True

    except Exception as e:
        print(f"✗ Error downloading {url}: {e}")
        return False

def main():
    print("🎨 Downloading Free Game Assets\n")

    base_dir = "/home/user/breakin-shit"
    os.chdir(base_dir)

    success_count = 0
    fail_count = 0

    # Download music files
    print("🎵 Downloading Music...")
    for asset in ASSETS["music"]:
        if download_file(asset["url"], asset["dest"]):
            success_count += 1
        else:
            fail_count += 1
        print()

    print(f"\n📊 Results: {success_count} successful, {fail_count} failed")

    if success_count > 0:
        print("\n✅ Some assets downloaded successfully!")
        print("Run the game to hear the music!")

    if fail_count > 0:
        print("\n⚠️  Some downloads failed due to access restrictions")
        print("Trying alternative sources...")

if __name__ == "__main__":
    main()
