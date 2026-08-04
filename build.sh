#!/bin/bash
set -e

echo "============================================================"
echo "⚡ COMPILING CYBERPUNK COMMAND TERMINAL SCREENSAVER (.saver)"
echo "============================================================"

BUILD_DIR="build/CyberpunkSaver.saver"
MODULE_CACHE="module-cache"

# Clean build dir
rm -rf build "$MODULE_CACHE"
mkdir -p "$BUILD_DIR/Contents/MacOS"
mkdir -p "$BUILD_DIR/Contents/Resources"
mkdir -p "$MODULE_CACHE"

echo "🔨 Compiling Swift ScreenSaverView subclass..."
swiftc -emit-library -o "$BUILD_DIR/Contents/MacOS/CyberpunkSaver" \
  -module-cache-path "./$MODULE_CACHE" \
  -framework ScreenSaver -framework WebKit -framework AppKit -framework Foundation \
  CyberpunkSaver/CyberpunkSaverView.swift

echo "📦 Bundling Info.plist and WebContent assets..."
cp CyberpunkSaver/Info.plist "$BUILD_DIR/Contents/"
cp -R CyberpunkSaver/WebContent "$BUILD_DIR/Contents/Resources/"

echo "✅ SUCCESS! CyberpunkSaver.saver compiled at:"
echo "   $(pwd)/$BUILD_DIR"
echo ""
echo "To install the screensaver on macOS, run:"
echo "   open build/CyberpunkSaver.saver"
echo "============================================================"
