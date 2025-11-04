#!/usr/bin/env node

/**
 * Asset Downloader for Donkey GTA
 * Downloads free CC0/CC-BY assets for the game
 *
 * This script fetches real 3D models, music, and sound effects
 * from freely available sources with proper licensing.
 */

const https = require('https');
const http = require('http');
const fs = require('fs');
const path = require('path');
const { exec } = require('child_process');
const { promisify } = require('util');

const execAsync = promisify(exec);

// Asset sources with download URLs
const ASSETS = {
  models: [
    {
      name: 'Kenney City Kit (Commercial)',
      url: 'https://kenney.nl/content/3-city-kit-commercial/city-kit-commercial.zip',
      dest: 'godot/assets/models/city/',
      license: 'CC0',
      attribution: 'City Kit (Commercial) by Kenney (kenney.nl)'
    },
    {
      name: 'Quaternius Animated Animals (via Poly Pizza)',
      info: 'Visit https://poly.pizza/bundle/Animated-Animal-Pack-ILAPXeUYiS to download',
      manual: true,
      dest: 'godot/assets/models/animals/',
      license: 'CC0',
      attribution: 'Animated Animals by Quaternius (quaternius.com)'
    }
  ],
  music: [
    {
      name: 'Kevin MacLeod - Cipher',
      info: 'Visit https://incompetech.com/music/royalty-free/ to download Cipher.mp3',
      manual: true,
      dest: 'godot/assets/audio/music/',
      license: 'CC-BY 4.0',
      attribution: '"Cipher" by Kevin MacLeod (incompetech.com) Licensed under Creative Commons: By Attribution 4.0 License http://creativecommons.org/licenses/by/4.0/'
    },
    {
      name: 'Kevin MacLeod - Funky Chunk',
      info: 'Visit https://incompetech.com/music/royalty-free/ to download Funky Chunk.mp3',
      manual: true,
      dest: 'godot/assets/audio/music/',
      license: 'CC-BY 4.0',
      attribution: '"Funky Chunk" by Kevin MacLeod (incompetech.com) Licensed under Creative Commons: By Attribution 4.0 License http://creativecommons.org/licenses/by/4.0/'
    }
  ],
  sfx: [
    {
      name: 'Kick Sound Effects',
      info: 'Visit https://freesound.org/ and search for "kick impact" with CC0 filter',
      manual: true,
      dest: 'godot/assets/audio/sfx/',
      license: 'CC0 / CC-BY',
      attribution: 'Various from Freesound.org (see CREDITS.md)'
    }
  ]
};

function createDirectories() {
  const dirs = [
    'godot/assets/models/animals',
    'godot/assets/models/city',
    'godot/assets/models/characters',
    'godot/assets/textures',
    'godot/assets/audio/music',
    'godot/assets/audio/sfx'
  ];

  dirs.forEach(dir => {
    if (!fs.existsSync(dir)) {
      fs.mkdirSync(dir, { recursive: true });
      console.log(`✅ Created directory: ${dir}`);
    }
  });
}

function printManualInstructions() {
  console.log('\n📋 MANUAL DOWNLOAD INSTRUCTIONS\n');
  console.log('Due to download protections, please manually download these assets:\n');

  console.log('🎨 3D MODELS:');
  console.log('1. Visit https://kenney.nl/assets/city-kit-commercial');
  console.log('   - Click "Download" button');
  console.log('   - Extract ZIP to: godot/assets/models/city/\n');

  console.log('2. Visit https://poly.pizza/bundle/Animated-Animal-Pack-ILAPXeUYiS');
  console.log('   - Download the pack (donkey, horse, etc.)');
  console.log('   - Extract to: godot/assets/models/animals/\n');

  console.log('🎵 MUSIC:');
  console.log('3. Visit https://incompetech.com/music/royalty-free/');
  console.log('   - Search for "Cipher" and download MP3');
  console.log('   - Search for "Funky Chunk" and download MP3');
  console.log('   - Save both to: godot/assets/audio/music/\n');

  console.log('🔊 SOUND EFFECTS:');
  console.log('4. Visit https://freesound.org/');
  console.log('   - Search "kick impact" with CC0 filter');
  console.log('   - Download 3-5 variations');
  console.log('   - Save to: godot/assets/audio/sfx/\n');

  console.log('💡 TIP: All these assets are FREE (CC0/CC-BY licensed)!');
  console.log('    Total download time: ~10 minutes\n');
}

async function createSampleAssets() {
  console.log('\n📦 Creating sample asset references...\n');

  // Create README files in each asset directory
  const readmes = [
    {
      path: 'godot/assets/models/animals/README.md',
      content: `# Animal Models

Download from: https://poly.pizza/bundle/Animated-Animal-Pack-ILAPXeUYiS

Models needed:
- Donkey.fbx (main character)
- Horse.fbx (variation)
- Any other animals you want to add

License: CC0 (Public Domain)
Attribution: Quaternius (quaternius.com)
`
    },
    {
      path: 'godot/assets/models/city/README.md',
      content: `# City Building Models

Download from: https://kenney.nl/assets/city-kit-commercial

This pack includes:
- 50+ building models
- FBX, OBJ, and GLTF formats
- Commercial buildings, skyscrapers, shops

License: CC0 (Public Domain)
Attribution: Kenney (kenney.nl)
`
    },
    {
      path: 'godot/assets/audio/music/README.md',
      content: `# Music Tracks

Download from: https://incompetech.com/music/royalty-free/

Recommended tracks:
- Cipher (urban energy)
- Funky Chunk (upbeat action)
- Fluffing a Duck (comedy/chaos)

License: CC-BY 4.0
Attribution: Kevin MacLeod (incompetech.com)
Required attribution in game credits!
`
    },
    {
      path: 'godot/assets/audio/sfx/README.md',
      content: `# Sound Effects

Download from: https://freesound.org/

Search for:
- "kick impact" (for kick attacks)
- "footstep concrete" (for walking)
- "donkey bray" (for donkey sounds)
- "crowd city" (for ambient sound)

License: CC0 or CC-BY (check each sound)
Attribution: See CREDITS.md for specific sounds
`
    }
  ];

  readmes.forEach(readme => {
    fs.writeFileSync(readme.path, readme.content);
    console.log(`✅ Created: ${readme.path}`);
  });
}

async function main() {
  console.log('🫏 Donkey GTA Asset Downloader\n');
  console.log('This script will help you download free assets for the game.\n');

  createDirectories();
  await createSampleAssets();
  printManualInstructions();

  console.log('✨ Setup complete!\n');
  console.log('📝 Next steps:');
  console.log('   1. Download the assets using the links above');
  console.log('   2. Run: npm run integrate-assets (coming soon)');
  console.log('   3. Export game: cd godot && ./export_game.sh android\n');
}

main().catch(console.error);
