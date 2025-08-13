# MacPortScanner Makefile
# Convenient commands for building, testing, and managing the project

.PHONY: all build quick dev clean test lint format docs bench dmg install uninstall help

# Default target
all: build

# Quick build for development
quick:
	@echo "⚡ Quick build..."
	@./Development/quick-build.sh

# Full local build
build:
	@echo "🚀 Full build..."
	@./Development/build-local.sh

# Development workflow
workflow:
	@echo "🚀 Development workflow..."
	@./Development/dev-workflow.sh

# Development build with all checks
dev:
	@echo "🛠️  Development build..."
	@./Development/dev-build.sh

# Development build with watch mode
watch:
	@echo "👀 Watch mode..."
	@./Development/dev-build.sh --watch

# Clean all build artifacts
clean:
	@echo "🧹 Cleaning..."
	@rm -rf Core/target/
	@rm -rf UI/build/
	@rm -rf dist/
	@rm -rf dist-quick/
	@rm -rf dev-dist/
	@rm -rf *.dmg
	@echo "✅ Clean completed"

# Run tests
test:
	@echo "🧪 Running tests..."
	@cd Core && cargo test

# Run tests with coverage
test-coverage:
	@echo "📊 Running tests with coverage..."
	@cd Core && cargo tarpaulin --out Html

# Lint code
lint:
	@echo "🔍 Linting code..."
	@cd Core && cargo clippy -- -D warnings

# Format code
format:
	@echo "🎨 Formatting code..."
	@cd Core && cargo fmt

# Check code quality (format + lint + test)
check: format lint test
	@echo "✅ All checks passed"

# Generate documentation
docs:
	@echo "📚 Generating documentation..."
	@cd Core && cargo doc --open --no-deps

# Run benchmarks
bench:
	@echo "⚡ Running benchmarks..."
	@cd Core && cargo bench

# Create DMG installer
dmg: build
	@echo "💿 Creating DMG..."
	@./Development/create-dmg.sh

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

# Development setup
setup:
	@echo "🔧 Setting up development environment..."
	@if [ -f "Development/setup.sh" ]; then \
		cd Development && ./setup.sh; \
	else \
		echo "⚠️  Setup script not found in Development/"; \
	fi

# Smart commit
commit:
	@echo "🤖 Creating smart commit..."
	@./Development/smart-commit.sh

# Update changelog
changelog:
	@echo "📝 Updating changelog..."
	@./Development/update-changelog.sh

# Full workflow
all-workflow:
	@echo "🚀 Full development workflow..."
	@./Development/dev-workflow.sh --all

# Update dependencies
update:
	@echo "🔄 Updating dependencies..."
	@cd Core && cargo update

# Security audit
audit:
	@echo "🔒 Running security audit..."
	@cd Core && cargo audit

# Release build (optimized)
release:
	@echo "🚀 Release build..."
	@./Development/build-local.sh --clean

# Debug build
debug:
	@echo "🐛 Debug build..."
	@./Development/build-local.sh --debug

# Run the application
run: quick
	@echo "🏃 Running application..."
	@open dist-quick/MacPortScanner.app

# Run development version
run-dev: dev
	@echo "🏃 Running development version..."
	@open dev-dist/MacPortScanner-Dev.app

# Package for distribution
package: clean release dmg
	@echo "📦 Package created successfully"

# Show help
help:
	@echo "MacPortScanner Build System"
	@echo ""
	@echo "🚀 Build Commands:"
	@echo "  make build       - Full production build"
	@echo "  make quick       - Fast development build"
	@echo "  make dev         - Development build with all checks"
	@echo "  make debug       - Debug build"
	@echo "  make release     - Optimized release build"
	@echo ""
	@echo "🤖 Workflow Commands:"
	@echo "  make workflow    - Interactive development workflow"
	@echo "  make all-workflow- Full automated workflow"
	@echo "  make commit      - Smart commit"
	@echo "  make changelog   - Update changelog"
	@echo ""
	@echo "🧪 Testing & Quality:"
	@echo "  make test      - Run all tests"
	@echo "  make lint      - Run clippy linting"
	@echo "  make format    - Format code"
	@echo "  make check     - Run format + lint + test"
	@echo "  make bench     - Run benchmarks"
	@echo "  make audit     - Security audit"
	@echo ""
	@echo "📚 Documentation:"
	@echo "  make docs      - Generate and open documentation"
	@echo ""
	@echo "🛠️  Development:"
	@echo "  make watch     - Watch for changes and rebuild"
	@echo "  make setup     - Setup development environment"
	@echo "  make update    - Update dependencies"
	@echo ""
	@echo "🏃 Running:"
	@echo "  make run       - Build and run application"
	@echo "  make run-dev   - Build and run development version"
	@echo ""
	@echo "📦 Distribution:"
	@echo "  make dmg       - Create DMG installer"
	@echo "  make package   - Full clean build + DMG"
	@echo "  make install   - Install to /Applications"
	@echo "  make uninstall - Remove from /Applications"
	@echo ""
	@echo "🧹 Maintenance:"
	@echo "  make clean     - Clean all build artifacts"
	@echo ""
	@echo "Examples:"
	@echo "  make quick && make run    # Quick build and run"
	@echo "  make check               # Full quality check"
	@echo "  make package             # Create distribution package"

# Show project status
status:
	@echo "📊 MacPortScanner Project Status"
	@echo "==============================="
	@echo ""
	@echo "📁 Project Structure:"
	@ls -la | grep -E "(Core|UI|Development|dist|\.sh$$|Makefile)" || true
	@echo ""
	@echo "🦀 Rust Information:"
	@rustc --version 2>/dev/null || echo "  Rust not installed"
	@echo ""
	@echo "🍎 macOS Information:"
	@sw_vers
	@echo ""
	@echo "📦 Build Artifacts:"
	@echo "  Rust library: $$(ls Core/target/release/libmacportscan_core.* 2>/dev/null | wc -l | tr -d ' ') file(s)"
	@echo "  Applications: $$(ls -d dist*/MacPortScanner*.app 2>/dev/null | wc -l | tr -d ' ') bundle(s)"
	@echo "  DMG files:    $$(ls *.dmg 2>/dev/null | wc -l | tr -d ' ') file(s)"

# Continuous integration simulation
ci: clean format lint test
	@echo "✅ CI simulation completed successfully"