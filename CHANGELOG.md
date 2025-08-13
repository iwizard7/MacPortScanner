# Changelog

All notable changes to MacPortScanner will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.1.0] - 2025-08-13

### Added
- Initial release of MacPortScanner
- High-performance port scanning engine built with Rust
- Native macOS SwiftUI interface
- Real-time scan progress and results visualization
- Interactive charts and network topology views
- Multiple export formats (JSON, CSV, XML)
- Scan history with search and filtering
- Configurable scan profiles (Fast, Balanced, Thorough, Stealth)
- macOS system integration (notifications, Spotlight, menu bar)
- App Sandbox security with network permissions
- Automatic GitHub Actions build and release pipeline

### Features
- **Performance**: Scan up to 65,535 ports in 3 seconds
- **UI/UX**: Modern SwiftUI interface with dark/light mode
- **Visualization**: Interactive charts, graphs, and network maps
- **Export**: Multiple format support for scan results
- **History**: Complete scan history with search capabilities
- **Configuration**: Flexible scan settings and presets
- **Security**: macOS App Sandbox with proper permissions
- **Integration**: Native macOS features (notifications, Spotlight, etc.)

### Technical Details
- Rust core library for high-performance scanning
- SwiftUI interface optimized for macOS
- C bridge for Rust-Swift integration
- Asynchronous scanning with adaptive batch sizing
- IPv4/IPv6 support with CIDR notation
- TCP/UDP protocol support
- Service detection and fingerprinting
- Comprehensive error handling and logging

### System Requirements
- macOS 14.0 or later
- Apple Silicon (M1/M2/M3) or Intel processor
- Network access permissions

### Known Issues
- First launch may take a few seconds to initialize
- Large CIDR ranges (>1000 IPs) may require increased timeout settings
- App is not yet notarized (requires manual security approval)

### Development
- Complete development environment setup
- Automated testing with GitHub Actions
- Comprehensive documentation
- Code quality tools (rustfmt, clippy)
- Performance benchmarking suite