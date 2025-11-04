# Donkey GTA - Credits & Attribution

## Game Development

**Programming & Design**
- Game Engine: Godot Engine 4.2 (godotengine.org)
- Mobile Framework: React Native + react-native-godot

## Assets

### 3D Models

#### Current Implementation
All 3D models are currently procedurally generated using GDScript.
See `godot/scripts/ProceduralAssets.gd` for implementation.

#### Recommended Free Assets (Not Yet Included)

**Animals:**
- Animated Animal Pack by Quaternius (quaternius.com)
- License: CC0 1.0 Universal (Public Domain)
- Source: https://poly.pizza/bundle/Animated-Animal-Pack-ILAPXeUYiS

**City Buildings:**
- City Kit (Commercial) by Kenney (kenney.nl)
- License: CC0 1.0 Universal (Public Domain)
- Source: https://kenney.nl/assets/city-kit-commercial

**Characters:**
- Mixamo Characters (requires Adobe account)
- License: Royalty-free for game use
- Source: https://www.mixamo.com/

### Audio

#### Music
Music assets not yet included. Recommended sources:

**Kevin MacLeod - Incompetech**
When using Kevin MacLeod's music, attribution is REQUIRED:
```
"[Track Name]" by Kevin MacLeod (incompetech.com)
Licensed under Creative Commons: By Attribution 4.0 License
http://creativecommons.org/licenses/by/4.0/
```

Recommended tracks:
- "Cipher" - Main gameplay theme
- "Funky Chunk" - Action sequences
- "Fluffing a Duck" - Comedy moments

#### Sound Effects
SFX assets not yet included. Recommended source:

**Freesound.org**
- Various CC0 and CC-BY sounds
- Attribution required for CC-BY sounds
- See `godot/assets/audio/sfx/README.md` for details

## Libraries & Dependencies

### React Native
```
React Native - MIT License
Copyright (c) Meta Platforms, Inc. and affiliates.
```

### React Native Godot
```
react-native-godot - MIT License
Copyright (c) Born/Migeran
```

### Godot Engine
```
Godot Engine - MIT License
Copyright (c) 2014-present Godot Engine contributors
Copyright (c) 2007-2014 Juan Linietsky, Ariel Manzur
```

## Fonts
Default system fonts used. No custom fonts included.

## License Compliance

This project uses or recommends assets with the following licenses:

### CC0 1.0 Universal (Public Domain)
Assets can be used freely without attribution for any purpose including commercial use.

Recommended CC0 assets:
- Kenney assets (kenney.nl)
- Quaternius assets (quaternius.com)
- Some Freesound.org sounds

### CC-BY 4.0 (Creative Commons Attribution)
Assets can be used freely including commercially, but attribution is REQUIRED.

Assets requiring attribution:
- Kevin MacLeod music from Incompetech
- Some Freesound.org sounds (check individual licenses)

### MIT License
Software components are MIT licensed. See individual dependencies for details.

## How to Add Your Downloaded Assets

When you download and integrate real assets:

1. **For CC0 Assets:**
   - Optional but appreciated: Add to this file
   - Format: `Asset Name by Creator (website) - CC0 License`

2. **For CC-BY Assets:**
   - REQUIRED: Add detailed attribution to this file
   - Include: Asset name, creator, source URL, license type
   - Format provided in asset README files

3. **In-Game Credits:**
   - Add a "Credits" screen in the game UI
   - List all CC-BY attributed assets
   - Recommended for CC0 assets as well

## Asset Integration Checklist

Before publishing your game:

- [ ] Verify all asset licenses
- [ ] Add required attributions to CREDITS.md
- [ ] Create in-game credits screen
- [ ] Double-check CC-BY attribution formatting
- [ ] Ensure music attribution is visible
- [ ] Review all Freesound.org sounds for license compliance
- [ ] Keep copies of license files
- [ ] Document any custom assets you create

## Support the Creators

While CC0 assets don't require attribution or payment, consider:

- ☕ **Kenney**: Support via Patreon or donations (kenney.nl)
- ☕ **Quaternius**: Support via Patreon (patreon.com/quaternius)
- 💰 **Kevin MacLeod**: Buy a license if you want to skip attribution (~$30)
- 💰 **Freesound**: Donate to support the platform

## Contact

For questions about asset licensing in this project:
- Check individual asset README files
- Review original source websites
- Contact asset creators directly for commercial licensing questions

---

**Last Updated:** 2025-11-04

**Note:** This file will be updated as assets are downloaded and integrated.
Currently using 100% procedural placeholder assets.
