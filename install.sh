#!/bin/bash

APP_NAME="PixelParallax"
SAVER_NAME="$APP_NAME.saver"
DEST_DIR="$HOME/Library/Screen Savers"
SOURCE_DIR="PixelParallax"

echo "🔨 Compiling $APP_NAME..."

# Ensure directories exist
mkdir -p "$SAVER_NAME/Contents/MacOS"
mkdir -p "$SAVER_NAME/Contents/Resources"

# Compile
swiftc -emit-library -Xlinker -bundle -target arm64-apple-macosx14.0 \
    -framework ScreenSaver -framework Cocoa -framework AppKit \
    -o "$SAVER_NAME/Contents/MacOS/$APP_NAME" \
    "$SOURCE_DIR/PixelParallaxView.swift" \
    "$SOURCE_DIR/MIScenery.swift" \
    "$SOURCE_DIR/MICharacters.swift" \
    "$SOURCE_DIR/MIPalette.swift" \
    "$SOURCE_DIR/MIBackground.swift"

if [ $? -eq 0 ]; then
    echo "✅ Build Successful!"
else
    echo "❌ Build Failed."
    exit 1
fi

# Info.plist generation (if needed, but we have it)
# cp Info.plist ...

echo "📂 Installing to $DEST_DIR..."
rm -rf "$DEST_DIR/$SAVER_NAME"
cp -R "$SAVER_NAME" "$DEST_DIR/"

echo "🔄 Restarting LegacyScreenSaver engine..."
# Kill the legacy screen saver engine to force reload
killall "LegacyScreenSaver" 2>/dev/null

echo "✨ Done! Open System Settings -> Screen Saver to select PixelParallax."
