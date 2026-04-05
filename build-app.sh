#!/bin/bash
# Build MarkdownReader with xcodebuild and package as .app bundle

set -eo pipefail
cd "$(dirname "$0")"

APP_NAME="MarkdownReader"
DERIVED_DATA="build/DerivedData"
BUILD_DIR="$DERIVED_DATA/Build/Products/Release"
APP_BUNDLE="$BUILD_DIR/${APP_NAME}.app"

echo "Building $APP_NAME with xcodebuild..."
xcodebuild -scheme "$APP_NAME" -configuration Release -derivedDataPath "$DERIVED_DATA" -destination 'platform=macOS' build 2>&1 | tail -5

BUILT_EXEC="$BUILD_DIR/${APP_NAME}"

if [ ! -f "$BUILT_EXEC" ]; then
    echo "Error: Build output not found at $BUILT_EXEC"
    exit 1
fi

echo "Assembling .app bundle..."
rm -rf "$APP_BUNDLE"
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

# Copy executable
cp "$BUILT_EXEC" "$APP_BUNDLE/Contents/MacOS/${APP_NAME}"

# Generate Info.plist with variables resolved
sed \
    -e 's/$(PRODUCT_BUNDLE_IDENTIFIER)/com.youngchingjui.MarkdownReader/' \
    -e 's/$(CURRENT_PROJECT_VERSION)/1/' \
    -e 's/$(MARKETING_VERSION)/1.0/' \
    -e 's/$(EXECUTABLE_NAME)/MarkdownReader/' \
    -e 's/$(MACOSX_DEPLOYMENT_TARGET)/14.0/' \
    Sources/MarkdownReader/Info.plist > "$APP_BUNDLE/Contents/Info.plist"

# Create PkgInfo
echo -n "APPL????" > "$APP_BUNDLE/Contents/PkgInfo"

# Copy any bundled resources (Highlighter syntax definitions)
HIGHLIGHTER_BUNDLE="$BUILD_DIR/Highlighter_Highlighter.bundle"
if [ -d "$HIGHLIGHTER_BUNDLE" ]; then
    cp -r "$HIGHLIGHTER_BUNDLE" "$APP_BUNDLE/Contents/Resources/"
fi

echo "Installing to /Applications..."
rm -rf "/Applications/${APP_NAME}.app"
cp -r "$APP_BUNDLE" /Applications/
echo "Done! $APP_NAME is installed at /Applications/${APP_NAME}.app"
