#!/bin/bash

# MacPortScanner Simple Build Script
# This script builds the application for end users

set -e

echo "🚀 Building MacPortScanner..."

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if we're on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    print_error "This application is designed for macOS only"
    exit 1
fi

# Check for required tools
if ! command -v cargo &> /dev/null; then
    print_error "Rust not found. Please install Rust from https://rustup.rs/"
    exit 1
fi

if ! command -v xcodebuild &> /dev/null; then
    print_error "Xcode command line tools not found. Please install with: xcode-select --install"
    exit 1
fi

# Build Rust library
print_status "Building Rust core library..."
cd Core
cargo build --release
if [ $? -ne 0 ]; then
    print_error "Failed to build Rust library"
    exit 1
fi
cd ..

# Build Swift application
print_status "Building Swift application..."
cd UI
xcodebuild build -project MacPortScanner.xcodeproj -scheme MacPortScanner -configuration Release -derivedDataPath build
if [ $? -ne 0 ]; then
    print_error "Failed to build Swift application"
    exit 1
fi
cd ..

# Create distribution
print_status "Creating distribution..."
mkdir -p dist
cp -R UI/build/Build/Products/Release/MacPortScanner.app dist/

print_success "Build completed successfully!"
echo ""
echo "📦 Application built: dist/MacPortScanner.app"
echo "🚀 To run: open dist/MacPortScanner.app"
echo "📲 To install: cp -R dist/MacPortScanner.app /Applications/"