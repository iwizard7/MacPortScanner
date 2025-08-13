#!/bin/bash

# MacPortScanner DMG Creation Script
# Creates a professional DMG installer

set -e

echo "💿 MacPortScanner DMG Creator"
echo "============================"

# Check if we're on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    echo "❌ This script is designed for macOS only"
    exit 1
fi

# Check for create-dmg
if ! command -v create-dmg &> /dev/null; then
    echo "📦 Installing create-dmg..."
    if command -v brew &> /dev/null; then
        brew install create-dmg
    else
        echo "❌ Homebrew not found. Please install create-dmg manually:"
        echo "   brew install create-dmg"
        exit 1
    fi
fi

# Build the app first if it doesn't exist
if [ ! -d "dist/MacPortScanner.app" ]; then
    echo "🔧 App not found, building first..."
    ./build-local.sh --skip-tests
fi

# Create DMG
echo "💿 Creating DMG installer..."

VERSION="0.1.0"
DMG_NAME="MacPortScanner-${VERSION}"

# Clean previous DMG
rm -f "${DMG_NAME}.dmg"

# Create DMG with create-dmg
create-dmg \
    --volname "MacPortScanner ${VERSION}" \
    --volicon "dist/MacPortScanner.app/Contents/Resources/AppIcon.icns" \
    --window-pos 200 120 \
    --window-size 600 400 \
    --icon-size 100 \
    --icon "MacPortScanner.app" 175 120 \
    --hide-extension "MacPortScanner.app" \
    --app-drop-link 425 120 \
    --background-color "#f0f0f0" \
    --text-size 16 \
    --no-internet-enable \
    "${DMG_NAME}.dmg" \
    "dist/" || {
    
    # Fallback: create simple DMG with hdiutil
    echo "⚠️  create-dmg failed, using hdiutil fallback..."
    
    # Create temporary directory
    temp_dir=$(mktemp -d)
    cp -R dist/MacPortScanner.app "$temp_dir/"
    
    # Create Applications symlink
    ln -s /Applications "$temp_dir/Applications"
    
    # Create README
    cat > "$temp_dir/README.txt" << EOF
MacPortScanner v${VERSION}
========================

Installation:
1. Drag MacPortScanner.app to the Applications folder
2. Launch from Applications or Spotlight

System Requirements:
- macOS 14.0 or later
- Network access permissions

For support: https://github.com/iwizard7/MacPortScanner
EOF
    
    # Create DMG
    hdiutil create -volname "MacPortScanner ${VERSION}" \
                   -srcfolder "$temp_dir" \
                   -ov -format UDZO \
                   "${DMG_NAME}.dmg"
    
    # Clean up
    rm -rf "$temp_dir"
}

if [ -f "${DMG_NAME}.dmg" ]; then
    echo "✅ DMG created successfully: ${DMG_NAME}.dmg"
    echo ""
    echo "📊 DMG Information:"
    ls -lh "${DMG_NAME}.dmg"
    echo ""
    echo "🧪 To test the DMG:"
    echo "   open ${DMG_NAME}.dmg"
    echo ""
    echo "📤 To distribute:"
    echo "   Upload ${DMG_NAME}.dmg to GitHub Releases"
else
    echo "❌ Failed to create DMG"
    exit 1
fi