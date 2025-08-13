#!/bin/bash

# MacPortScanner Quick Build Script
# Fast build for development iterations

set -e

echo "⚡ MacPortScanner Quick Build"
echo "============================"

# Check if we're on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    echo "❌ This script is designed for macOS only"
    exit 1
fi

# Quick checks
if ! command -v cargo &> /dev/null; then
    echo "❌ Rust not found. Install from https://rustup.rs/"
    exit 1
fi

echo "🔧 Building Rust library..."
cd Core
cargo build --release --quiet
cd ..

if [ -f "Core/target/release/libmacportscan_core.a" ] || [ -f "Core/target/release/libmacportscan_core.dylib" ]; then
    echo "✅ Rust library built successfully"
else
    echo "❌ Rust library build failed"
    exit 1
fi

echo "📦 Creating quick distribution..."
mkdir -p dist-quick
mkdir -p "dist-quick/MacPortScanner.app/Contents/MacOS"
mkdir -p "dist-quick/MacPortScanner.app/Contents/Resources"

# Copy library
cp Core/target/release/libmacportscan_core.* "dist-quick/MacPortScanner.app/Contents/Resources/" 2>/dev/null || true

# Create minimal executable
cat > "dist-quick/MacPortScanner.app/Contents/MacOS/MacPortScanner" << 'EOF'
#!/bin/bash
echo "🚀 MacPortScanner Core Library Ready!"
echo "Library: $(ls -la "$0/../Resources/libmacportscan_core"*)"
echo ""
echo "🧪 To test: cd Core && cargo test"
echo "📚 To explore: cd Core && cargo doc --open"
EOF

chmod +x "dist-quick/MacPortScanner.app/Contents/MacOS/MacPortScanner"

# Create minimal Info.plist
cat > "dist-quick/MacPortScanner.app/Contents/Info.plist" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>MacPortScanner</string>
    <key>CFBundleIdentifier</key>
    <string>com.macportscanner.MacPortScanner</string>
    <key>CFBundleName</key>
    <string>MacPortScanner</string>
</dict>
</plist>
EOF

echo "✅ Quick build completed!"
echo "📦 Output: dist-quick/MacPortScanner.app"
echo "🚀 Run: open dist-quick/MacPortScanner.app"