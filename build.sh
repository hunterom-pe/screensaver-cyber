#!/bin/bash
set -e

echo "============================================================"
echo "⚡ COMPILING CYBERPUNK COMMAND TERMINAL SCREENSAVER (.saver)"
echo "============================================================"

BUILD_DIR="build/CyberpunkSaver.saver"
MODULE_CACHE="module-cache"

# Generate self-contained single-file HTML bundle to bypass legacyScreenSaver sandbox file restrictions
echo "📦 Generating in-memory WebContent HTML bundle..."
python3 bundle_webcontent.py

# Clean build dir
rm -rf build "$MODULE_CACHE"
mkdir -p "$BUILD_DIR/Contents/MacOS"
mkdir -p "$BUILD_DIR/Contents/Resources"
mkdir -p "$MODULE_CACHE"

echo "🔨 Compiling Swift ScreenSaverView subclass as Mach-O Bundle (MH_BUNDLE)..."
swiftc -emit-library -Xlinker -bundle -o "$BUILD_DIR/Contents/MacOS/CyberpunkSaver" \
  -module-cache-path "./$MODULE_CACHE" \
  -framework ScreenSaver -framework AppKit -framework CoreGraphics -framework QuartzCore -framework Foundation \
  CyberpunkSaver/CyberpunkSaverView.swift

echo "📦 Bundling Info.plist and WebContent assets..."
cp CyberpunkSaver/Info.plist "$BUILD_DIR/Contents/"
cp -R CyberpunkSaver/WebContent "$BUILD_DIR/Contents/Resources/"

echo "🔍 Verifying Mach-O Header Binary Format:"
file "$BUILD_DIR/Contents/MacOS/CyberpunkSaver"

echo "✅ SUCCESS! CyberpunkSaver.saver compiled at:"
echo "   $(pwd)/$BUILD_DIR"
echo "============================================================"
