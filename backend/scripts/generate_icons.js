const fs = require('fs');
const path = require('path');
const sharp = require('sharp');

const sourceIcon = path.resolve(__dirname, '../../assets/Wehere_Logo_Assets/6_android_app_icon_1024.png');
const resDir = path.resolve(__dirname, '../../android/app/src/main/res');

const sizes = [
  { folder: 'mipmap-mdpi', size: 48 },
  { folder: 'mipmap-hdpi', size: 72 },
  { folder: 'mipmap-xhdpi', size: 96 },
  { folder: 'mipmap-xxhdpi', size: 144 },
  { folder: 'mipmap-xxxhdpi', size: 192 },
];

async function generate() {
  console.log(`Generating icons from ${sourceIcon}...`);
  if (!fs.existsSync(sourceIcon)) {
    console.error('Source icon not found:', sourceIcon);
    process.exit(1);
  }

  for (const item of sizes) {
    const targetDir = path.join(resDir, item.folder);
    if (!fs.existsSync(targetDir)) {
      fs.mkdirSync(targetDir, { recursive: true });
    }

    const launcherTarget = path.join(targetDir, 'ic_launcher.png');
    await sharp(sourceIcon)
      .resize(item.size, item.size)
      .toFile(launcherTarget);
    console.log(`Created ${launcherTarget} (${item.size}x${item.size})`);

    const roundTarget = path.join(targetDir, 'ic_launcher_round.png');
    // For round icon, create a circular mask
    const circleBuffer = Buffer.from(
      `<svg><circle cx="${item.size/2}" cy="${item.size/2}" r="${item.size/2}" fill="white"/></svg>`
    );
    await sharp(sourceIcon)
      .resize(item.size, item.size)
      .composite([{
        input: circleBuffer,
        blend: 'dest-in'
      }])
      .toFile(roundTarget);
    console.log(`Created ${roundTarget} (${item.size}x${item.size})`);
  }
  console.log('App icons generated successfully!');
}

generate().catch(err => {
  console.error(err);
  process.exit(1);
});
