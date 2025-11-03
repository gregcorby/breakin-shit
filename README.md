# 🫏 Donkey GTA - Urban Chaos on Four Hooves

A hilarious GTA-style action game where you ride a donkey through a bustling city and kick pedestrians for points! Built with React Native and Godot Engine using react-native-godot.

## 🎮 Game Features

### Core Gameplay
- **Ride a Donkey**: Control a fully-animated donkey through a procedurally generated city
- **Kick System**: Use powerful kicks to send NPCs flying with realistic physics
- **Combo System**: Chain kicks together for massive score multipliers
- **Open World**: Explore a dynamic city with buildings, streets, and ambient NPCs
- **Score Challenge**: Compete for the highest score with an addictive scoring system

### Technical Features
- **GTA-Style Camera**: Smooth third-person follow camera with collision detection
- **Procedural City**: Dynamically generated urban environment with buildings and streets
- **Advanced Physics**: Realistic character physics and ragdoll effects
- **Particle Effects**: Explosive visual feedback for kicks and impacts
- **Dynamic Audio**: Immersive music and sound effects system
- **Mobile Controls**: Intuitive touch controls optimized for mobile gameplay
- **Performance Optimized**: Runs smoothly on both iOS and Android devices

### Visual Polish
- **Volumetric Fog**: Atmospheric lighting and fog effects
- **Dynamic Lighting**: Real-time shadows and ambient lighting
- **Particle Systems**: Impact effects, dust clouds, and explosions
- **Screen Space Effects**: SSAO, bloom, and glow for enhanced visuals
- **Minimap**: Real-time overhead map for navigation

## 🚀 Quick Start

### Prerequisites

- Node.js 18 or higher
- React Native development environment ([setup guide](https://reactnative.dev/docs/environment-setup))
- Godot Engine 4.2 ([download](https://godotengine.org/download))
- For iOS: Xcode 14+, CocoaPods
- For Android: Android Studio, Android SDK 33+

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd breakin-shit
   ```

2. **Install dependencies**
   ```bash
   npm install
   # or
   yarn install
   ```

3. **Download prebuilt Godot libraries**
   ```bash
   npm run download-prebuilt
   ```

4. **Export Godot game**
   ```bash
   # For Android
   npm run export-godot-android

   # For iOS
   npm run export-godot-ios

   # For both
   cd godot
   ./export_game.sh all
   ```

### Running the Game

#### iOS
```bash
cd ios
bundle install
bundle exec pod install
cd ..
npm run ios
```

#### Android
```bash
npm run android
```

## 🎯 How to Play

### Controls

#### Desktop (Testing)
- **W/A/S/D**: Move donkey
- **Space**: Kick attack
- **Q/E**: Rotate camera
- **Right Mouse + Drag**: Free camera rotation

#### Mobile
- **Virtual Joystick** (left side): Move donkey around the city
- **Kick Button** (right side): Perform kick attack
- **Swipe**: Rotate camera view

### Gameplay Tips

1. **Build Combos**: Kick multiple NPCs quickly to increase your combo multiplier
2. **Time Your Kicks**: Wait for NPCs to group up for massive combo potential
3. **Explore the City**: Find dense NPC areas for higher scores
4. **Watch Your Combo Timer**: Keep kicking to maintain your multiplier
5. **Use the Minimap**: Navigate efficiently to find more targets

## 🏗️ Project Structure

```
breakin-shit/
├── App.tsx                    # React Native app entry
├── package.json               # NPM dependencies
├── index.js                   # RN entry point
├── godot/                     # Godot game project
│   ├── project.godot          # Godot project configuration
│   ├── export_game.sh         # Export script
│   ├── scenes/
│   │   └── Main.tscn          # Main game scene
│   └── scripts/
│       ├── GameManager.gd     # Game state & scoring
│       ├── DonkeyPlayer.gd    # Player controller
│       ├── FollowCamera.gd    # Camera system
│       ├── NPCPedestrian.gd   # NPC AI behavior
│       ├── NPCSpawner.gd      # NPC spawning system
│       ├── CityGenerator.gd   # Procedural city generation
│       ├── ParticleEffects.gd # Visual effects
│       ├── TouchControls.gd   # Mobile controls
│       └── AudioManager.gd    # Audio system
├── android/                   # Android project
└── ios/                       # iOS project
```

## 🎨 Asset Sources & Attribution

### 3D Models (Recommended Sources)

To enhance the game with high-quality 3D assets, we recommend these sources:

#### Donkey Model
- **Poly Pizza**: Free low-poly animals - [polypizza.com](https://poly.pizza/)
- **Sketchfab**: Search "donkey CC0" - [sketchfab.com](https://sketchfab.com/)
- **Quaternius**: Ultimate Animals Pack - [quaternius.com](https://quaternius.com/)
- **Kenney**: Animal Pack - [kenney.nl](https://kenney.nl/)

#### City Assets
- **Kenney City Kit**: Comprehensive city building pack - [kenney.nl/assets/city-kit](https://kenney.nl/assets/city-kit)
- **Synty Studios**: Polygon City Pack (paid, high quality)
- **Quaternius**: Ultimate Modular City - [quaternius.com](https://quaternius.com/)

#### Character Models
- **Mixamo**: Rigged character models (free with Adobe account) - [mixamo.com](https://www.mixamo.com/)
- **Ready Player Me**: Customizable avatars - [readyplayer.me](https://readyplayer.me/)
- **Kenney Character Pack**: Simple humanoid models

### Audio Assets (Recommended Sources)

#### Music
- **Incompetech**: Royalty-free music by Kevin MacLeod - [incompetech.com](https://incompetech.com/)
- **Free Music Archive**: CC-licensed tracks - [freemusicarchive.org](https://freemusicarchive.org/)
- **Purple Planet**: Free game music - [purple-planet.com](https://www.purple-planet.com/)
- Recommended tracks for city atmosphere:
  - "Cipher" by Kevin MacLeod (urban energy)
  - "Funky Chunk" by Kevin MacLeod (upbeat action)
  - "Fluffing a Duck" by Kevin MacLeod (comedy/chaos)

#### Sound Effects
- **Freesound**: Community sound library - [freesound.org](https://freesound.org/)
- **Kenney Audio**: Game sound packs - [kenney.nl/assets/category:Audio](https://kenney.nl/assets/category:Audio)
- **OpenGameArt**: Free game audio - [opengameart.org](https://opengameart.org/)

Recommended searches:
- "kick impact" for kick sounds
- "donkey bray" for donkey sounds
- "city ambience" for background atmosphere
- "footstep concrete" for walking sounds

### Asset Integration Instructions

1. **Download Assets**: Get your chosen assets from the sources above
2. **Place in Project**:
   - Models: `godot/assets/models/`
   - Audio: `godot/assets/audio/`
   - Textures: `godot/assets/textures/`
3. **Update Scene**: Modify `godot/scenes/Main.tscn` to reference real assets
4. **Update Scripts**: Replace placeholder mesh creation with model loading
5. **Test**: Run the game and verify all assets load correctly

## 🛠️ Development

### Adding New Features

1. **New GDScript**: Add scripts to `godot/scripts/`
2. **Modify Scene**: Edit `Main.tscn` in Godot Editor
3. **Re-export**: Run `npm run export-godot-[platform]`
4. **Test**: Run app on device/emulator

### Debugging

- **Godot Logs**: Check console output for Godot errors
- **React Native Logs**: Use `npx react-native log-android` or `log-ios`
- **Godot Remote Debugging**: Connect Godot editor to running game

### Performance Optimization

- Reduce `max_npcs` in NPCSpawner for better performance
- Adjust `city_size` in CityGenerator for larger/smaller cities
- Disable fog/particles on low-end devices
- Use simpler materials for better mobile performance

## 🎮 Game Design Philosophy

This game aims to deliver a **premium $49.99 gaming experience** through:

1. **Polished Mechanics**: Responsive controls and satisfying feedback
2. **Visual Excellence**: Modern rendering with effects and polish
3. **Engaging Gameplay**: Addictive scoring system with combo mechanics
4. **Attention to Detail**: Particle effects, sound design, camera work
5. **Replayability**: Procedural generation and score challenges
6. **Mobile Optimization**: Smooth 60 FPS gameplay on modern devices

## 📱 Platform Support

- **iOS**: Tested on iOS 14+
- **Android**: Tested on Android 10+ (API 29+)
- **Devices**: Optimized for devices from 2018 onwards

## 🤝 Contributing

Contributions are welcome! Areas for enhancement:

- Additional NPC types and behaviors
- More city props and variety
- Multiplayer support
- Achievement system
- Leaderboards
- More visual effects
- Additional game modes

## 📄 License

This project is provided as-is for educational and entertainment purposes.

**Asset Licenses**: When using third-party assets, ensure you comply with their respective licenses:
- CC0: No attribution required, free use
- CC-BY: Attribution required
- CC-BY-SA: Attribution + share-alike required

## 🙏 Acknowledgments

- **Godot Engine**: Amazing open-source game engine
- **Born/Migeran**: react-native-godot library creators
- **Asset Creators**: All the talented artists providing free game assets
- **Community**: Game development community for inspiration and support

## 📞 Support

For issues or questions:
- Check the documentation in `docs/`
- Review Godot logs for game-related issues
- Check React Native logs for app-related issues
- Ensure all dependencies are correctly installed

## 🎯 Roadmap

### Phase 1 (Current) - Core Game
- [x] Basic donkey movement
- [x] Kick mechanic
- [x] NPC spawning
- [x] Scoring system
- [x] Camera controls
- [x] City generation

### Phase 2 - Content & Polish
- [ ] Replace placeholder assets with high-quality 3D models
- [ ] Add professional music tracks
- [ ] Implement full sound effect library
- [ ] Add more particle effects
- [ ] Improve NPC AI variety

### Phase 3 - Features
- [ ] Power-ups system
- [ ] Different donkey types
- [ ] Weather effects
- [ ] Day/night cycle
- [ ] Mission system

### Phase 4 - Social & Competitive
- [ ] Online leaderboards
- [ ] Achievement system
- [ ] Replay system
- [ ] Social sharing
- [ ] Multiplayer mode

---

**Have fun causing chaos on your trusty donkey! 🫏💥**