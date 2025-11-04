# Sound Effects

## Current Status
No SFX files included - audio system ready in `scripts/AudioManager.gd`

## Download Free Sound Effects

**Recommended Source:** Freesound.org
- URL: https://freesound.org/
- License: CC0 or CC-BY (check each sound)
- Create free account to download

**Sound Effects Needed:**

### High Priority
- **Kick Impact** (3-5 variations)
  - Search: "kick impact", "punch hit", "body hit"
  - Use for player kick attacks

- **Footsteps** (4-6 variations)
  - Search: "footstep concrete", "walk stone"
  - Use for player and NPC walking

- **Donkey Sounds** (2-3 variations)
  - Search: "donkey bray", "donkey sound"
  - Use for player character

### Medium Priority
- **Score/Combo**
  - Search: "ding", "coin", "point score"
  - Use when kicking NPCs

- **Crowd Ambience**
  - Search: "city ambience", "crowd murmur"
  - Loop in background

### Low Priority
- **UI Sounds**
  - Button clicks
  - Menu navigation
  - Pause/resume

## Alternative Sources

- **Kenney Audio**: https://kenney.nl/assets?q=audio
- **Pixabay Sound Effects**: https://pixabay.com/sound-effects/
- **OpenGameArt**: https://opengameart.org/art-search-advanced?keys=&field_art_type_tid%5B%5D=13

## Integration Instructions

1. Download WAV or OGG files
2. Rename descriptively: `kick_01.ogg`, `footstep_concrete_01.ogg`
3. Place in this directory
4. Update `scripts/AudioManager.gd`:
   - Update `sound_effects` dictionary with actual file paths
5. Sounds will automatically play when triggered

## License Compliance

- **CC0**: No attribution needed, use freely
- **CC-BY**: Attribution required - add to CREDITS.md

Format for Freesound attribution:
```
"[Sound Name]" by [Username] (freesound.org/people/[username]/sounds/[id]/)
Licensed under Creative Commons [License Type]
```

## File Format Recommendations

- **Format**: OGG Vorbis (best compression for games)
- **Sample Rate**: 44.1 kHz
- **Bit Depth**: 16-bit
- **Channels**: Mono for SFX (smaller file size)

Convert WAV to OGG:
```bash
ffmpeg -i input.wav -c:a libvorbis -q:a 4 output.ogg
```
