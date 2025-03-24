#!/bin/bash

# Custom version code

if [ $# -ge 1 ]; then
    if [[ $1 =~ ^[0-9]+$ ]]; then
        CUSTOM_VERSION_CODE=$1
    else
        echo "Error: versionCode must be a positive integer"
        exit 1
    fi
fi

# Clean previous build
rm -rf build 2>/dev/null
mkdir -p build/{system/fonts,META-INF/com/google/android}

echo "Downloading font files..."
wget -O build/system/fonts/NotoColorEmoji.ttf \
  "https://github.com/googlefonts/noto-emoji/raw/main/fonts/Noto-COLRv1-noflags.ttf"

wget -O build/system/fonts/NotoColorEmojiLegacy.ttf \
  "https://github.com/googlefonts/noto-emoji/raw/main/fonts/NotoColorEmoji-emojicompat.ttf"

wget -O build/system/fonts/NotoColorEmojiFlags.ttf \
  "https://github.com/googlefonts/noto-emoji/raw/main/fonts/NotoColorEmoji-flagsonly.ttf"

# Get version from XML template
wget -q -O version.xml \
  "https://github.com/googlefonts/noto-emoji/raw/main/NotoColorEmoji.tmpl.ttx.tmpl"
VERSION=$(grep -oP '<fontRevision value="\K[^"]+' version.xml)

# Calculate versionCode
if [ -n "$CUSTOM_VERSION_CODE" ]; then
    VERSION_CODE=$CUSTOM_VERSION_CODE
else
    VERSION_CODE=$(echo $VERSION | tr -d '.' | cut -c1-4)
fi

# Create module.prop
cat > build/module.prop << EOF
id=Emoji_Font
name=Emoji Font
version=v$VERSION
versionCode=$VERSION_CODE
author=Kesantielu
description=Updated Emoji font
EOF

# Copy Magisk scripts
cp META-INF/com/google/android/{update-binary,updater-script} build/META-INF/com/google/android/

# Copy license
cp {LICENSE,LICENSE.font} build/

# Package ZIP
cd build
zip -qr ../EmojiMagisk.zip *
cd ..
rm -rf build version.xml

echo "Build complete"
