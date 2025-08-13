#!/bin/bash

# MacPortScanner Build Script
# This script builds both the Rust core library and the Swift UI application

set -e

echo "🚀 Building MacPortScanner..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if we're on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    print_error "This script is designed for macOS only"
    exit 1
fi

# Check for required tools
print_status "Checking for required tools..."

if ! command -v cargo &> /dev/null; then
    print_error "Rust/Cargo not found. Please install Rust from https://rustup.rs/"
    exit 1
fi

if ! command -v xcodebuild &> /dev/null; then
    print_error "Xcode command line tools not found. Please install with: xcode-select --install"
    exit 1
fi

print_success "All required tools found"

# Build Rust library
print_status "Building Rust core library..."
cd Core

# Clean previous builds
cargo clean

# Build for release
print_status "Compiling Rust library for release..."
cargo build --release

if [ $? -eq 0 ]; then
    print_success "Rust library built successfully"
else
    print_error "Failed to build Rust library"
    exit 1
fi

# Run tests
print_status "Running Rust tests..."
cargo test --release

if [ $? -eq 0 ]; then
    print_success "All Rust tests passed"
else
    print_warning "Some Rust tests failed, but continuing..."
fi

cd ..

# Build Swift application
print_status "Building Swift UI application..."
cd UI

# Clean previous builds
xcodebuild clean -project MacPortScanner.xcodeproj -scheme MacPortScanner

# Build the application
print_status "Compiling Swift application..."
xcodebuild build -project MacPortScanner.xcodeproj -scheme MacPortScanner -configuration Release

if [ $? -eq 0 ]; then
    print_success "Swift application built successfully"
else
    print_error "Failed to build Swift application"
    exit 1
fi

cd ..

# Create distribution package
print_status "Creating distribution package..."

DIST_DIR="dist"
APP_NAME="MacPortScanner.app"
BUILD_DIR="UI/build/Release"

# Clean and create distribution directory
rm -rf "$DIST_DIR"
mkdir -p "$DIST_DIR"

# Copy the built application
if [ -d "$BUILD_DIR/$APP_NAME" ]; then
    cp -R "$BUILD_DIR/$APP_NAME" "$DIST_DIR/"
    print_success "Application copied to distribution directory"
else
    print_error "Built application not found at $BUILD_DIR/$APP_NAME"
    exit 1
fi

# Create DMG (optional)
if command -v create-dmg &> /dev/null; then
    print_status "Creating DMG installer..."
    create-dmg \
        --volname "MacPortScanner" \
        --volicon "Resources/AppIcon.icns" \
        --window-pos 200 120 \
        --window-size 600 300 \
        --icon-size 100 \
        --icon "$APP_NAME" 175 120 \
        --hide-extension "$APP_NAME" \
        --app-drop-link 425 120 \
        "$DIST_DIR/MacPortScanner.dmg" \
        "$DIST_DIR/"
    
    if [ $? -eq 0 ]; then
        print_success "DMG created successfully"
    else
        print_warning "Failed to create DMG, but application is still available"
    fi
else
    print_warning "create-dmg not found. Install with: brew install create-dmg"
fi

# Print build summary
print_success "Build completed successfully!"
echo ""
echo "📦 Distribution files:"
echo "   Application: $DIST_DIR/$APP_NAME"
if [ -f "$DIST_DIR/MacPortScanner.dmg" ]; then
    echo "   Installer:   $DIST_DIR/MacPortScanner.dmg"
fi
echo ""
echo "🚀 To run the application:"
echo "   open $DIST_DIR/$APP_NAME"
echo ""
echo "📋 Build information:"
echo "   Rust version: $(rustc --version)"
echo "   Xcode version: $(xcodebuild -version | head -n 1)"
echo "   macOS version: $(sw_vers -productVersion)"
echo "   Architecture: $(uname -m)"

# Optional: Run the application
read -p "Would you like to run the application now? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    print_status "Launching MacPortScanner..."
    open "$DIST_DIR/$APP_NAME"
fi