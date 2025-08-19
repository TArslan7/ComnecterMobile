#!/bin/bash

# App Icon Generator Script for Comnecter Mobile
# This script generates all required icon sizes for iOS and Android

echo "🎨 Generating App Icons for Comnecter Mobile..."

# Check if source icon exists
SOURCE_ICON="assets/app_icon.png"
if [ ! -f "$SOURCE_ICON" ]; then
    echo "❌ Error: Source icon not found at $SOURCE_ICON"
    exit 1
fi

# Create directories if they don't exist
mkdir -p assets/icons/ios
mkdir -p assets/icons/android
mkdir -p assets/icons/web

echo "📱 Generating iOS Icons..."

# iOS App Store Icon (1024x1024)
convert "$SOURCE_ICON" -resize 1024x1024 -background transparent -gravity center -extent 1024x1024 "assets/icons/ios/ios_app_store_1024.png"

# iOS App Icons (all required sizes)
convert "$SOURCE_ICON" -resize 180x180 -background transparent -gravity center -extent 180x180 "assets/icons/ios/ios_180.png"
convert "$SOURCE_ICON" -resize 167x167 -background transparent -gravity center -extent 167x167 "assets/icons/ios/ios_167.png"
convert "$SOURCE_ICON" -resize 152x152 -background transparent -gravity center -extent 152x152 "assets/icons/ios/ios_152.png"
convert "$SOURCE_ICON" -resize 120x120 -background transparent -gravity center -extent 120x120 "assets/icons/ios/ios_120.png"
convert "$SOURCE_ICON" -resize 87x87 -background transparent -gravity center -extent 87x87 "assets/icons/ios/ios_87.png"
convert "$SOURCE_ICON" -resize 80x80 -background transparent -gravity center -extent 80x80 "assets/icons/ios/ios_80.png"
convert "$SOURCE_ICON" -resize 76x76 -background transparent -gravity center -extent 76x76 "assets/icons/ios/ios_76.png"
convert "$SOURCE_ICON" -resize 60x60 -background transparent -gravity center -extent 60x60 "assets/icons/ios/ios_60.png"
convert "$SOURCE_ICON" -resize 58x58 -background transparent -gravity center -extent 58x58 "assets/icons/ios/ios_58.png"
convert "$SOURCE_ICON" -resize 40x40 -background transparent -gravity center -extent 40x40 "assets/icons/ios/ios_40.png"
convert "$SOURCE_ICON" -resize 29x29 -background transparent -gravity center -extent 29x29 "assets/icons/ios/ios_29.png"
convert "$SOURCE_ICON" -resize 20x20 -background transparent -gravity center -extent 20x20 "assets/icons/ios/ios_20.png"

echo "🤖 Generating Android Icons..."

# Android App Icons (all required densities)
convert "$SOURCE_ICON" -resize 192x192 -background transparent -gravity center -extent 192x192 "assets/icons/android/android_192.png"
convert "$SOURCE_ICON" -resize 144x144 -background transparent -gravity center -extent 144x144 "assets/icons/android/android_144.png"
convert "$SOURCE_ICON" -resize 96x96 -background transparent -gravity center -extent 96x96 "assets/icons/android/android_96.png"
convert "$SOURCE_ICON" -resize 72x72 -background transparent -gravity center -extent 72x72 "assets/icons/android/android_72.png"
convert "$SOURCE_ICON" -resize 48x48 -background transparent -gravity center -extent 48x48 "assets/icons/android/android_48.png"
convert "$SOURCE_ICON" -resize 36x36 -background transparent -gravity center -extent 36x36 "assets/icons/android/android_36.png"

# Android Adaptive Icons (foreground and background)
convert "$SOURCE_ICON" -resize 108x108 -background transparent -gravity center -extent 108x108 "assets/icons/android/android_adaptive_foreground_108.png"
convert "$SOURCE_ICON" -resize 81x81 -background transparent -gravity center -extent 81x81 "assets/icons/android/android_adaptive_foreground_81.png"
convert "$SOURCE_ICON" -resize 54x54 -background transparent -gravity center -extent 54x54 "assets/icons/android/android_adaptive_foreground_54.png"

echo "🌐 Generating Web Icons..."

# Web Icons
convert "$SOURCE_ICON" -resize 512x512 -background transparent -gravity center -extent 512x512 "assets/icons/web/web_512.png"
convert "$SOURCE_ICON" -resize 192x192 -background transparent -gravity center -extent 192x192 "assets/icons/web/web_192.png"
convert "$SOURCE_ICON" -resize 180x180 -background transparent -gravity center -extent 180x180 "assets/icons/web/web_180.png"
convert "$SOURCE_ICON" -resize 152x152 -background transparent -gravity center -extent 152x152 "assets/icons/web/web_152.png"
convert "$SOURCE_ICON" -resize 144x144 -background transparent -gravity center -extent 144x144 "assets/icons/web/web_144.png"
convert "$SOURCE_ICON" -resize 120x120 -background transparent -gravity center -extent 120x120 "assets/icons/web/web_120.png"
convert "$SOURCE_ICON" -resize 114x114 -background transparent -gravity center -extent 114x114 "assets/icons/web/web_114.png"
convert "$SOURCE_ICON" -resize 96x96 -background transparent -gravity center -extent 96x96 "assets/icons/web/web_96.png"
convert "$SOURCE_ICON" -resize 72x72 -background transparent -gravity center -extent 72x72 "assets/icons/web/web_72.png"
convert "$SOURCE_ICON" -resize 48x48 -background transparent -gravity center -extent 48x48 "assets/icons/web/web_48.png"
convert "$SOURCE_ICON" -resize 32x32 -background transparent -gravity center -extent 32x32 "assets/icons/web/web_32.png"
convert "$SOURCE_ICON" -resize 16x16 -background transparent -gravity center -extent 16x16 "assets/icons/web/web_16.png"

echo "✅ App Icons Generated Successfully!"
echo ""
echo "📁 Generated Icons:"
echo "  📱 iOS: assets/icons/ios/ (13 icons)"
echo "  🤖 Android: assets/icons/android/ (9 icons)"
echo "  🌐 Web: assets/icons/web/ (12 icons)"
echo ""
echo "🎯 Next Steps:"
echo "  1. Copy iOS icons to ios/Runner/Assets.xcassets/AppIcon.appiconset/"
echo "  2. Copy Android icons to android/app/src/main/res/mipmap-*/"
echo "  3. Copy Web icons to web/"
echo ""
echo "💡 Tip: Use the Flutter launcher_icons package to automatically integrate these icons!"

