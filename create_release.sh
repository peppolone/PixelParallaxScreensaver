#!/bin/bash

# =========================================
# PixelParallax Release Builder
# Crea il file .zip pronto per la release
# =========================================

set -e

VERSION="${1:-1.0.0}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SAVER_NAME="PixelParallax.saver"
RELEASE_DIR="$SCRIPT_DIR/releases"
ZIP_NAME="PixelParallax-v${VERSION}.saver.zip"

echo "🎨 PixelParallax Release Builder"
echo "================================"
echo "Version: $VERSION"
echo ""

# 1. Compila lo screensaver (usa install.sh)
echo "📦 Compilando lo screensaver..."
"$SCRIPT_DIR/install.sh"

# 2. Verifica che il bundle esista
if [ ! -d "$SCRIPT_DIR/$SAVER_NAME" ]; then
    echo "❌ Errore: $SAVER_NAME non trovato!"
    exit 1
fi

# 3. Crea la cartella releases se non esiste
mkdir -p "$RELEASE_DIR"

# 4. Rimuovi vecchio zip se esiste
rm -f "$RELEASE_DIR/$ZIP_NAME"

# 5. Crea lo zip
echo "🗜️  Creando $ZIP_NAME..."
cd "$SCRIPT_DIR"
zip -r "$RELEASE_DIR/$ZIP_NAME" "$SAVER_NAME" -x "*.DS_Store"

# 6. Mostra info
ZIP_SIZE=$(du -h "$RELEASE_DIR/$ZIP_NAME" | cut -f1)
echo ""
echo "✅ Release creata con successo!"
echo ""
echo "📁 File: $RELEASE_DIR/$ZIP_NAME"
echo "📊 Dimensione: $ZIP_SIZE"
echo ""
echo "📝 Per pubblicare su GitHub:"
echo "   1. Vai su https://github.com/peppolone/PixelParallaxScreensaver/releases"
echo "   2. Click 'Create a new release'"
echo "   3. Tag: v$VERSION"
echo "   4. Allega il file: $ZIP_NAME"
echo ""
echo "📥 L'utente potrà installare così:"
echo "   1. Scarica e estrai il .zip"
echo "   2. Doppio click su PixelParallax.saver"
echo "   3. Conferma l'installazione"
