# 🛠️ Development Guide - Donkey GTA

This guide covers advanced development topics for extending and modifying the game.

## 🏗️ Architecture Overview

### React Native Layer
- **App.tsx**: Main React Native component that initializes Godot
- **index.js**: Entry point for React Native application
- Handles UI overlay, score display, and game controls integration
- Communicates with Godot via signals and the Godot API

### Godot Game Layer
All game logic runs in Godot Engine (4.2), which is embedded in React Native.

#### Core Systems

1. **GameManager** (`GameManager.gd`)
   - Central game state management
   - Score tracking with combo system
   - Game events and signals
   - Pause/resume functionality

2. **Player System** (`DonkeyPlayer.gd`)
   - Character controller for donkey
   - Input handling (WASD, touch)
   - Physics-based movement
   - Kick attack mechanics
   - Animation system integration

3. **Camera System** (`FollowCamera.gd`)
   - Third-person follow camera
   - Camera collision detection
   - Smooth interpolation
   - Mouse/touch rotation
   - Camera shake effects

4. **World Generation** (`CityGenerator.gd`)
   - Procedural city generation
   - Building placement and variety
   - Street network creation
   - Prop spawning (lampposts, benches)
   - Optimized for mobile performance

5. **NPC System** (`NPCPedestrian.gd`, `NPCSpawner.gd`)
   - AI state machine (idle, walking, running, ragdoll)
   - Navigation mesh pathfinding
   - Dynamic spawning based on player position
   - Despawn optimization
   - Kick reaction physics

6. **Effects System** (`ParticleEffects.gd`)
   - Particle pooling for performance
   - Kick impact effects
   - Dust clouds
   - Explosion effects
   - GPU particle systems

7. **Audio System** (`AudioManager.gd`)
   - Music playlist management
   - 3D spatial audio for SFX
   - Volume controls
   - Dynamic audio based on gameplay

8. **UI System** (`TouchControls.gd`)
   - Virtual joystick for movement
   - Touch-based kick button
   - Responsive touch handling
   - Mobile-optimized controls

## 🔧 Common Development Tasks

### Adding a New Feature

1. **Plan the Feature**
   - Define requirements
   - Identify which systems are affected
   - Consider mobile performance impact

2. **Implement in Godot**
   ```bash
   cd godot
   godot project.godot  # Opens Godot Editor
   ```
   - Create new GDScript in `scripts/`
   - Add nodes to `scenes/Main.tscn`
   - Test in Godot Editor (F5)

3. **Export Updated Game**
   ```bash
   cd godot
   ./export_game.sh android  # or ios
   ```

4. **Update React Native (if needed)**
   - Modify `App.tsx` for UI changes
   - Update signal connections for new events

5. **Test on Device**
   ```bash
   npm run android  # or npm run ios
   ```

### Example: Adding a Power-Up System

1. **Create PowerUp Script** (`godot/scripts/PowerUp.gd`)
   ```gdscript
   extends Area3D

   enum PowerUpType {
       SPEED_BOOST,
       KICK_POWER,
       INVINCIBILITY
   }

   @export var type: PowerUpType = PowerUpType.SPEED_BOOST
   @export var duration: float = 10.0

   signal collected(type: PowerUpType)

   func _ready():
       body_entered.connect(_on_body_entered)

   func _on_body_entered(body: Node3D):
       if body.is_in_group("player"):
           collected.emit(type)
           apply_powerup(body)
           queue_free()

   func apply_powerup(player: Node3D):
       match type:
           PowerUpType.SPEED_BOOST:
               player.move_speed *= 1.5
               await get_tree().create_timer(duration).timeout
               player.move_speed /= 1.5
           PowerUpType.KICK_POWER:
               player.kick_force *= 2.0
               await get_tree().create_timer(duration).timeout
               player.kick_force /= 2.0
   ```

2. **Add Spawning Logic** (in `CityGenerator.gd`)
   ```gdscript
   func spawn_powerups():
       for i in range(10):
           var powerup = preload("res://scenes/PowerUp.tscn").instantiate()
           powerup.position = Vector3(
               randf_range(-100, 100),
               1,
               randf_range(-100, 100)
           )
           add_child(powerup)
   ```

3. **Update UI** (in `App.tsx`)
   ```typescript
   // Connect to powerup signal
   const powerupNode = root.find_child('PowerUp', true, false);
   if (powerupNode) {
     powerupNode.collected.connect((type: number) => {
       showPowerupNotification(type);
     });
   }
   ```

### Debugging Tips

#### Godot Debugging
```bash
# Run Godot with console output
cd godot
godot --verbose project.godot

# Enable remote debugging
# In Godot Editor: Debug → Deploy with Remote Debug
```

#### React Native Debugging
```bash
# Android logs
npx react-native log-android

# iOS logs
npx react-native log-ios

# Open React Native debugger
# Press Cmd+D (iOS) or Cmd+M (Android) in simulator
```

#### Common Issues

**Issue**: Godot doesn't initialize
- **Solution**: Check console for initialization errors
- Verify PCK file is exported correctly
- Ensure Godot libraries are downloaded

**Issue**: Poor performance on device
- **Solution**: Reduce NPC count, city size
- Disable post-processing effects
- Lower shadow quality in Environment

**Issue**: Touch controls not responding
- **Solution**: Check z-index of UI elements
- Verify TouchControls CanvasLayer is on top
- Test touch events in Godot standalone first

## 📊 Performance Optimization

### Profiling

1. **Godot Profiler**
   ```bash
   # Run with profiler enabled
   godot --profile project.godot
   ```
   - Monitor frame time
   - Check draw calls
   - Identify bottlenecks

2. **React Native Performance**
   - Use Flipper for React Native profiling
   - Monitor JS thread usage
   - Check bridge communication overhead

### Optimization Strategies

#### Reduce Draw Calls
```gdscript
# Use MultiMesh for repeating objects
var multimesh = MultiMeshInstance3D.new()
multimesh.multimesh = MultiMesh.new()
multimesh.multimesh.mesh = building_mesh
multimesh.multimesh.instance_count = 100
# Set transforms for each instance
```

#### LOD (Level of Detail)
```gdscript
# Add LOD to buildings
var lod = GeometryInstance3D.new()
lod.lod_bias = 1.5  # Adjust based on distance
```

#### Occlusion Culling
```gdscript
# Enable in WorldEnvironment
env.environment.sdfgi_enabled = false  # For mobile
env.environment.volumetric_fog_enabled = false  # Optional
```

#### Object Pooling
```gdscript
# Pool NPCs instead of creating/destroying
var npc_pool: Array[Node3D] = []

func get_npc() -> Node3D:
    if npc_pool.size() > 0:
        return npc_pool.pop_back()
    else:
        return create_npc()

func return_npc(npc: Node3D):
    npc.visible = false
    npc_pool.append(npc)
```

## 🧪 Testing

### Unit Testing Godot Scripts

Create `godot/tests/test_game_manager.gd`:
```gdscript
extends GutTest

func test_score_increases_on_kick():
    var gm = GameManager.new()
    var initial_score = gm.score
    gm.add_kick_score(Vector3.ZERO)
    assert_gt(gm.score, initial_score, "Score should increase")

func test_combo_multiplier():
    var gm = GameManager.new()
    gm.add_kick_score(Vector3.ZERO)
    assert_eq(gm.combo_multiplier, 2, "Combo should be 2")
```

Run with [GUT (Godot Unit Test)](https://github.com/bitwes/Gut)

### Integration Testing

Test full gameplay loop:
1. Player movement
2. NPC spawning
3. Kick mechanics
4. Score updates
5. UI synchronization

## 🎨 Advanced Customization

### Custom Animations

1. **Import Animations from Mixamo**
   - Download FBX with animation
   - Import to Godot
   - Add to AnimationPlayer

2. **Blend Animations**
   ```gdscript
   var animation_tree = AnimationTree.new()
   animation_tree.tree_root = AnimationNodeBlendTree.new()

   # Add blend node
   var blend = AnimationNodeBlend2.new()
   animation_tree.tree_root.add_child(blend, "blend")
   ```

### Custom Shaders

Create `godot/shaders/cel_shade.gdshader`:
```glsl
shader_type spatial;

void fragment() {
    vec3 light = normalize(LIGHT);
    float NdotL = dot(NORMAL, light);

    // Cel shading steps
    float intensity = smoothstep(0.0, 0.01, NdotL);
    intensity = floor(intensity * 3.0) / 3.0;

    ALBEDO = ALBEDO.rgb * intensity;
}
```

### Procedural Generation

Advanced city generation:
```gdscript
# Use noise for terrain
var noise = FastNoiseLite.new()
noise.noise_type = FastNoiseLite.TYPE_PERLIN
noise.frequency = 0.05

func get_terrain_height(x: float, z: float) -> float:
    return noise.get_noise_2d(x, z) * 10.0
```

## 🚀 Deployment

### Building for Production

1. **Optimize Assets**
   ```bash
   # Compress textures
   # Reduce poly counts
   # Minimize audio files
   ```

2. **Export Release Build**
   ```bash
   cd godot
   ./export_game.sh all
   ```

3. **Build React Native Release**

   **Android**:
   ```bash
   cd android
   ./gradlew assembleRelease
   # APK in: android/app/build/outputs/apk/release/
   ```

   **iOS**:
   ```bash
   cd ios
   xcodebuild -workspace DonkeyGTA.xcworkspace \
              -scheme DonkeyGTA \
              -configuration Release \
              -archivePath build/DonkeyGTA.xcarchive \
              archive
   ```

4. **Test Release Build**
   - Install on multiple devices
   - Test performance
   - Verify all assets load
   - Check for crashes

### Publishing

1. **Google Play Store**
   - Create app listing
   - Upload APK/AAB
   - Add screenshots and description
   - Set pricing ($49.99 or free)

2. **Apple App Store**
   - Create app in App Store Connect
   - Upload IPA via Xcode
   - Submit for review
   - Configure pricing

## 📖 Additional Resources

- [Godot Documentation](https://docs.godotengine.org/)
- [React Native Godot GitHub](https://github.com/borndotcom/react-native-godot)
- [GDScript Style Guide](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_styleguide.html)
- [React Native Docs](https://reactnative.dev/docs/getting-started)

---

**Happy coding! Make this donkey game legendary! 🫏🎮**
