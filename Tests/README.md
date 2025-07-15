# GitCthulhu Test Suite

## Overview
This document describes the comprehensive test suite for GitCthulhu, including unit tests, integration tests, performance tests, and UI tests.

## Test Structure

### Unit Tests
- **GitCoreTests/**: Core Git functionality tests
- **GitCthulhuTests/**: Application-level tests
- **UITests/**: UI component tests

### Integration Tests
- **FileStatusIntegrationTests.swift**: Complete file status workflow tests
- **FileStatusPerformanceTests.swift**: Performance and stress tests
- **FileStatusUITests.swift**: UI integration tests

### Test Utilities
- **TestUtilities/TestRepository.swift**: Utility for creating test Git repositories

## Integration Test Coverage

### File Status Workflow Tests
- [x] Complete file status workflow (creation → staging → commit)
- [x] Stage/unstage operations
- [x] Diff view workflow
- [x] Real-time file system monitoring
- [x] Debounced refresh mechanism
- [x] Branch operations with file status
- [x] Error handling in file operations
- [x] Multi-repository management

### Performance Tests
- [x] Large repository status loading (500+ files)
- [x] Branch loading performance (20+ branches)
- [x] Concurrent file operations
- [x] File system monitoring with many changes
- [x] Memory usage monitoring
- [x] Repository cleanup performance
- [x] Stress tests for rapid operations
- [x] Multiple concurrent repositories

### UI Integration Tests
- [x] Repository detail view file status display
- [x] View model refresh functionality
- [x] Repository sidebar management
- [x] Content view integration
- [x] App view model initialization
- [x] View state updates with repository changes
- [x] Error handling in UI
- [x] Repository info panel integration
- [x] UI performance with large repositories
- [x] File system monitoring integration

## Running Tests

### All Tests
```bash
swift test
```

### Specific Test Suite
```bash
swift test --filter FileStatusIntegrationTests
swift test --filter FileStatusPerformanceTests
swift test --filter FileStatusUITests
```

### Performance Tests Only
```bash
swift test --filter Performance
```

## Test Coverage Goals

The integration tests aim to achieve:
- **85%+ code coverage** for file status management features
- **End-to-end workflow coverage** for all Sprint 2 features
- **Performance benchmarks** for large repositories
- **UI integration validation** for all view models

## Test Data Generation

The `TestRepository` utility provides:
- Temporary Git repository creation
- File status simulation (untracked, modified, staged, etc.)
- Large repository generation for performance testing
- Branch management for testing
- Cleanup and teardown functionality

## Known Limitations

1. **File System Monitoring**: Tests include delays to allow for file system event processing
2. **Performance Thresholds**: Performance tests have reasonable time limits but may vary by system
3. **Concurrent Operations**: Some tests may be sensitive to system load

## Continuous Integration

These tests are designed to run in CI environments and include:
- Proper cleanup of test repositories
- Reasonable timeout values
- Error handling for CI-specific scenarios
- Memory usage monitoring

## Contributing

When adding new tests:
1. Use the `TestRepository` utility for Git operations
2. Include proper cleanup in test teardown
3. Add appropriate delays for file system monitoring
4. Follow the existing test patterns and naming conventions
5. Update this documentation when adding new test categories