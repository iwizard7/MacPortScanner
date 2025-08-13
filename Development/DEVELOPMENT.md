# MacPortScanner Development Guide

## 🛠️ Development Setup

### Prerequisites
- macOS 14.0 or later
- Xcode 15.0 or later with Command Line Tools
- Rust 1.70 or later
- Homebrew (recommended)

### Quick Setup
```bash
# Run the setup script
./setup.sh

# Or manually install dependencies
brew install create-dmg
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
```

## 🏗️ Build System

### Using Make (Recommended)
```bash
make help          # Show all available commands
make build         # Build the entire project
make test          # Run all tests
make clean         # Clean build artifacts
make dev           # Start development environment
make install       # Install to /Applications
```

### Manual Build
```bash
# Build Rust core
cd Core
cargo build --release

# Build Swift UI
cd UI
xcodebuild build -project MacPortScanner.xcodeproj -scheme MacPortScanner -configuration Release
```

## 🧪 Testing

### Rust Tests
```bash
cd Core
cargo test                    # Run all tests
cargo test --release         # Run optimized tests
cargo bench                  # Run benchmarks
cargo clippy                 # Lint code
cargo fmt                    # Format code
```

### Swift Tests
```bash
cd UI
xcodebuild test -project MacPortScanner.xcodeproj -scheme MacPortScanner -destination 'platform=macOS'
```

## 📁 Project Structure

```
MacPortScanner/
├── Core/                     # Rust scanning engine
│   ├── src/
│   │   ├── lib.rs           # Main library interface
│   │   ├── scanner.rs       # Core scanning logic
│   │   ├── network.rs       # Network utilities
│   │   ├── config.rs        # Configuration management
│   │   ├── results.rs       # Result data structures
│   │   └── bridge.rs        # C interface for Swift
│   ├── Cargo.toml           # Rust dependencies
│   └── benches/             # Performance benchmarks
├── UI/                      # Swift UI application
│   ├── MacPortScanner/
│   │   ├── MacPortScannerApp.swift      # App entry point
│   │   ├── ContentView.swift            # Main interface
│   │   ├── ScannerBridge.swift          # Rust integration
│   │   ├── ScanResultView.swift         # Results display
│   │   ├── VisualizationView.swift      # Charts and graphs
│   │   └── ConfigurationView.swift      # Settings
│   └── MacPortScanner.xcodeproj         # Xcode project
├── Development/             # Development tools
│   ├── setup.sh            # Environment setup
│   ├── build.sh            # Advanced build script
│   ├── Makefile            # Build automation
│   └── FEATURES.md         # Feature documentation
├── .github/workflows/       # CI/CD automation
├── build.sh                # Simple build script
└── README.md               # User documentation
```

## 🔧 Development Workflow

### 1. Feature Development
```bash
# Create feature branch
git checkout -b feature/new-feature

# Make changes to Rust core
cd Core
cargo test
cargo clippy

# Make changes to Swift UI
cd UI
# Use Xcode or your preferred editor

# Test the integration
make build
make test
```

### 2. Code Quality
```bash
# Format code
make format

# Lint code
make lint

# Run all checks
make check
```

### 3. Performance Testing
```bash
# Run benchmarks
cd Core
cargo bench

# Profile the application
# Use Instruments.app for Swift profiling
# Use cargo flamegraph for Rust profiling
```

## 🚀 Release Process

### 1. Version Bump
```bash
# Update version in Cargo.toml
# Update version in Xcode project
# Update CHANGELOG.md
```

### 2. Create Release
```bash
# Tag the release
git tag -a v0.1.0 -m "Release version 0.1.0"
git push origin v0.1.0

# GitHub Actions will automatically:
# - Build the application
# - Run tests
# - Create DMG installer
# - Upload to GitHub Releases
```

## 🐛 Debugging

### Rust Debugging
```bash
# Enable debug logging
RUST_LOG=debug cargo run

# Use lldb for debugging
rust-lldb target/debug/macportscan_core
```

### Swift Debugging
- Use Xcode's built-in debugger
- Set breakpoints in Swift code
- Use Console.app to view system logs

### Integration Debugging
- Check the C bridge functions in `bridge.rs`
- Verify memory management between Rust and Swift
- Use Activity Monitor to check resource usage

## 📊 Performance Optimization

### Rust Optimizations
- Use `cargo bench` to identify bottlenecks
- Profile with `cargo flamegraph`
- Optimize hot paths with `#[inline]`
- Use `rayon` for CPU-intensive parallel work

### Swift Optimizations
- Use Instruments.app for profiling
- Optimize SwiftUI view updates
- Minimize bridge calls between Rust and Swift
- Use `@State` and `@ObservedObject` efficiently

## 🔒 Security Considerations

### Code Signing
```bash
# Sign the application (requires Apple Developer account)
codesign --force --options runtime --deep --sign "Developer ID Application: Your Name" dist/MacPortScanner.app
```

### Notarization
```bash
# Notarize with Apple (requires Apple Developer account)
xcrun notarytool submit dist/MacPortScanner.dmg --apple-id your@email.com --password app-specific-password --team-id TEAMID --wait
```

### Sandboxing
- The app runs in Apple's App Sandbox
- Network permissions are requested explicitly
- File access is limited to user-selected files

## 🤝 Contributing Guidelines

### Code Style
- Rust: Follow `rustfmt` and `clippy` recommendations
- Swift: Follow Swift API Design Guidelines
- Use meaningful variable and function names
- Add documentation for public APIs

### Commit Messages
```
feat: add new scanning algorithm
fix: resolve memory leak in scanner
docs: update API documentation
test: add unit tests for network module
```

### Pull Requests
1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests
5. Update documentation
6. Submit a pull request

## 📚 Resources

### Rust Resources
- [Rust Book](https://doc.rust-lang.org/book/)
- [Async Programming in Rust](https://rust-lang.github.io/async-book/)
- [Tokio Documentation](https://tokio.rs/)

### Swift Resources
- [SwiftUI Documentation](https://developer.apple.com/documentation/swiftui)
- [Swift API Design Guidelines](https://swift.org/documentation/api-design-guidelines/)
- [macOS App Development](https://developer.apple.com/macos/)

### Network Programming
- [TCP/IP Illustrated](https://www.amazon.com/TCP-Illustrated-Volume-Implementation/dp/0201633469)
- [Network Programming with Rust](https://www.packtpub.com/product/network-programming-with-rust/9781788624893)

## 🆘 Troubleshooting

### Common Issues

#### Build Failures
```bash
# Clean and rebuild
make clean
make build

# Update dependencies
cd Core && cargo update
```

#### Xcode Issues
```bash
# Clean Xcode build cache
cd UI
xcodebuild clean -project MacPortScanner.xcodeproj -scheme MacPortScanner
rm -rf ~/Library/Developer/Xcode/DerivedData/MacPortScanner-*
```

#### Runtime Issues
```bash
# Check system logs
log show --predicate 'subsystem == "com.macportscanner.MacPortScanner"' --last 1h

# Enable debug logging
defaults write com.macportscanner.MacPortScanner DebugLogging -bool YES
```

### Getting Help
- Check existing GitHub issues
- Create a new issue with detailed information
- Join discussions in GitHub Discussions
- Contact maintainers via email

---

Happy coding! 🚀