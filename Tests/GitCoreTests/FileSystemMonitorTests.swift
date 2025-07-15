//
// FileSystemMonitorTests.swift
// GitCthulhu
//
// Created by GitCthulhu Team on 2025-07-15.
//

import Testing
import Foundation
import Combine
@testable import GitCore

@Suite("FileSystemMonitor Tests", .serialized)
struct FileSystemMonitorTests {

    @Test("FileSystemMonitor initialization")
    func testFileSystemMonitorInitialization() async throws {
        let tempURL = createTempDirectory()
        defer { try? FileManager.default.removeItem(at: tempURL) }

        let monitor = await FileSystemMonitor(repositoryPath: tempURL)

        await MainActor.run {
            #expect(!monitor.isMonitoring)
        }
    }

    @Test("Start and stop monitoring")
    func testStartStopMonitoring() async throws {
        let tempURL = createTempDirectory()
        defer { try? FileManager.default.removeItem(at: tempURL) }

        let monitor = await FileSystemMonitor(repositoryPath: tempURL)

        await MainActor.run {
            monitor.startMonitoring()
            #expect(monitor.isMonitoring)

            monitor.stopMonitoring()
            #expect(!monitor.isMonitoring)
        }
    }

    @Test("File system event detection")
    func testFileSystemEventDetection() async throws {
        let tempURL = createTempDirectory()
        defer { try? FileManager.default.removeItem(at: tempURL) }

        let monitor = await FileSystemMonitor(repositoryPath: tempURL)
        var receivedEvents: [FileSystemEvent] = []

        let expectation = XCTestExpectation(description: "File system event received")
        expectation.expectedFulfillmentCount = 1

        await MainActor.run {
            let cancellable = monitor.eventPublisher
                .sink { events in
                    receivedEvents = events
                    expectation.fulfill()
                }

            monitor.startMonitoring()

            // Create a test file to trigger events
            DispatchQueue.global().asyncAfter(deadline: .now() + 0.1) {
                let testFile = tempURL.appendingPathComponent("test.txt")
                try? "Hello World".write(to: testFile, atomically: true, encoding: .utf8)
            }

            // Wait for the event with timeout
            let result = XCTWaiter().wait(for: [expectation], timeout: 2.0)
            #expect(result == .completed)
            #expect(!receivedEvents.isEmpty)

            monitor.stopMonitoring()
            cancellable.cancel()
        }
    }

    @Test("Event filtering for Git internal files")
    func testEventFilteringForGitInternalFiles() async throws {
        let tempURL = createTempDirectory()
        defer { try? FileManager.default.removeItem(at: tempURL) }

        // Create .git directory structure
        let gitDir = tempURL.appendingPathComponent(".git")
        let objectsDir = gitDir.appendingPathComponent("objects")
        try FileManager.default.createDirectory(at: objectsDir, withIntermediateDirectories: true)

        let monitor = await FileSystemMonitor(repositoryPath: tempURL)
        var receivedEvents: [FileSystemEvent] = []
        var cancellable: AnyCancellable?

        await MainActor.run {
            cancellable = monitor.eventPublisher
                .sink { events in
                    receivedEvents.append(contentsOf: events)
                }

            monitor.startMonitoring()

            // Create files that should be filtered out
            DispatchQueue.global().asyncAfter(deadline: .now() + 0.1) {
                let objectFile = objectsDir.appendingPathComponent("test_object")
                try? "object_content".write(to: objectFile, atomically: true, encoding: .utf8)

                let lockFile = gitDir.appendingPathComponent("index.lock")
                try? "lock_content".write(to: lockFile, atomically: true, encoding: .utf8)
            }
        }

        // Wait a moment for potential events
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second

        await MainActor.run {
            // Should have no events for internal Git files
            #expect(receivedEvents.isEmpty)

            monitor.stopMonitoring()
            cancellable?.cancel()
        }
    }

    @Test("Event debouncing mechanism")
    func testEventDebouncing() async throws {
        let tempURL = createTempDirectory()
        defer { try? FileManager.default.removeItem(at: tempURL) }

        let monitor = await FileSystemMonitor(repositoryPath: tempURL)
        var eventBatches: [[FileSystemEvent]] = []
        var cancellable: AnyCancellable?

        let expectation = XCTestExpectation(description: "Debounced events received")
        expectation.expectedFulfillmentCount = 1

        await MainActor.run {
            cancellable = monitor.eventPublisher
                .sink { events in
                    eventBatches.append(events)
                    if eventBatches.count == 1 {
                        expectation.fulfill()
                    }
                }

            monitor.startMonitoring()

            // Create multiple files in rapid succession
            DispatchQueue.global().asyncAfter(deadline: .now() + 0.1) {
                for i in 1...5 {
                    let testFile = tempURL.appendingPathComponent("test\(i).txt")
                    try? "Content \(i)".write(to: testFile, atomically: true, encoding: .utf8)
                    Thread.sleep(forTimeInterval: 0.05) // Small delay between files
                }
            }
        }

        // Wait for debounced events
        let result = XCTWaiter().wait(for: [expectation], timeout: 3.0)
        #expect(result == .completed)

        await MainActor.run {
            // Should receive events in batches due to debouncing
            #expect(eventBatches.count >= 1)

            monitor.stopMonitoring()
            cancellable?.cancel()
        }
    }

    @Test("Monitor lifecycle with multiple start/stop cycles")
    func testMonitorLifecycle() async throws {
        let tempURL = createTempDirectory()
        defer { try? FileManager.default.removeItem(at: tempURL) }

        let monitor = await FileSystemMonitor(repositoryPath: tempURL)

        await MainActor.run {
            // Test multiple start/stop cycles
            for _ in 1...3 {
                monitor.startMonitoring()
                #expect(monitor.isMonitoring)

                monitor.stopMonitoring()
                #expect(!monitor.isMonitoring)
            }

            // Test redundant starts and stops
            monitor.startMonitoring()
            monitor.startMonitoring() // Should be safe to call multiple times
            #expect(monitor.isMonitoring)

            monitor.stopMonitoring()
            monitor.stopMonitoring() // Should be safe to call multiple times
            #expect(!monitor.isMonitoring)
        }
    }

    // MARK: - Helper Methods

    private func createTempDirectory() -> URL {
        let tempDir = FileManager.default.temporaryDirectory
        let uniqueDir = tempDir.appendingPathComponent(UUID().uuidString)
        try! FileManager.default.createDirectory(at: uniqueDir, withIntermediateDirectories: true)
        return uniqueDir
    }
}

// MARK: - XCTestExpectation for Testing Support

/// Simplified expectation for async testing
private class XCTestExpectation {
    let description: String
    var expectedFulfillmentCount = 1
    private var fulfillmentCount = 0
    private var isFulfilled = false

    init(description: String) {
        self.description = description
    }

    func fulfill() {
        fulfillmentCount += 1
        if fulfillmentCount >= expectedFulfillmentCount {
            isFulfilled = true
        }
    }

    var isComplete: Bool {
        return isFulfilled
    }
}

/// Simplified waiter for async testing
private class XCTWaiter {
    enum Result {
        case completed
        case timedOut
    }

    func wait(for expectations: [XCTestExpectation], timeout: TimeInterval) -> Result {
        let deadline = Date().addingTimeInterval(timeout)

        while Date() < deadline {
            if expectations.allSatisfy({ $0.isComplete }) {
                return .completed
            }
            Thread.sleep(forTimeInterval: 0.01)
        }

        return .timedOut
    }
}
