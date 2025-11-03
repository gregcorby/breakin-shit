# 🎨 Asset Integration Guide for Donkey GTA

This guide will help you upgrade the game from placeholder graphics to premium-quality 3D assets and audio.

## 📦 Quick Asset Setup

### Step 1: Download Recommended Asset Packs

#### For the Donkey (Main Character)
1. Visit [Quaternius - Ultimate Animals Pack](https://quaternius.com/packs/ultimateanimals.html)
2. Download the pack (FREE)
3. Extract and locate the "Donkey.fbx" or similar model
4. Alternatively, search for "donkey" on [Poly Pizza](https://poly.pizza/)

#### For City Buildings
1. Visit [Kenney - City Kit](https://kenney.nl/assets/city-kit-commercial)
2. Download the pack (FREE)
3. Extract to access building models
4. Alternatively, use [Quaternius Ultimate Modular City](https://quaternius.com/)

#### For NPCs/Pedestrians
1. Visit [Mixamo](https://www.mixamo.com/)
2. Create a free account (requires Adobe ID)
3. Download 3-5 different character models
4. Download with "T-Pose" and animations (walk, idle, hit reaction)

#### For Music
1. Visit [Incompetech](https://incompetech.com/music/royalty-free/music.html)
2. Search for and download these tracks:
   - "Cipher" (main theme)
   - "Funky Chunk" (high energy)
   - "Fluffing a Duck" (comedy)
3. Download in OGG format for best compatibility

#### For Sound Effects
1. Visit [Freesound.org](https://freesound.org/)
2. Search and download:
   - "kick impact" → multiple variations
   - "donkey bray" → 2-3 variations
   - "footstep concrete" → 4-5 variations
   - "crowd ambient city" → 1-2 loops
   - "score ding" → combo notifications

### Step 2: Organize Assets

Create the following folder structure:

```
godot/assets/
├── models/
│   ├── animals/
│   │   ├── donkey.fbx
│   │   └── donkey_animations.fbx
│   ├── characters/
│   │   ├── pedestrian_01.fbx
│   │   ├── pedestrian_02.fbx
│   │   ├── pedestrian_03.fbx
│   │   └── animations/
│   │       ├── walk.fbx
│   │       ├── idle.fbx
│   │       └── hit.fbx
│   └── city/
│       ├── buildings/
│       │   ├── building_01.fbx
│       │   ├── building_02.fbx
│       │   └── ...
│       └── props/
│           ├── lamppost.fbx
│           ├── bench.fbx
│           └── ...
├── textures/
│   ├── donkey_albedo.png
│   ├── building_atlas.png
│   └── ...
└── audio/
    ├── music/
    │   ├── city_theme_1.ogg
    │   ├── city_theme_2.ogg
    │   └── action_theme.ogg
    └── sfx/
        ├── kick.ogg
        ├── hit.ogg
        ├── donkey_bray.ogg
        ├── footstep_01.ogg
        └── score.ogg
```

### Step 3: Import Assets into Godot

1. **Open Godot Editor**
   ```bash
   cd godot
   godot project.godot
   ```

2. **Import 3D Models**
   - Drag FBX files into the FileSystem panel
   - Godot will auto-import them
   - For each model, check import settings:
     - Enable "Generate Collisions" for buildings
     - Enable "Create Animation Player" for animated models
     - Set scale if needed (some models may need 0.01 scale)

3. **Configure Materials**
   - Select imported model
   - In Inspector → Material, create StandardMaterial3D
   - Assign textures to appropriate channels:
     - Albedo → base color texture
     - Normal → normal map
     - Metallic → metallic map
     - Roughness → roughness map

4. **Import Audio**
   - Drag audio files into `assets/audio/`
   - Godot supports: OGG, WAV, MP3
   - For music: Use OGG for better compression
   - For SFX: Use WAV for no-latency playback

### Step 4: Update Game Scripts

#### Replace Donkey Placeholder

Edit `godot/scenes/Main.tscn`:

1. Open scene in Godot Editor
2. Select "DonkeyPlayer" node
3. Delete the "DonkeyMesh" child (placeholder)
4. Drag your imported donkey model onto DonkeyPlayer
5. Rename to "DonkeyMesh"
6. Adjust position/rotation if needed

Or manually edit `Main.tscn`:

```gdscript
[node name="DonkeyMesh" parent="DonkeyPlayer" instance=ExtResource("path_to_donkey_model")]
```

#### Update NPC Models

Edit `godot/scripts/NPCSpawner.gd`:

Replace the `create_npc_instance()` function:

```gdscript
func create_npc_instance() -> Node3D:
    """Create an NPC with proper 3D model"""
    var npc = CharacterBody3D.new()

    # Add the NPC script
    var script = load("res://scripts/NPCPedestrian.gd")
    if script:
        npc.set_script(script)

    # Load random pedestrian model
    var pedestrian_models = [
        "res://assets/models/characters/pedestrian_01.fbx",
        "res://assets/models/characters/pedestrian_02.fbx",
        "res://assets/models/characters/pedestrian_03.fbx",
    ]

    var random_model = load(pedestrian_models[randi() % pedestrian_models.size()])
    var model_instance = random_model.instantiate()
    model_instance.name = "Mesh"
    npc.add_child(model_instance)

    # ... rest of the function stays the same
```

#### Update City Buildings

Edit `godot/scripts/CityGenerator.gd`:

Replace the `generate_building()` function to use real models:

```gdscript
func generate_building(position: Vector3) -> void:
    """Generate a building using real 3D models"""
    var building = StaticBody3D.new()
    building.position = position
    building.collision_layer = 8

    # Load random building model
    var building_models = [
        "res://assets/models/city/buildings/building_01.fbx",
        "res://assets/models/city/buildings/building_02.fbx",
        "res://assets/models/city/buildings/building_03.fbx",
    ]

    var random_model = load(building_models[randi() % building_models.size()])
    var model_instance = random_model.instantiate()

    # Random rotation for variety
    model_instance.rotation_degrees.y = [0, 90, 180, 270][randi() % 4]

    building.add_child(model_instance)

    # Add collision (assuming model has collision shapes)
    buildings_parent.add_child(building)
```

#### Add Audio Files

Edit `godot/scripts/AudioManager.gd`:

Update the arrays at the top:

```gdscript
var music_tracks: Array[String] = [
    "res://assets/audio/music/city_theme_1.ogg",
    "res://assets/audio/music/city_theme_2.ogg",
    "res://assets/audio/music/action_theme.ogg"
]

var sound_effects: Dictionary = {
    "kick": "res://assets/audio/sfx/kick.ogg",
    "hit": "res://assets/audio/sfx/hit.ogg",
    "footstep": "res://assets/audio/sfx/footstep_01.ogg",
    "donkey_bray": "res://assets/audio/sfx/donkey_bray.ogg",
    "score": "res://assets/audio/sfx/score.ogg",
    "combo": "res://assets/audio/sfx/combo.ogg"
}
```

Update the `play_sound()` function:

```gdscript
func play_sound(sound_name: String, position: Vector3 = Vector3.ZERO) -> void:
    """Play a sound effect"""
    if not sound_effects.has(sound_name):
        print("Sound effect not found: ", sound_name)
        return

    var sound_file = sound_effects[sound_name]
    var audio_stream = load(sound_file)

    if position != Vector3.ZERO:
        var audio_player = AudioStreamPlayer3D.new()
        get_tree().root.add_child(audio_player)
        audio_player.global_position = position
        audio_player.stream = audio_stream
        audio_player.volume_db = linear_to_db(sfx_volume)
        audio_player.max_distance = 50.0
        audio_player.play()
        audio_player.finished.connect(func(): audio_player.queue_free())
    else:
        sfx_player.stream = audio_stream
        sfx_player.volume_db = linear_to_db(sfx_volume)
        sfx_player.play()
```

### Step 5: Test Asset Integration

1. **Open Godot Editor**
   ```bash
   cd godot
   godot project.godot
   ```

2. **Run Scene**
   - Press F5 or click "Run Project"
   - Verify all models load correctly
   - Check that audio plays

3. **Export Game**
   ```bash
   ./export_game.sh all
   ```

4. **Test in React Native**
   ```bash
   cd ..
   npm run android  # or npm run ios
   ```

## 🎯 Asset Quality Checklist

### 3D Models
- [ ] Donkey model is properly rigged and animated
- [ ] At least 3 different NPC models for variety
- [ ] 5-10 different building models
- [ ] All models have appropriate scale (not too big/small)
- [ ] Models have optimized poly count (< 5000 triangles for NPCs)
- [ ] Collision shapes are set up correctly

### Textures
- [ ] All textures are power-of-2 resolution (512x512, 1024x1024, etc.)
- [ ] Textures use appropriate compression (VRAM compressed on mobile)
- [ ] Normal maps are included for added detail
- [ ] Material properties (metallic, roughness) are configured

### Audio
- [ ] Music tracks are in OGG format
- [ ] Music is properly looped
- [ ] Sound effects are normalized to similar volume levels
- [ ] Multiple variations for frequently played sounds (footsteps)
- [ ] Audio files are optimized (not unnecessarily high quality)

### Performance
- [ ] Game maintains 60 FPS with all assets loaded
- [ ] Memory usage is under 500MB on mobile
- [ ] Asset loading doesn't cause stutters
- [ ] LOD (Level of Detail) is set up for distant buildings

## 📋 Licensing & Attribution

Create a file `CREDITS.md` with all asset attributions:

```markdown
# Asset Credits

## 3D Models
- Donkey Model: [Source] by [Creator] - [License]
- Character Models: Mixamo by Adobe - [License]
- City Buildings: Kenney - CC0 License

## Audio
### Music
- "Cipher" by Kevin MacLeod (incompetech.com)
  Licensed under Creative Commons: By Attribution 4.0
  http://creativecommons.org/licenses/by/4.0/

### Sound Effects
- Kick sounds: [Freesound user] - [License]
- Footsteps: [Freesound user] - [License]
```

## 🚀 Advanced Asset Tips

### Optimizing for Mobile

1. **Reduce Poly Count**
   - Use Blender's decimate modifier
   - Target: < 5000 triangles per character
   - Target: < 10000 triangles per building

2. **Texture Optimization**
   - Resize textures to 1024x1024 max
   - Use texture atlases for multiple objects
   - Enable VRAM compression in Godot import settings

3. **Audio Optimization**
   - Music: 128kbps OGG (stereo)
   - SFX: 96kbps OGG or 16-bit WAV (mono)
   - Use compressed formats, avoid large WAV files

### Adding Animations

1. **Import Animations**
   - Download animations from Mixamo
   - Import into Godot
   - Add to AnimationPlayer

2. **Set Up Animation Tree**
   - Create AnimationTree node
   - Set up blend tree for smooth transitions
   - Connect to player/NPC scripts

3. **Test Animations**
   - Verify idle, walk, run, kick animations play correctly
   - Check animation blending is smooth
   - Adjust animation speeds if needed

## 🎨 Next Level Assets (Premium)

For a truly premium $49.99 experience, consider:

### Professional Asset Stores
- **Synty Studios**: Polygon City Pack ($19.99)
- **Unity Asset Store**: High-quality city packs (Godot compatible via FBX)
- **TurboSquid**: Professional 3D models

### Custom Music
- **Hire a composer** on Fiverr ($50-200)
- **AudioJungle**: Professional game music tracks ($20-50 per track)
- **Epidemic Sound**: Subscription service with high-quality tracks

### Professional Sound Design
- **AudioJungle**: Professional SFX packs
- **Sonniss Game Audio GDC**: Free annual bundle
- **Pro Sound Effects**: Professional libraries

---

**Remember**: Even with placeholder graphics, the game mechanics are solid. Assets are the polish that takes it from good to great!
