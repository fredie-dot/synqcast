#!/bin/bash

# Generate Android app icons for all densities
# Requires ImageMagick to be installed

echo "Generating SynqCast app icons..."

# Create directories if they don't exist
mkdir -p android/app/src/main/res/mipmap-mdpi
mkdir -p android/app/src/main/res/mipmap-hdpi
mkdir -p android/app/src/main/res/mipmap-xhdpi
mkdir -p android/app/src/main/res/mipmap-xxhdpi
mkdir -p android/app/src/main/res/mipmap-xxxhdpi

# Create a simple icon with "SC" text
convert -size 48x48 xc:none \
  -fill "linear-gradient(45deg, #6C63FF, #8B7CF6, #A78BFA)" \
  -draw "circle 24,24 24,2" \
  -fill white \
  -font Arial-Bold \
  -pointsize 20 \
  -gravity center \
  -draw "text 0,0 'SC'" \
  android/app/src/main/res/mipmap-mdpi/ic_launcher.png

convert -size 72x72 xc:none \
  -fill "linear-gradient(45deg, #6C63FF, #8B7CF6, #A78BFA)" \
  -draw "circle 36,36 36,3" \
  -fill white \
  -font Arial-Bold \
  -pointsize 30 \
  -gravity center \
  -draw "text 0,0 'SC'" \
  android/app/src/main/res/mipmap-hdpi/ic_launcher.png

convert -size 96x96 xc:none \
  -fill "linear-gradient(45deg, #6C63FF, #8B7CF6, #A78BFA)" \
  -draw "circle 48,48 48,4" \
  -fill white \
  -font Arial-Bold \
  -pointsize 40 \
  -gravity center \
  -draw "text 0,0 'SC'" \
  android/app/src/main/res/mipmap-xhdpi/ic_launcher.png

convert -size 144x144 xc:none \
  -fill "linear-gradient(45deg, #6C63FF, #8B7CF6, #A78BFA)" \
  -draw "circle 72,72 72,6" \
  -fill white \
  -font Arial-Bold \
  -pointsize 60 \
  -gravity center \
  -draw "text 0,0 'SC'" \
  android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png

convert -size 192x192 xc:none \
  -fill "linear-gradient(45deg, #6C63FF, #8B7CF6, #A78BFA)" \
  -draw "circle 96,96 96,8" \
  -fill white \
  -font Arial-Bold \
  -pointsize 80 \
  -gravity center \
  -draw "text 0,0 'SC'" \
  android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png

# Copy to round icons
cp android/app/src/main/res/mipmap-mdpi/ic_launcher.png android/app/src/main/res/mipmap-mdpi/ic_launcher_round.png
cp android/app/src/main/res/mipmap-hdpi/ic_launcher.png android/app/src/main/res/mipmap-hdpi/ic_launcher_round.png
cp android/app/src/main/res/mipmap-xhdpi/ic_launcher.png android/app/src/main/res/mipmap-xhdpi/ic_launcher_round.png
cp android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png android/app/src/main/res/mipmap-xxhdpi/ic_launcher_round.png
cp android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png android/app/src/main/res/mipmap-xxxhdpi/ic_launcher_round.png

echo "App icons generated successfully!"
echo "Icons created in:"
echo "  - android/app/src/main/res/mipmap-mdpi/"
echo "  - android/app/src/main/res/mipmap-hdpi/"
echo "  - android/app/src/main/res/mipmap-xhdpi/"
echo "  - android/app/src/main/res/mipmap-xxhdpi/"
echo "  - android/app/src/main/res/mipmap-xxxhdpi/"
