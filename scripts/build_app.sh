#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
APP_NAME="Deck"
APP_BUNDLE="$PROJECT_DIR/$APP_NAME.app"

echo "==> 1. Ensuring AppIcon.icns is generated..."
cd "$PROJECT_DIR"
if [ ! -f "$PROJECT_DIR/Resources/AppIcon.icns" ]; then
    python3 "$PROJECT_DIR/scripts/generate_icon.py"
fi

echo "==> 2. Building $APP_NAME (Release mode)..."
swift build -c release

BIN_PATH="$PROJECT_DIR/.build/release/$APP_NAME"

echo "==> 3. Creating Application Bundle: $APP_BUNDLE..."
rm -rf "$APP_BUNDLE"
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

cp "$BIN_PATH" "$APP_BUNDLE/Contents/MacOS/$APP_NAME"
chmod +x "$APP_BUNDLE/Contents/MacOS/$APP_NAME"
cp "$PROJECT_DIR/Resources/Info.plist" "$APP_BUNDLE/Contents/Info.plist"
cp "$PROJECT_DIR/Resources/AppIcon.icns" "$APP_BUNDLE/Contents/Resources/AppIcon.icns"

# 4. 寻找 Apple Development 证书（支持本地 .codesign_identity 文件或 DEVELOPER_IDENTITY 环境变量）
IDENTITY="${DEVELOPER_IDENTITY:-}"
if [ -z "$IDENTITY" ] && [ -f "$PROJECT_DIR/.codesign_identity" ]; then
    IDENTITY=$(cat "$PROJECT_DIR/.codesign_identity" | tr -d '\r\n')
fi

if [ -z "$IDENTITY" ]; then
    IDENTITY=$(security find-identity -v -p codesigning | grep "Apple Development" | head -n 1 | awk -F'"' '{print $2}')
fi

if [ -n "$IDENTITY" ]; then
    echo "==> 4. Code signing with Apple Developer certificate: $IDENTITY..."
    codesign --force --deep --options runtime --sign "$IDENTITY" --identifier "com.deck.Deck" "$APP_BUNDLE"
else
    echo "==> 4. No developer certificate found, falling back to ad-hoc signing with stable designated requirement..."
    codesign --force --deep --sign - --identifier "com.deck.Deck" -r="designated => identifier \"com.deck.Deck\"" "$APP_BUNDLE"
fi

echo "==> 5. Verifying signature & designated requirement:"
codesign --verify --deep --strict "$APP_BUNDLE"
codesign -d -r- "$APP_BUNDLE"

echo "==> Successfully created $APP_BUNDLE with AppIcon and Developer Signature!"
