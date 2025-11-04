# Animal Models

## Current Status
Currently using procedural models (see `scripts/ProceduralAssets.gd`)

## Download Real 3D Models

**Recommended Source:** Poly Pizza - Animated Animal Pack
- URL: https://poly.pizza/bundle/Animated-Animal-Pack-ILAPXeUYiS
- License: CC0 (Public Domain)
- Attribution: Quaternius (quaternius.com)

**Models Needed:**
- `Donkey.fbx` or `Donkey.glb` (main character)
- `Horse.fbx` (variation)
- Any other animals you want to add

**Alternative Sources:**
1. Quaternius Direct: https://quaternius.com/packs/ultimateanimatedanimals.html
2. Sketchfab (search "donkey CC0")
3. Poly Pizza individual models

## Integration Instructions

1. Download the model files (FBX or GLTF format)
2. Place them in this directory
3. In Godot Editor:
   - Open `scenes/Main.tscn`
   - Select the "DonkeyPlayer" node
   - Replace "DonkeyMesh" with your downloaded model
4. Re-export: `cd godot && ./export_game.sh android`

## License
All assets in this directory should be CC0 or properly attributed CC-BY.
See `/CREDITS.md` for full attribution.
