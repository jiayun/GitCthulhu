//
// GitStatusManagerTests.swift
// GitCthulhu
//
// Created by GitCthulhu Team on 2025-07-15.
//

@testable import GitCore
import XCTest

final class GitStatusManagerTests: XCTestCase {
    var tempRepoURL: URL!
    var statusManager: GitStatusManager!

    override func setUp() async throws {
        try await super.setUp()

        // Create a temporary directory for testing
        let tempDir = FileManager.default.temporaryDirectory
        tempRepoURL = tempDir.appendingPathComponent("test-repo-\(UUID().uuidString)")

        try FileManager.default.createDirectory(at: tempRepoURL, withIntermediateDirectories: true)

        // Initialize a git repository
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/git")
        process.arguments = ["init"]
        process.currentDirectoryURL = tempRepoURL
        try process.run()
        process.waitUntilExit()

        // Configure git for testing
        let configProcess = Process()
        configProcess.executableURL = URL(fileURLWithPath: "/usr/bin/git")
        configProcess.arguments = ["config", "user.email", "test@example.com"]
        configProcess.currentDirectoryURL = tempRepoURL
        try configProcess.run()
        configProcess.waitUntilExit()

        let configProcess2 = Process()
        configProcess2.executableURL = URL(fileURLWithPath: "/usr/bin/git")
        configProcess2.arguments = ["config", "user.name", "Test User"]
        configProcess2.currentDirectoryURL = tempRepoURL
        try configProcess2.run()
        configProcess2.waitUntilExit()

        statusManager = GitStatusManager(repositoryURL: tempRepoURL)
    }

    override func tearDown() async throws {
        try await super.tearDown()

        // Clean up temporary directory
        if FileManager.default.fileExists(atPath: tempRepoURL.path) {
            try FileManager.default.removeItem(at: tempRepoURL)
        }
    }

    func testGetDetailedStatus_EmptyRepository() async throws {
        let entries = try await statusManager.getDetailedStatus()
        XCTAssertTrue(entries.isEmpty)
    }

    func testGetDetailedStatus_UntrackedFile() async throws {
        // Create an untracked file
        let testFile = tempRepoURL.appendingPathComponent("test.txt")
        try "Hello, World!".write(to: testFile, atomically: true, encoding: .utf8)

        let entries = try await statusManager.getDetailedStatus()
        XCTAssertEqual(entries.count, 1)

        guard let entry = entries.first else {
            XCTFail("Expected to find an entry")
            return
        }
        XCTAssertEqual(entry.filePath, "test.txt")
        XCTAssertEqual(entry.displayStatus, .untracked)
        XCTAssertTrue(entry.isUntracked)
        XCTAssertFalse(entry.isStaged)
    }

    func testGetDetailedStatus_StagedFile() async throws {
        // Create and stage a file
        let testFile = tempRepoURL.appendingPathComponent("staged.txt")
        try "Staged content".write(to: testFile, atomically: true, encoding: .utf8)

        let addProcess = Process()
        addProcess.executableURL = URL(fileURLWithPath: "/usr/bin/git")
        addProcess.arguments = ["add", "staged.txt"]
        addProcess.currentDirectoryURL = tempRepoURL
        try addProcess.run()
        addProcess.waitUntilExit()

        let entries = try await statusManager.getDetailedStatus()
        XCTAssertEqual(entries.count, 1)

        guard let entry = entries.first else {
            XCTFail("Expected to find an entry")
            return
        }
        XCTAssertEqual(entry.filePath, "staged.txt")
        XCTAssertEqual(entry.displayStatus, .added)
        XCTAssertTrue(entry.isStaged)
        XCTAssertFalse(entry.isUntracked)
    }

    func testGetStagedFiles() async throws {
        // Create untracked file
        let untrackedFile = tempRepoURL.appendingPathComponent("untracked.txt")
        try "Untracked".write(to: untrackedFile, atomically: true, encoding: .utf8)

        // Create and stage a file
        let stagedFile = tempRepoURL.appendingPathComponent("staged.txt")
        try "Staged".write(to: stagedFile, atomically: true, encoding: .utf8)

        let addProcess = Process()
        addProcess.executableURL = URL(fileURLWithPath: "/usr/bin/git")
        addProcess.arguments = ["add", "staged.txt"]
        addProcess.currentDirectoryURL = tempRepoURL
        try addProcess.run()
        addProcess.waitUntilExit()

        let stagedFiles = try await statusManager.getStagedFiles()
        XCTAssertEqual(stagedFiles.count, 1)
        XCTAssertEqual(stagedFiles.first?.filePath, "staged.txt")
        XCTAssertTrue(stagedFiles.first?.isStaged ?? false)
    }

    func testGetUntrackedFiles() async throws {
        // Create untracked file
        let untrackedFile = tempRepoURL.appendingPathComponent("untracked.txt")
        try "Untracked".write(to: untrackedFile, atomically: true, encoding: .utf8)

        // Create and stage a file
        let stagedFile = tempRepoURL.appendingPathComponent("staged.txt")
        try "Staged".write(to: stagedFile, atomically: true, encoding: .utf8)

        let addProcess = Process()
        addProcess.executableURL = URL(fileURLWithPath: "/usr/bin/git")
        addProcess.arguments = ["add", "staged.txt"]
        addProcess.currentDirectoryURL = tempRepoURL
        try addProcess.run()
        addProcess.waitUntilExit()

        let untrackedFiles = try await statusManager.getUntrackedFiles()
        XCTAssertEqual(untrackedFiles.count, 1)
        XCTAssertEqual(untrackedFiles.first?.filePath, "untracked.txt")
        XCTAssertTrue(untrackedFiles.first?.isUntracked ?? false)
    }

    func testIsRepositoryClean() async throws {
        // Initially clean
        let isClean1 = try await statusManager.isRepositoryClean()
        XCTAssertTrue(isClean1)

        // Add a file
        let testFile = tempRepoURL.appendingPathComponent("test.txt")
        try "Content".write(to: testFile, atomically: true, encoding: .utf8)

        // Should not be clean
        let isClean2 = try await statusManager.isRepositoryClean()
        XCTAssertFalse(isClean2)

        // Stage the file
        let addProcess = Process()
        addProcess.executableURL = URL(fileURLWithPath: "/usr/bin/git")
        addProcess.arguments = ["add", "test.txt"]
        addProcess.currentDirectoryURL = tempRepoURL
        try addProcess.run()
        addProcess.waitUntilExit()

        // Still not clean (staged changes)
        let isClean3 = try await statusManager.isRepositoryClean()
        XCTAssertFalse(isClean3)

        // Commit the file
        let commitProcess = Process()
        commitProcess.executableURL = URL(fileURLWithPath: "/usr/bin/git")
        commitProcess.arguments = ["commit", "-m", "Initial commit"]
        commitProcess.currentDirectoryURL = tempRepoURL
        try commitProcess.run()
        commitProcess.waitUntilExit()

        // Should be clean now
        let isClean4 = try await statusManager.isRepositoryClean()
        XCTAssertTrue(isClean4)
    }

    func testGetStatusSummary() async throws {
        // Create different types of files
        let untrackedFile = tempRepoURL.appendingPathComponent("untracked.txt")
        try "Untracked".write(to: untrackedFile, atomically: true, encoding: .utf8)

        let stagedFile = tempRepoURL.appendingPathComponent("staged.txt")
        try "Staged".write(to: stagedFile, atomically: true, encoding: .utf8)

        let addProcess = Process()
        addProcess.executableURL = URL(fileURLWithPath: "/usr/bin/git")
        addProcess.arguments = ["add", "staged.txt"]
        addProcess.currentDirectoryURL = tempRepoURL
        try addProcess.run()
        addProcess.waitUntilExit()

        let summary = try await statusManager.getStatusSummary()
        XCTAssertEqual(summary.stagedCount, 1)
        XCTAssertEqual(summary.untrackedCount, 1)
        XCTAssertEqual(summary.unstagedCount, 0)
        XCTAssertEqual(summary.conflictedCount, 0)
        XCTAssertFalse(summary.isClean)
        XCTAssertTrue(summary.hasChanges)
        XCTAssertEqual(summary.totalChanges, 2)
    }

    func testGetFileStatus() async throws {
        // Create a file
        let testFile = tempRepoURL.appendingPathComponent("test.txt")
        try "Content".write(to: testFile, atomically: true, encoding: .utf8)

        let entry = try await statusManager.getFileStatus("test.txt")
        XCTAssertNotNil(entry)
        XCTAssertEqual(entry?.filePath, "test.txt")
        XCTAssertTrue(entry?.isUntracked ?? false)

        // Non-existent file
        let nonExistentEntry = try await statusManager.getFileStatus("nonexistent.txt")
        XCTAssertNil(nonExistentEntry)
    }

    func testCache() async throws {
        // Create a file
        let testFile = tempRepoURL.appendingPathComponent("test.txt")
        try "Content".write(to: testFile, atomically: true, encoding: .utf8)

        // First call should populate cache
        let entries1 = try await statusManager.getDetailedStatus()
        XCTAssertEqual(entries1.count, 1)

        // Second call should use cache
        let entries2 = try await statusManager.getDetailedStatus()
        XCTAssertEqual(entries2.count, 1)

        // Invalidate cache
        statusManager.invalidateCache()

        // Should still work
        let entries3 = try await statusManager.getDetailedStatus()
        XCTAssertEqual(entries3.count, 1)
    }

    func testRefreshCache() async throws {
        // Create a file
        let testFile = tempRepoURL.appendingPathComponent("test.txt")
        try "Content".write(to: testFile, atomically: true, encoding: .utf8)

        // Load initial status
        let entries1 = try await statusManager.getDetailedStatus()
        XCTAssertEqual(entries1.count, 1)

        // Add another file
        let testFile2 = tempRepoURL.appendingPathComponent("test2.txt")
        try "Content2".write(to: testFile2, atomically: true, encoding: .utf8)

        // Refresh cache
        try await statusManager.refreshCache()

        // Should now have 2 files
        let entries2 = try await statusManager.getDetailedStatus()
        XCTAssertEqual(entries2.count, 2)
    }
}
