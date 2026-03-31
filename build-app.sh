#!/bin/bash
# Build MarkdownReader with xcodebuild and install to /Applications

set -eo pipefail
cd "$(dirname "$0")"

APP_NAME="MarkdownReader"
DERIVED_DATA="build/DerivedData"

echo "Building $APP_NAME with xcodebuild..."
xcodebuild -scheme "$APP_NAME" -configuration Release -derivedDataPath "$DERIVED_DATA" -destination 'platform=macOS' build 2>&1 | tail -5

BUILT_APP="$DERIVED_DATA/Build/Products/Release/${APP_NAME}.app"

if [ ! -d "$BUILT_APP" ]; then
    echo "Error: Build output not found at $BUILT_APP"
    exit 1
fi

echo "Installing to /Applications..."
rm -rf "/Applications/${APP_NAME}.app"
cp -r "$BUILT_APP" /Applications/
echo "Done! $APP_NAME is installed at /Applications/${APP_NAME}.app"
