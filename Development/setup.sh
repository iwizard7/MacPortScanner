#!/bin/bash

# MacPortScanner Development Environment Setup Script
# This script sets up everything needed for development

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

echo "🔧 MacPortScanner Development Environment Setup"
echo "=============================================="

# Check if we're on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    print_error "This setup script is designed for macOS only"
    exit 1
fi

# Check for Homebrew
print_status "Checking for Homebrew..."
if ! command -v brew &> /dev/null; then
    print_warning "Homebrew not found. Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    
    if [ $? -eq 0 ]; then
        print_success "Homebrew installed successfully"
    else
        print_error "Failed to install Homebrew"
        exit 1
    fi
else
    print_success "Homebrew found"
fi

# Update Homebrew
print_status "Updating Homebrew..."
brew update

# Install Rust if not present
print_status "Checking for Rust..."
if ! command -v rustc &> /dev/null; then
    print_warning "Rust not found. Installing Rust..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    source ~/.cargo/env
    
    if [ $? -eq 0 ]; then
        print_success "Rust installed successfully"
    else
        print_error "Failed to install Rust"
        exit 1
    fi
else
    print_success "Rust found: $(rustc --version)"
fi

# Update Rust
print_status "Updating Rust..."
rustup update

# Install Rust components
print_status "Installing Rust components..."
rustup component add clippy rustfmt

# Install cargo tools
print_status "Installing useful Cargo tools..."
cargo install cargo-audit cargo-outdated cargo-tree

# Check for Xcode Command Line Tools
print_status "Checking for Xcode Command Line Tools..."
if ! xcode-select -p &> /dev/null; then
    print_warning "Xcode Command Line Tools not found. Installing..."
    xcode-select --install
    
    echo "Please complete the Xcode Command Line Tools installation and run this script again."
    exit 1
else
    print_success "Xcode Command Line Tools found"
fi

# Install additional development tools
print_status "Installing additional development tools..."
brew install --cask create-dmg || print_warning "create-dmg installation failed"

# Install useful development utilities
print_status "Installing development utilities..."
brew install git-lfs jq tree htop || print_warning "Some utilities failed to install"

# Setup Git hooks (if in a git repository)
if [ -d ".git" ]; then
    print_status "Setting up Git hooks..."
    
    # Pre-commit hook for formatting and linting
    cat > .git/hooks/pre-commit << 'EOF'
#!/bin/bash
# Pre-commit hook for MacPortScanner

echo "Running pre-commit checks..."

# Format Rust code
cd Core
cargo fmt --check
if [ $? -ne 0 ]; then
    echo "❌ Rust code is not formatted. Run 'cargo fmt' to fix."
    exit 1
fi

# Lint Rust code
cargo clippy -- -D warnings
if [ $? -ne 0 ]; then
    echo "❌ Rust code has linting errors. Fix them before committing."
    exit 1
fi

# Run tests
cargo test
if [ $? -ne 0 ]; then
    echo "❌ Tests failed. Fix them before committing."
    exit 1
fi

echo "✅ All pre-commit checks passed"
EOF
    
    chmod +x .git/hooks/pre-commit
    print_success "Git hooks installed"
fi

# Create development configuration
print_status "Creating development configuration..."

# Create .vscode directory with settings if it doesn't exist
if [ ! -d ".vscode" ]; then
    mkdir -p .vscode
    
    # VS Code settings
    cat > .vscode/settings.json << 'EOF'
{
    "rust-analyzer.cargo.features": "all",
    "rust-analyzer.checkOnSave.command": "clippy",
    "editor.formatOnSave": true,
    "files.associations": {
        "*.rs": "rust"
    },
    "swift.path": "/usr/bin/swift",
    "swift.sourcekit-lsp.serverPath": "/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/sourcekit-lsp"
}
EOF

    # VS Code tasks
    cat > .vscode/tasks.json << 'EOF'
{
    "version": "2.0.0",
    "tasks": [
        {
            "label": "Build Rust Core",
            "type": "shell",
            "command": "cargo",
            "args": ["build", "--release"],
            "options": {
                "cwd": "${workspaceFolder}/Core"
            },
            "group": "build",
            "presentation": {
                "echo": true,
                "reveal": "always",
                "focus": false,
                "panel": "shared"
            }
        },
        {
            "label": "Test Rust Core",
            "type": "shell",
            "command": "cargo",
            "args": ["test"],
            "options": {
                "cwd": "${workspaceFolder}/Core"
            },
            "group": "test",
            "presentation": {
                "echo": true,
                "reveal": "always",
                "focus": false,
                "panel": "shared"
            }
        },
        {
            "label": "Build Full Project",
            "type": "shell",
            "command": "./build.sh",
            "options": {
                "cwd": "${workspaceFolder}"
            },
            "group": {
                "kind": "build",
                "isDefault": true
            },
            "presentation": {
                "echo": true,
                "reveal": "always",
                "focus": false,
                "panel": "shared"
            }
        }
    ]
}
EOF

    # VS Code launch configuration
    cat > .vscode/launch.json << 'EOF'
{
    "version": "0.2.0",
    "configurations": [
        {
            "name": "Debug Rust Tests",
            "type": "lldb",
            "request": "launch",
            "program": "${workspaceFolder}/Core/target/debug/deps/macportscan_core-*",
            "args": [],
            "cwd": "${workspaceFolder}/Core",
            "sourceLanguages": ["rust"]
        }
    ]
}
EOF

    print_success "VS Code configuration created"
fi

# Install VS Code extensions (if VS Code is installed)
if command -v code &> /dev/null; then
    print_status "Installing VS Code extensions..."
    code --install-extension rust-lang.rust-analyzer
    code --install-extension vadimcn.vscode-lldb
    code --install-extension sswg.swift-lang
    print_success "VS Code extensions installed"
fi

# Fetch Rust dependencies
print_status "Fetching Rust dependencies..."
cd Core
cargo fetch
cd ..

# Create initial build to verify everything works
print_status "Performing initial build to verify setup..."
cd Core
cargo build
if [ $? -eq 0 ]; then
    print_success "Initial Rust build successful"
else
    print_error "Initial Rust build failed"
    exit 1
fi
cd ..

# Print setup summary
print_success "Development environment setup completed!"
echo ""
echo "📋 Setup Summary:"
echo "   ✅ Homebrew: $(brew --version | head -n 1)"
echo "   ✅ Rust: $(rustc --version)"
echo "   ✅ Cargo: $(cargo --version)"
echo "   ✅ Xcode: $(xcodebuild -version | head -n 1)"
echo ""
echo "🚀 Next Steps:"
echo "   1. Run 'make build' to build the project"
echo "   2. Run 'make test' to run tests"
echo "   3. Run 'make run' to launch the application"
echo "   4. Open the project in your favorite editor"
echo ""
echo "📚 Useful Commands:"
echo "   make help     - Show all available commands"
echo "   make dev      - Start development environment"
echo "   make check    - Format, lint, and test code"
echo ""
echo "🎉 Happy coding!"