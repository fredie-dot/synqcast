#!/bin/bash

# Generate simple Android app icons
echo "Generating simple SynqCast app icons..."

# Create directories if they don't exist
mkdir -p android/app/src/main/res/mipmap-mdpi
mkdir -p android/app/src/main/res/mipmap-hdpi
mkdir -p android/app/src/main/res/mipmap-xhdpi
mkdir -p android/app/src/main/res/mipmap-xxhdpi
mkdir -p android/app/src/main/res/mipmap-xxxhdpi

# Create simple circular icons with gradient background
# Using a simpler approach without complex text rendering

# MDPI (48x48)
convert -size 48x48 xc:none \
  -fill "#6C63FF" \
  -draw "circle 24,24 24,2" \
  android/app/src/main/res/mipmap-mdpi/ic_launcher.png

# HDPI (72x72)
convert -size 72x72 xc:none \
  -fill "#6C63FF" \
  -draw "circle 36,36 36,3" \
  android/app/src/main/res/mipmap-hdpi/ic_launcher.png

# XHDPI (96x96)
convert -size 96x96 xc:none \
  -fill "#6C63FF" \
  -draw "circle 48,48 48,4" \
  android/app/src/main/res/mipmap-xhdpi/ic_launcher.png

# XXHDPI (144x144)
convert -size 144x144 xc:none \
  -fill "#6C63FF" \
  -draw "circle 72,72 72,6" \
  android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png

# XXXHDPI (192x192)
convert -size 192x192 xc:none \
  -fill "#6C63FF" \
  -draw "circle 96,96 96,8" \
  android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png

# Copy to round icons
cp android/app/src/main/res/mipmap-mdpi/ic_launcher.png android/app/src/main/res/mipmap-mdpi/ic_launcher_round.png
cp android/app/src/main/res/mipmap-hdpi/ic_launcher.png android/app/src/main/res/mipmap-hdpi/ic_launcher_round.png
cp android/app/src/main/res/mipmap-xhdpi/ic_launcher.png android/app/src/main/res/mipmap-xhdpi/ic_launcher_round.png
cp android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png android/app/src/main/res/mipmap-xxhdpi/ic_launcher_round.png
cp android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png android/app/src/main/res/mipmap-xxxhdpi/ic_launcher_round.png

echo "Simple app icons generated successfully!"
