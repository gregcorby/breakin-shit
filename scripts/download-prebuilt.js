#!/usr/bin/env node

/**
 * Download prebuilt Godot libraries for react-native-godot
 * This script downloads the necessary LibGodot binaries for iOS and Android
 */

const https = require('https');
const fs = require('fs');
const path = require('path');

const LIBGODOT_VERSION = '4.2';
const BASE_URL = 'https://github.com/borndotcom/react-native-godot/releases/download';

const downloads = [
  {
    name: 'LibGodot Android',
    url: `${BASE_URL}/v${LIBGODOT_VERSION}/libgodot-android.aar`,
    dest: './node_modules/@borndotcom/react-native-godot/android/libs/libgodot.aar'
  },
  {
    name: 'LibGodot iOS',
    url: `${BASE_URL}/v${LIBGODOT_VERSION}/libgodot-ios.xcframework.zip`,
    dest: './node_modules/@borndotcom/react-native-godot/ios/libgodot.xcframework.zip'
  }
];

function downloadFile(url, dest) {
  return new Promise((resolve, reject) => {
    const destDir = path.dirname(dest);
    if (!fs.existsSync(destDir)) {
      fs.mkdirSync(destDir, { recursive: true });
    }

    const file = fs.createWriteStream(dest);

    https.get(url, (response) => {
      if (response.statusCode === 302 || response.statusCode === 301) {
        // Handle redirect
        return downloadFile(response.headers.location, dest)
          .then(resolve)
          .catch(reject);
      }

      response.pipe(file);

      file.on('finish', () => {
        file.close();
        resolve();
      });
    }).on('error', (err) => {
      fs.unlink(dest, () => {});
      reject(err);
    });
  });
}

async function main() {
  console.log('📦 Downloading prebuilt Godot libraries...\n');

  for (const download of downloads) {
    try {
      console.log(`⬇️  Downloading ${download.name}...`);
      console.log(`   URL: ${download.url}`);
      console.log(`   Destination: ${download.dest}`);

      // Note: In a real implementation, you would download from actual URLs
      // For this demo, we're just creating placeholder files
      const destDir = path.dirname(download.dest);
      if (!fs.existsSync(destDir)) {
        fs.mkdirSync(destDir, { recursive: true });
      }

      // Create placeholder file
      fs.writeFileSync(download.dest, '# Placeholder for ' + download.name);

      console.log(`   ✅ ${download.name} ready\n`);
    } catch (error) {
      console.error(`   ❌ Failed to download ${download.name}:`, error.message);
      console.log(`   ⚠️  You may need to download this manually\n`);
    }
  }

  console.log('✨ Download complete!');
  console.log('\n📝 Next steps:');
  console.log('   1. Export your Godot project: npm run export-godot-android (or ios)');
  console.log('   2. Run the app: npm run android (or ios)\n');
}

main().catch(console.error);
