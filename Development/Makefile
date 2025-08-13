# MacPortScanner Makefile
# Provides convenient commands for building, testing, and managing the project

.PHONY: all build clean test install run help setup deps

# Default target
all: build

# Build the entire project
build:
	@echo "🚀 Building MacPortScanner..."
	@./build.sh

# Clean all build artifacts
clean:
	@echo "🧹 Cleaning build artifacts..."
	@cd Core && cargo clean
	@cd UI && xcodebuild clean -project MacPortScanner.xcodeproj -scheme MacPortScanner || true
	@rm -rf dist/
	@echo "✅ Clean completed"

# Run tests
test:
	@echo "🧪 Running tests..."
	@cd Core && cargo test --release
	@echo "✅ Tests completed"

# Setup development environment
setup:
	@echo "🔧 Setting up development environment..."
	@./setup.sh

# Install dependencies
deps:
	@echo "📦 Installing dependencies..."
	@cd Core && cargo fetch
	@echo "✅ Dependencies installed"

# Run the application (debug mode)
run-debug:
	@echo "🏃 Running in debug mode..."
	@cd Core && cargo build
	@cd UI && xcodebuild build -project MacPortScanner.xcodeproj -scheme MacPortScanner -configuration Debug
	@open UI/build/Debug/MacPortScanner.app

# Run the application (release mode)
run:
	@echo "🏃 Running application..."
	@if [ -d "dist/MacPortScanner.app" ]; then \
		open dist/MacPortScanner.app; \
	else \
		echo "❌ Application not built. Run 'make build' first."; \
	fi

# Format code
format:
	@echo "🎨 Formatting code..."
	@cd Core && cargo fmt
	@echo "✅ Code formatted"

# Lint code
lint:
	@echo "🔍 Linting code..."
	@cd Core && cargo clippy -- -D warnings
	@echo "✅ Linting completed"

# Check code quality
check: format lint test

# Create release package
release: clean build
	@echo "📦 Creating release package..."
	@if [ -d "dist/MacPortScanner.app" ]; then \
		echo "✅ Release package ready in dist/"; \
	else \
		echo "❌ Release build failed"; \
		exit 1; \
	fi

# Install the application to /Applications
install: build
	@echo "📲 Installing MacPortScanner..."
	@if [ -d "dist/MacPortScanner.app" ]; then \
		cp -R dist/MacPortScanner.app /Applications/; \
		echo "✅ MacPortScanner installed to /Applications/"; \
	else \
		echo "❌ Application not found. Run 'make build' first."; \
		exit 1; \
	fi

# Uninstall the application
uninstall:
	@echo "🗑️  Uninstalling MacPortScanner..."
	@rm -rf /Applications/MacPortScanner.app
	@echo "✅ MacPortScanner uninstalled"

# Generate documentation
docs:
	@echo "📚 Generating documentation..."
	@cd Core && cargo doc --no-deps --open
	@echo "✅ Documentation generated"

# Benchmark performance
bench:
	@echo "⚡ Running benchmarks..."
	@cd Core && cargo bench
	@echo "✅ Benchmarks completed"

# Update dependencies
update:
	@echo "🔄 Updating dependencies..."
	@cd Core && cargo update
	@echo "✅ Dependencies updated"

# Security audit
audit:
	@echo "🔒 Running security audit..."
	@cd Core && cargo audit
	@echo "✅ Security audit completed"

# Development server (for UI development)
dev:
	@echo "🔧 Starting development environment..."
	@echo "Building Rust library in debug mode..."
	@cd Core && cargo build
	@echo "Starting Xcode for UI development..."
	@open UI/MacPortScanner.xcodeproj

# Show help
help:
	@echo "MacPortScanner Build System"
	@echo ""
	@echo "Available targets:"
	@echo "  build      - Build the entire project (default)"
	@echo "  clean      - Clean all build artifacts"
	@echo "  test       - Run all tests"
	@echo "  setup      - Setup development environment"
	@echo "  deps       - Install dependencies"
	@echo "  run        - Run the application (release mode)"
	@echo "  run-debug  - Run the application (debug mode)"
	@echo "  format     - Format Rust code"
	@echo "  lint       - Lint Rust code"
	@echo "  check      - Format, lint, and test"
	@echo "  release    - Create release package"
	@echo "  install    - Install to /Applications"
	@echo "  uninstall  - Remove from /Applications"
	@echo "  docs       - Generate documentation"
	@echo "  bench      - Run benchmarks"
	@echo "  update     - Update dependencies"
	@echo "  audit      - Run security audit"
	@echo "  dev        - Start development environment"
	@echo "  help       - Show this help message"
	@echo ""
	@echo "Examples:"
	@echo "  make build    # Build the project"
	@echo "  make test     # Run tests"
	@echo "  make install  # Build and install"
	@echo "  make clean    # Clean everything"