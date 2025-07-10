# GitCthulhu 🐙

A Modern Git Client for macOS

> **Status**: 🚧 Active Development - Sprint 0 Complete

## 📋 Overview

GitCthulhu is an open-source Git client built specifically for macOS, combining the power of SwiftUI and AppKit to deliver a native, performant experience. The project follows a structured development approach with clear sprints and comprehensive testing.

## 🎯 Key Features (Planned)

- **Native macOS Experience**: Built with SwiftUI + AppKit hybrid architecture
- **Repository Management**: Open, clone, and manage multiple Git repositories
- **File Status Tracking**: Real-time file status with staging/unstaging capabilities
- **Branch Operations**: Create, switch, merge, and visualize branches
- **Commit Management**: Full commit workflow with message editing and history
- **Remote Operations**: Push, pull, fetch with authentication support
- **Modern UI**: Clean, intuitive interface following macOS design patterns

## 🛠 Technical Stack

- **Language**: Swift 5.9+
- **Frameworks**: SwiftUI, AppKit, Combine
- **Architecture**: Modular design with MVVM pattern
- **Git Backend**: Native Git integration (libgit2 planned)
- **Testing**: Swift Testing framework
- **CI/CD**: GitHub Actions
- **Minimum Requirements**: macOS 12+

## 📁 Project Structure

```
GitCthulhu/
├── Sources/
│   ├── GitCthulhu/           # Main application
│   │   ├── App/              # App lifecycle
│   │   ├── Views/            # SwiftUI Views
│   │   └── ViewModels/       # MVVM ViewModels
│   ├── GitCore/              # Git operations core
│   │   ├── Repository/       # Repository management
│   │   ├── Operations/       # Git operations
│   │   └── Models/           # Data models
│   ├── UIKit/                # Shared UI components
│   │   ├── Components/       # Reusable components
│   │   └── Extensions/       # SwiftUI extensions
│   └── Utilities/            # Helper utilities
│       ├── FileManager/      # File operations
│       └── Logger/           # Logging system
├── Tests/                    # Test suites
├── .github/                  # GitHub workflows & templates
└── Documentation/            # Project documentation
```

## 🚀 Current Status

### ✅ Sprint 0: Project Setup (Completed)
- [x] Xcode project structure created
- [x] Swift Package Manager configured
- [x] Modular architecture established
- [x] Basic UI framework implemented
- [x] Testing infrastructure setup
- [x] CI/CD pipeline configured
- [x] GitHub Issues and collaboration system

### 🔄 Next Steps (Sprint 1)
- [ ] Git repository core functionality
- [ ] Repository opening and validation
- [ ] Error handling and logging
- [ ] Basic repository information display

## 🏗 Development

### Prerequisites
- Xcode 15.0+
- macOS 12.0+
- Git 2.30+

### Building
```bash
# Clone the repository
git clone https://github.com/jiayun/GitCthulhu.git
cd GitCthulhu

# Build the project
swift build

# Run tests
swift test

# Run the application
swift run GitCthulhu
```

### Contributing

We welcome contributions! Please see our [contributing guidelines](CONTRIBUTING.md) and check out our [collaboration guide](CLAUDE_COLLABORATION.md) for working with AI assistance.

1. Check existing [Issues](https://github.com/jiayun/GitCthulhu/issues)
2. Follow our [Issue templates](https://github.com/jiayun/GitCthulhu/tree/main/.github/ISSUE_TEMPLATE)
3. Submit PRs using our [PR template](https://github.com/jiayun/GitCthulhu/blob/main/.github/PULL_REQUEST_TEMPLATE.md)

## 📊 Development Progress

| Sprint | Status | Deliverables |
|--------|--------|-------------|
| Sprint 0 | ✅ Complete | Project setup, CI/CD, basic architecture |
| Sprint 1 | 🔄 Next | Git core functionality, repository management |
| Sprint 2 | 📋 Planned | File status management, staging operations |
| Sprint 3 | 📋 Planned | Commit functionality and history |
| Sprint 4 | 📋 Planned | Branch management and operations |
| Sprint 5 | 📋 Planned | Remote operations (push/pull/fetch) |
| Sprint 6 | 📋 Planned | MVP polish and release preparation |

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Built with [SwiftUI](https://developer.apple.com/xcode/swiftui/) and [AppKit](https://developer.apple.com/documentation/appkit)
- Testing powered by [Swift Testing](https://github.com/apple/swift-testing)
- Developed with AI assistance from [Claude](https://claude.ai)

---

**Note**: This project is in active development. Features and APIs may change as we progress through the development sprints.