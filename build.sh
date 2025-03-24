#!/bin/bash

# Enable immediate exit on errors
set -e

cleanup() {
    exit_code=$?
    if [ $exit_code -ne 0 ]; then
        echo "Error while building module"
    fi
	rm -rf build version.xml
	trap - SIGINT SIGTERM ERR EXIT
    exit $exit_code
}

trap cleanup SIGINT SIGTERM ERR EXIT

if [ $# -ge 1 ]; then
    if [[ $1 =~ ^[0-9]+$ ]]; then
        CUSTOM_VERSION_CODE=$1
    else
        echo "Error: versionCode must be positive integer"
        exit 1
    fi
fi

# Check dependencies
for cmd in wget zip grep; do
    if ! command -v $cmd &> /dev/null; then
        echo "Error: $cmd required"
        exit 1
    fi
done

# Cleanup
rm -rf build 2>/dev/null
mkdir -p build/{system/fonts,META-INF/com/google/android}

# Download files
download_with_check() {
    echo "Downloading $2..."
    if ! wget -q --show-progress -O "$1" "$2"; then
        echo "Error downloading: $2"
        exit 1
    fi
}

# Check Magisk scripts
if [ ! -f "update-binary" ] || [ ! -f "updater-script" ]; then
    echo "Error: Magisk script files missing"
    exit 1
fi

cp {update-binary,updater-script} build/META-INF/com/google/android/

# Copy license
cp {LICENSE,LICENSE.font} build/

# Get version
download_with_check \
    version.xml \
    "https://github.com/googlefonts/noto-emoji/raw/main/NotoColorEmoji.tmpl.ttx.tmpl"

VERSION=$(grep -oP '<fontRevision value="\K[^"]+' version.xml || true)
if [ -z "$VERSION" ]; then
    echo "Error: can't get version"
    exit 1
fi

# Generate versionCode
if [ -n "$CUSTOM_VERSION_CODE" ]; then
    VERSION_CODE=$CUSTOM_VERSION_CODE
else
    VERSION_CODE=$(echo $VERSION | tr -d '.' | cut -c1-4)
    if [ -z "$VERSION_CODE" ]; then
        echo "Error: can't generate versionCode"
        exit 1
	fi
fi

download_with_check \
    build/system/fonts/NotoColorEmoji.ttf \
    "https://github.com/googlefonts/noto-emoji/raw/main/fonts/Noto-COLRv1-noflags.ttf"

download_with_check \
    build/system/fonts/NotoColorEmojiLegacy.ttf \
    "https://github.com/googlefonts/noto-emoji/raw/main/fonts/NotoColorEmoji-emojicompat.ttf"

download_with_check \
    build/system/fonts/NotoColorEmojiFlags.ttf \
    "https://github.com/googlefonts/noto-emoji/raw/main/fonts/NotoColorEmoji-flagsonly.ttf"

# Create module.prop
cat > build/module.prop << EOF
id=Emoji_Font
name=Emoji Font
version=$VERSION
versionCode=$VERSION_CODE
author=Kesantielu
description=Updated emoji font
EOF

# Create archive
cd build
if ! zip -qr ../EmojiMagisk.zip *; then
    echo "Error module packing"
	cd ..
    exit 1
fi
cd ..

# Finalization
echo "Build complete: EmojiMagisk.zip"
echo "version: $VERSION"
echo "versionCode: $VERSION_CODE"
