#!/bin/bash

APP_NAME="PixelParallax"
SAVER_NAME="$APP_NAME.saver"
DEST_DIR="$HOME/Library/Screen Savers"
SOURCE_DIR="PixelParallax"
ASSETS_DIR="$SOURCE_DIR/Assets"

echo "🔨 Compiling $APP_NAME (Universal Binary)..."

# Ensure directories exist
mkdir -p "$SAVER_NAME/Contents/MacOS"
mkdir -p "$SAVER_NAME/Contents/Resources"

# Copy Info.plist from source directory
if [ -f "$SOURCE_DIR/Info.plist" ]; then
    cp "$SOURCE_DIR/Info.plist" "$SAVER_NAME/Contents/Info.plist"
fi

# Copy assets (PNG sprites) to Resources
if [ -d "$ASSETS_DIR" ]; then
    echo "📁 Copying assets..."
    cp -R "$ASSETS_DIR/"*.png "$SAVER_NAME/Contents/Resources/" 2>/dev/null || true
fi

# Source files
SWIFT_FILES=(
    "$SOURCE_DIR/MISpriteLoader.swift"
    "$SOURCE_DIR/PixelParallaxView.swift"
    "$SOURCE_DIR/MIScenery.swift"
    "$SOURCE_DIR/MICharacters.swift"
    "$SOURCE_DIR/MIPalette.swift"
    "$SOURCE_DIR/MIBackground.swift"
)

# Compile for x86_64 (like Xcode does for compatibility with legacyScreenSaver)
echo "  → Building for x86_64..."
swiftc -emit-library -Xlinker -bundle -target x86_64-apple-macosx12.0 \
    -framework ScreenSaver -framework Cocoa -framework AppKit \
    -o "$SAVER_NAME/Contents/MacOS/$APP_NAME-x86_64" \
    "${SWIFT_FILES[@]}"

if [ $? -ne 0 ]; then
    echo "❌ x86_64 Build Failed."
    exit 1
fi

# Compile for arm64
echo "  → Building for arm64..."
swiftc -emit-library -Xlinker -bundle -target arm64-apple-macosx12.0 \
    -framework ScreenSaver -framework Cocoa -framework AppKit \
    -o "$SAVER_NAME/Contents/MacOS/$APP_NAME-arm64" \
    "${SWIFT_FILES[@]}"

if [ $? -ne 0 ]; then
    echo "❌ arm64 Build Failed."
    exit 1
fi

# Create Universal Binary with lipo
echo "  → Creating Universal Binary..."
lipo -create \
    "$SAVER_NAME/Contents/MacOS/$APP_NAME-x86_64" \
    "$SAVER_NAME/Contents/MacOS/$APP_NAME-arm64" \
    -output "$SAVER_NAME/Contents/MacOS/$APP_NAME"

# Clean up temp files
rm -f "$SAVER_NAME/Contents/MacOS/$APP_NAME-x86_64" "$SAVER_NAME/Contents/MacOS/$APP_NAME-arm64"

echo "✅ Build Successful!"

# Code sign (ad-hoc for local use)
echo "🔏 Code signing..."
codesign --force --sign - "$SAVER_NAME/Contents/MacOS/$APP_NAME" 2>/dev/null || true

echo "📂 Installing to $DEST_DIR..."
rm -rf "$DEST_DIR/$SAVER_NAME"
cp -R "$SAVER_NAME" "$DEST_DIR/"

echo "🔄 Restarting LegacyScreenSaver engine..."
# Kill the legacy screen saver engine to force reload
killall "LegacyScreenSaver" 2>/dev/null

echo "✨ Done! Open System Settings -> Screen Saver to select PixelParallax."
