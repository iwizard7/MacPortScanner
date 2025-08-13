#!/bin/bash

# MacPortScanner Development Build Script
# Comprehensive build with development tools and checks

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

print_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[OK]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

echo "🛠️  MacPortScanner Development Build"
echo "==================================="

# Parse arguments
RUN_TESTS=true
RUN_CLIPPY=true
RUN_BENCHMARKS=false
GENERATE_DOCS=false
WATCH_MODE=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --no-tests)
            RUN_TESTS=false
            shift
            ;;
        --no-clippy)
            RUN_CLIPPY=false
            shift
            ;;
        --benchmarks)
            RUN_BENCHMARKS=true
            shift
            ;;
        --docs)
            GENERATE_DOCS=true
            shift
            ;;
        --watch)
            WATCH_MODE=true
            shift
            ;;
        --help)
            echo "Development build options:"
            echo "  --no-tests     Skip running tests"
            echo "  --no-clippy    Skip clippy linting"
            echo "  --benchmarks   Run performance benchmarks"
            echo "  --docs         Generate and open documentation"
            echo "  --watch        Watch for changes and rebuild"
            echo "  --help         Show this help"
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Check tools
print_step "Checking development tools..."

if ! command -v cargo &> /dev/null; then
    print_error "Rust not found"
    exit 1
fi

if ! command -v rustfmt &> /dev/null; then
    print_warning "rustfmt not found, installing..."
    rustup component add rustfmt
fi

if ! command -v clippy &> /dev/null && [ "$RUN_CLIPPY" = true ]; then
    print_warning "clippy not found, installing..."
    rustup component add clippy
fi

print_success "Development tools ready"

# Development build function
dev_build() {
    print_step "Building Rust library (debug mode)..."
    cd Core
    
    # Format code
    print_step "Formatting code..."
    cargo fmt
    
    # Build in debug mode for faster compilation
    cargo build
    
    if [ "$RUN_TESTS" = true ]; then
        print_step "Running tests..."
        cargo test
        print_success "All tests passed"
    fi
    
    if [ "$RUN_CLIPPY" = true ]; then
        print_step "Running clippy..."
        cargo clippy -- -D warnings
        print_success "Clippy checks passed"
    fi
    
    if [ "$RUN_BENCHMARKS" = true ]; then
        print_step "Running benchmarks..."
        cargo bench || print_warning "Benchmarks failed or not available"
    fi
    
    if [ "$GENERATE_DOCS" = true ]; then
        print_step "Generating documentation..."
        cargo doc --open --no-deps
    fi
    
    cd ..
    
    # Create development app bundle
    print_step "Creating development app bundle..."
    mkdir -p dev-dist
    mkdir -p "dev-dist/MacPortScanner-Dev.app/Contents/MacOS"
    mkdir -p "dev-dist/MacPortScanner-Dev.app/Contents/Resources"
    
    # Copy debug library
    cp Core/target/debug/libmacportscan_core.* "dev-dist/MacPortScanner-Dev.app/Contents/Resources/" 2>/dev/null || true
    
    # Create development executable with more info
    cat > "dev-dist/MacPortScanner-Dev.app/Contents/MacOS/MacPortScanner-Dev" << 'EOF'
#!/bin/bash

echo "🛠️  MacPortScanner Development Build"
echo "===================================="
echo ""
echo "📊 Build Information:"
echo "  • Mode: Debug"
echo "  • Built: $(date)"
echo "  • Rust: $(rustc --version)"
echo ""
echo "📁 Library Files:"
ls -la "$0/../Resources/libmacportscan_core"* 2>/dev/null || echo "  No library files found"
echo ""
echo "🧪 Development Commands:"
echo "  • Run tests:      cd Core && cargo test"
echo "  • Run benchmarks: cd Core && cargo bench"
echo "  • Format code:    cd Core && cargo fmt"
echo "  • Lint code:      cd Core && cargo clippy"
echo "  • Generate docs:  cd Core && cargo doc --open"
echo "  • Watch changes:  cd Core && cargo watch -x test"
echo ""
echo "🔧 Quick Actions:"
echo "  [1] Run tests"
echo "  [2] Run clippy"
echo "  [3] Generate docs"
echo "  [4] Exit"
echo ""

while true; do
    read -p "Choose action (1-4): " choice
    case $choice in
        1)
            echo "Running tests..."
            cd "$(dirname "$0")/../../.."
            cd Core && cargo test
            echo "Press Enter to continue..."
            read
            ;;
        2)
            echo "Running clippy..."
            cd "$(dirname "$0")/../../.."
            cd Core && cargo clippy
            echo "Press Enter to continue..."
            read
            ;;
        3)
            echo "Generating docs..."
            cd "$(dirname "$0")/../../.."
            cd Core && cargo doc --open --no-deps
            echo "Press Enter to continue..."
            read
            ;;
        4)
            echo "Goodbye!"
            exit 0
            ;;
        *)
            echo "Invalid choice. Please enter 1-4."
            ;;
    esac
done
EOF
    
    chmod +x "dev-dist/MacPortScanner-Dev.app/Contents/MacOS/MacPortScanner-Dev"
    
    # Create Info.plist for dev version
    cat > "dev-dist/MacPortScanner-Dev.app/Contents/Info.plist" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>MacPortScanner-Dev</string>
    <key>CFBundleIdentifier</key>
    <string>com.macportscanner.MacPortScanner.dev</string>
    <key>CFBundleName</key>
    <string>MacPortScanner Dev</string>
    <key>CFBundleDisplayName</key>
    <string>MacPortScanner (Development)</string>
</dict>
</plist>
EOF
    
    print_success "Development build completed!"
    echo ""
    echo "📦 Development app: dev-dist/MacPortScanner-Dev.app"
    echo "🚀 Run: open dev-dist/MacPortScanner-Dev.app"
}

# Watch mode
if [ "$WATCH_MODE" = true ]; then
    if ! command -v cargo-watch &> /dev/null; then
        print_step "Installing cargo-watch..."
        cargo install cargo-watch
    fi
    
    print_step "Starting watch mode..."
    echo "Watching for changes... Press Ctrl+C to stop"
    
    cd Core
    cargo watch -x 'build' -x 'test' -x 'clippy'
else
    dev_build
fi