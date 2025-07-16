//
// StagingOperationsTests.swift
// GitCthulhu
//
// Created by GitCthulhu Team on 2025-07-16.
//

import Foundation
@testable import GitCore
import XCTest

@MainActor
final class StagingOperationsTests: XCTestCase {
    private var tempRepositoryURL: URL!
    private var stagingOperations: GitStagingOperations!

    override func setUp() async throws {
        try await super.setUp()

        // Create temporary repository
        tempRepositoryURL = createTemporaryRepository()
        stagingOperations = GitStagingOperations(repositoryURL: tempRepositoryURL)
    }

    override func tearDown() async throws {
        // Clean up temporary repository
        if let tempRepositoryURL {
            try? FileManager.default.removeItem(at: tempRepositoryURL)
        }

        try await super.tearDown()
    }

    // MARK: - Test Helpers

    private func createTemporaryRepository() -> URL {
        let tempDir = FileManager.default.temporaryDirectory
        let repoName = "test-repo-\(UUID().uuidString)"
        let repoURL = tempDir.appendingPathComponent(repoName)

        // swiftlint:disable force_try
        try! FileManager.default.createDirectory(at: repoURL, withIntermediateDirectories: true)

        // Initialize git repository
        let gitInit = Process()
        gitInit.executableURL = URL(fileURLWithPath: "/usr/bin/git")
        gitInit.arguments = ["init"]
        gitInit.currentDirectoryURL = repoURL
        try! gitInit.run()
        gitInit.waitUntilExit()

        // Configure git user for testing
        let gitConfig = Process()
        gitConfig.executableURL = URL(fileURLWithPath: "/usr/bin/git")
        gitConfig.arguments = ["config", "user.email", "test@example.com"]
        gitConfig.currentDirectoryURL = repoURL
        try! gitConfig.run()
        gitConfig.waitUntilExit()

        let gitConfigName = Process()
        gitConfigName.executableURL = URL(fileURLWithPath: "/usr/bin/git")
        gitConfigName.arguments = ["config", "user.name", "Test User"]
        gitConfigName.currentDirectoryURL = repoURL
        try! gitConfigName.run()
        gitConfigName.waitUntilExit()
        // swiftlint:enable force_try

        return repoURL
    }

    private func createTestFile(named fileName: String, content: String = "test content") {
        let fileURL = tempRepositoryURL.appendingPathComponent(fileName)
        // swiftlint:disable:next force_try
        try! content.write(to: fileURL, atomically: true, encoding: .utf8)
    }

    private func stageFile(_ fileName: String) async throws {
        let gitAdd = Process()
        gitAdd.executableURL = URL(fileURLWithPath: "/usr/bin/git")
        gitAdd.arguments = ["add", fileName]
        gitAdd.currentDirectoryURL = tempRepositoryURL
        try gitAdd.run()
        gitAdd.waitUntilExit()
    }

    // MARK: - Smart Staging Operations Tests

    func testSmartStageFiles() async throws {
        // Create test files
        createTestFile(named: "file1.txt")
        createTestFile(named: "file2.txt")
        createTestFile(named: "file3.txt")

        // Stage one file manually
        try await stageFile("file1.txt")

        // Smart stage all files (should skip already staged file)
        let result = try await stagingOperations.smartStageFiles(["file1.txt", "file2.txt", "file3.txt"])

        // Verify result
        XCTAssertTrue(result.isSuccess)
        XCTAssertEqual(result.operation, .stage)
        XCTAssertEqual(result.successfulFiles.count, 2) // file2.txt and file3.txt
        XCTAssertEqual(result.skippedFiles.count, 1) // file1.txt was already staged
        XCTAssertEqual(result.failedFiles.count, 0)
    }

    func testSmartUnstageFiles() async throws {
        // Create and stage test files
        createTestFile(named: "file1.txt")
        createTestFile(named: "file2.txt")
        createTestFile(named: "file3.txt")

        try await stageFile("file1.txt")
        try await stageFile("file2.txt")
        // file3.txt remains unstaged

        // Smart unstage all files (should skip unstaged file)
        let result = try await stagingOperations.smartUnstageFiles(["file1.txt", "file2.txt", "file3.txt"])

        // Verify result
        XCTAssertTrue(result.isSuccess)
        XCTAssertEqual(result.operation, .unstage)
        XCTAssertEqual(result.successfulFiles.count, 2) // file1.txt and file2.txt
        XCTAssertEqual(result.skippedFiles.count, 1) // file3.txt was not staged
        XCTAssertEqual(result.failedFiles.count, 0)
    }

    func testToggleFilesStaging() async throws {
        // Create test files
        createTestFile(named: "staged.txt")
        createTestFile(named: "unstaged.txt")

        // Stage one file
        try await stageFile("staged.txt")

        // Toggle staging for both files
        let result = try await stagingOperations.toggleFilesStaging(["staged.txt", "unstaged.txt"])

        // Verify result
        XCTAssertTrue(result.isSuccess)
        XCTAssertEqual(result.operation, .toggle)
        XCTAssertEqual(result.successfulFiles.count, 2)
        XCTAssertEqual(result.failedFiles.count, 0)
    }

    // MARK: - Batch Operations Tests

    func testStageAllFilesWithProgress() async throws {
        // Create multiple test files
        createTestFile(named: "file1.txt")
        createTestFile(named: "file2.txt")
        createTestFile(named: "file3.txt")

        // Stage all files
        let result = try await stagingOperations.stageAllFilesWithProgress()

        // Verify result
        XCTAssertTrue(result.isSuccess)
        XCTAssertEqual(result.operation, .stageAll)
        XCTAssertEqual(result.successfulFiles.count, 3)
        XCTAssertEqual(result.failedFiles.count, 0)
    }

    func testUnstageAllFilesWithProgress() async throws {
        // Create and stage multiple test files
        createTestFile(named: "file1.txt")
        createTestFile(named: "file2.txt")
        createTestFile(named: "file3.txt")

        try await stageFile("file1.txt")
        try await stageFile("file2.txt")
        try await stageFile("file3.txt")

        // Unstage all files
        let result = try await stagingOperations.unstageAllFilesWithProgress()

        // Verify result
        XCTAssertTrue(result.isSuccess)
        XCTAssertEqual(result.operation, .unstageAll)
        XCTAssertEqual(result.successfulFiles.count, 3)
        XCTAssertEqual(result.failedFiles.count, 0)
    }

    // MARK: - Selective Operations Tests

    func testStageModifiedFiles() async throws {
        // Create and commit a file first
        createTestFile(named: "test.txt", content: "initial content")
        try await stageFile("test.txt")

        // Commit the file
        let commitProcess = Process()
        commitProcess.executableURL = URL(fileURLWithPath: "/usr/bin/git")
        commitProcess.arguments = ["commit", "-m", "Initial commit"]
        commitProcess.currentDirectoryURL = tempRepositoryURL
        try commitProcess.run()
        commitProcess.waitUntilExit()

        // Modify the file
        let fileURL = tempRepositoryURL.appendingPathComponent("test.txt")
        try "modified content".write(to: fileURL, atomically: true, encoding: .utf8)

        // Create untracked file
        createTestFile(named: "untracked.txt")

        // Stage only modified files
        let result = try await stagingOperations.stageModifiedFiles()

        // Verify result
        XCTAssertTrue(result.isSuccess)
        XCTAssertEqual(result.operation, .stageModified)
        XCTAssertEqual(result.successfulFiles.count, 1)
        XCTAssertTrue(result.successfulFiles.contains("test.txt"))
    }

    func testStageUntrackedFiles() async throws {
        // Create untracked files
        createTestFile(named: "untracked1.txt")
        createTestFile(named: "untracked2.txt")
        createTestFile(named: "untracked3.txt")

        // Stage only untracked files
        let result = try await stagingOperations.stageUntrackedFiles()

        // Verify result
        XCTAssertTrue(result.isSuccess)
        XCTAssertEqual(result.operation, .stageUntracked)
        XCTAssertEqual(result.successfulFiles.count, 3)
        XCTAssertTrue(result.successfulFiles.contains("untracked1.txt"))
        XCTAssertTrue(result.successfulFiles.contains("untracked2.txt"))
        XCTAssertTrue(result.successfulFiles.contains("untracked3.txt"))
    }

    // MARK: - Validation Tests

    func testValidateAndStageFiles() async throws {
        // Create test files
        createTestFile(named: "valid1.txt")
        createTestFile(named: "valid2.txt")

        // Validate and stage files
        let result = try await stagingOperations.validateAndStageFiles(["valid1.txt", "valid2.txt"])

        // Verify result
        XCTAssertTrue(result.isSuccess)
        XCTAssertEqual(result.operation, .stage)
        XCTAssertEqual(result.successfulFiles.count, 2)
        XCTAssertEqual(result.failedFiles.count, 0)
    }

    // MARK: - Status Query Tests

    func testGetDetailedStagingStatus() async throws {
        // Create files in different states
        createTestFile(named: "staged.txt")
        createTestFile(named: "untracked.txt")

        // Stage one file
        try await stageFile("staged.txt")

        // Get detailed status
        let detailedStatus = try await stagingOperations.getDetailedStagingStatus()

        // Verify status
        XCTAssertEqual(detailedStatus.stagedFiles, 1)
        XCTAssertEqual(detailedStatus.untrackedFiles, 1)
        XCTAssertEqual(detailedStatus.totalFiles, 2)
        XCTAssertTrue(detailedStatus.canStageAll)
        XCTAssertTrue(detailedStatus.canUnstageAll)
    }

    // MARK: - Result Object Tests

    func testStagingOperationResult() throws {
        // Test successful result
        let successResult = StagingOperationResult(
            operation: .stage,
            successfulFiles: ["file1.txt", "file2.txt"],
            failedFiles: [],
            skippedFiles: []
        )

        XCTAssertTrue(successResult.isSuccess)
        XCTAssertEqual(successResult.totalFiles, 2)
        XCTAssertEqual(successResult.summary, "2 successful")

        // Test result with failures
        let failureResult = StagingOperationResult(
            operation: .stage,
            successfulFiles: ["file1.txt"],
            failedFiles: ["file2.txt"],
            skippedFiles: ["file3.txt"]
        )

        XCTAssertFalse(failureResult.isSuccess)
        XCTAssertEqual(failureResult.totalFiles, 3)
        XCTAssertEqual(failureResult.summary, "1 successful, 1 failed, 1 skipped")
    }

    func testDetailedStagingStatus() throws {
        let detailedStatus = DetailedStagingStatus(
            totalFiles: 5,
            stagedFiles: 2,
            modifiedFiles: 2,
            untrackedFiles: 1,
            canStageAll: true,
            canUnstageAll: true
        )

        XCTAssertEqual(detailedStatus.totalFiles, 5)
        XCTAssertEqual(detailedStatus.stagedFiles, 2)
        XCTAssertEqual(detailedStatus.modifiedFiles, 2)
        XCTAssertEqual(detailedStatus.untrackedFiles, 1)
        XCTAssertTrue(detailedStatus.canStageAll)
        XCTAssertTrue(detailedStatus.canUnstageAll)
        XCTAssertEqual(detailedStatus.statusText, "2 staged, 2 modified, 1 untracked")
    }

    // MARK: - Error Handling Tests

    func testStageNonExistentFiles() async throws {
        // Try to stage files that don't exist
        let result = try await stagingOperations.smartStageFiles(["nonexistent1.txt", "nonexistent2.txt"])

        // Should report failures
        XCTAssertFalse(result.isSuccess)
        XCTAssertEqual(result.failedFiles.count, 2)
        XCTAssertEqual(result.successfulFiles.count, 0)
    }

    // MARK: - Performance Tests

    func testBatchOperationPerformance() async throws {
        // Create many files
        let fileCount = 50
        var filePaths: [String] = []

        for index in 0 ..< fileCount {
            let fileName = "file\(index).txt"
            createTestFile(named: fileName)
            filePaths.append(fileName)
        }

        // Measure batch staging performance
        let startTime = Date()
        let result = try await stagingOperations.smartStageFiles(filePaths)
        let endTime = Date()

        let duration = endTime.timeIntervalSince(startTime)
        // Log performance: Batch staging took \(duration) seconds for \(fileCount) files

        // Should complete within reasonable time
        XCTAssertLessThan(duration, 5.0)

        // Verify result
        XCTAssertTrue(result.isSuccess)
        XCTAssertEqual(result.successfulFiles.count, fileCount)
    }
}
