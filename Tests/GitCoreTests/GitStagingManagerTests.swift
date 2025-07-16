//
// GitStagingManagerTests.swift
// GitCthulhu
//
// Created by GitCthulhu Team on 2025-07-16.
//

import XCTest
import Foundation
@testable import GitCore

@MainActor
final class GitStagingManagerTests: XCTestCase {
    private var tempRepositoryURL: URL!
    private var stagingManager: GitStagingManager!

    override func setUp() async throws {
        try await super.setUp()

        // Create temporary repository
        tempRepositoryURL = createTemporaryRepository()
        stagingManager = GitStagingManager(repositoryURL: tempRepositoryURL)
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

        return repoURL
    }

    private func createTestFile(named fileName: String, content: String = "test content") {
        let fileURL = tempRepositoryURL.appendingPathComponent(fileName)
        try! content.write(to: fileURL, atomically: true, encoding: .utf8)
    }

    private func modifyTestFile(named fileName: String, content: String = "modified content") {
        let fileURL = tempRepositoryURL.appendingPathComponent(fileName)
        try! content.write(to: fileURL, atomically: true, encoding: .utf8)
    }

    private func deleteTestFile(named fileName: String) {
        let fileURL = tempRepositoryURL.appendingPathComponent(fileName)
        try! FileManager.default.removeItem(at: fileURL)
    }

    // MARK: - Single File Operations Tests

    func testStageFile() async throws {
        // Create and stage a file
        createTestFile(named: "test.txt")

        try await stagingManager.stageFile("test.txt")

        // Verify file is staged
        let status = try await stagingManager.getStagingStatus()
        XCTAssertTrue(status.stagedFiles.contains { $0.filePath == "test.txt" })
        XCTAssertTrue(status.hasStagedChanges)
    }

    func testUnstageFile() async throws {
        // Create and stage a file
        createTestFile(named: "test.txt")
        try await stagingManager.stageFile("test.txt")

        // Verify file is staged
        var status = try await stagingManager.getStagingStatus()
        XCTAssertTrue(status.stagedFiles.contains { $0.filePath == "test.txt" })

        // Unstage the file
        try await stagingManager.unstageFile("test.txt")

        // Verify file is unstaged
        status = try await stagingManager.getStagingStatus()
        XCTAssertFalse(status.stagedFiles.contains { $0.filePath == "test.txt" })
    }

    func testToggleFileStaging() async throws {
        // Create a file
        createTestFile(named: "test.txt")

        // Toggle staging (should stage)
        try await stagingManager.toggleFileStaging("test.txt")

        var status = try await stagingManager.getStagingStatus()
        XCTAssertTrue(status.stagedFiles.contains { $0.filePath == "test.txt" })

        // Toggle staging again (should unstage)
        try await stagingManager.toggleFileStaging("test.txt")

        status = try await stagingManager.getStagingStatus()
        XCTAssertFalse(status.stagedFiles.contains { $0.filePath == "test.txt" })
    }

    // MARK: - Batch Operations Tests

    func testStageMultipleFiles() async throws {
        // Create multiple files
        createTestFile(named: "file1.txt")
        createTestFile(named: "file2.txt")
        createTestFile(named: "file3.txt")

        // Stage all files
        try await stagingManager.stageFiles(["file1.txt", "file2.txt", "file3.txt"])

        // Verify all files are staged
        let status = try await stagingManager.getStagingStatus()
        XCTAssertTrue(status.stagedFiles.contains { $0.filePath == "file1.txt" })
        XCTAssertTrue(status.stagedFiles.contains { $0.filePath == "file2.txt" })
        XCTAssertTrue(status.stagedFiles.contains { $0.filePath == "file3.txt" })
        XCTAssertEqual(status.stagedFiles.count, 3)
    }

    func testUnstageMultipleFiles() async throws {
        // Create and stage multiple files
        createTestFile(named: "file1.txt")
        createTestFile(named: "file2.txt")
        createTestFile(named: "file3.txt")

        try await stagingManager.stageFiles(["file1.txt", "file2.txt", "file3.txt"])

        // Verify files are staged
        var status = try await stagingManager.getStagingStatus()
        XCTAssertEqual(status.stagedFiles.count, 3)

        // Unstage all files
        try await stagingManager.unstageFiles(["file1.txt", "file2.txt", "file3.txt"])

        // Verify all files are unstaged
        status = try await stagingManager.getStagingStatus()
        XCTAssertEqual(status.stagedFiles.count, 0)
    }

    func testStageAllFiles() async throws {
        // Create multiple files
        createTestFile(named: "file1.txt")
        createTestFile(named: "file2.txt")
        createTestFile(named: "file3.txt")

        // Stage all files
        try await stagingManager.stageAllFiles()

        // Verify all files are staged
        let status = try await stagingManager.getStagingStatus()
        XCTAssertEqual(status.stagedFiles.count, 3)
        XCTAssertTrue(status.hasStagedChanges)
    }

    func testUnstageAllFiles() async throws {
        // Create and stage multiple files
        createTestFile(named: "file1.txt")
        createTestFile(named: "file2.txt")
        createTestFile(named: "file3.txt")

        try await stagingManager.stageAllFiles()

        // Verify files are staged
        var status = try await stagingManager.getStagingStatus()
        XCTAssertEqual(status.stagedFiles.count, 3)

        // Unstage all files
        try await stagingManager.unstageAllFiles()

        // Verify all files are unstaged
        status = try await stagingManager.getStagingStatus()
        XCTAssertEqual(status.stagedFiles.count, 0)
    }

    // MARK: - Status-based Operations Tests

    func testStageAllModifiedFiles() async throws {
        // Create and commit a file first
        createTestFile(named: "test.txt", content: "initial content")
        try await stagingManager.stageFile("test.txt")

        // Commit the file
        let commitProcess = Process()
        commitProcess.executableURL = URL(fileURLWithPath: "/usr/bin/git")
        commitProcess.arguments = ["commit", "-m", "Initial commit"]
        commitProcess.currentDirectoryURL = tempRepositoryURL
        try commitProcess.run()
        commitProcess.waitUntilExit()

        // Modify the file
        modifyTestFile(named: "test.txt", content: "modified content")

        // Stage all modified files
        try await stagingManager.stageAllModifiedFiles()

        // Verify the modified file is staged
        let status = try await stagingManager.getStagingStatus()
        XCTAssertTrue(status.stagedFiles.contains { $0.filePath == "test.txt" })
    }

    func testStageAllUntrackedFiles() async throws {
        // Create multiple untracked files
        createTestFile(named: "untracked1.txt")
        createTestFile(named: "untracked2.txt")
        createTestFile(named: "untracked3.txt")

        // Stage all untracked files
        try await stagingManager.stageAllUntrackedFiles()

        // Verify all untracked files are staged
        let status = try await stagingManager.getStagingStatus()
        XCTAssertEqual(status.stagedFiles.count, 3)
        XCTAssertTrue(status.stagedFiles.contains { $0.filePath == "untracked1.txt" })
        XCTAssertTrue(status.stagedFiles.contains { $0.filePath == "untracked2.txt" })
        XCTAssertTrue(status.stagedFiles.contains { $0.filePath == "untracked3.txt" })
    }

    // MARK: - Status Query Tests

    func testGetStagingStatus() async throws {
        // Create files in different states
        createTestFile(named: "staged.txt")
        createTestFile(named: "untracked.txt")

        // Stage one file
        try await stagingManager.stageFile("staged.txt")

        // Get status
        let status = try await stagingManager.getStagingStatus()

        // Verify status information
        XCTAssertTrue(status.hasStagedChanges)
        XCTAssertTrue(status.hasChangesToStage)
        XCTAssertEqual(status.stagedFiles.count, 1)
        XCTAssertEqual(status.untrackedFiles.count, 1)
        XCTAssertEqual(status.totalChangedFiles, 2)
    }

    func testHasStagedChanges() async throws {
        // Initially no staged changes
        let initialHasStagedChanges = try await stagingManager.hasStagedChanges()
        XCTAssertFalse(initialHasStagedChanges)

        // Create and stage a file
        createTestFile(named: "test.txt")
        try await stagingManager.stageFile("test.txt")

        // Now should have staged changes
        let finalHasStagedChanges = try await stagingManager.hasStagedChanges()
        XCTAssertTrue(finalHasStagedChanges)
    }

    func testHasUnstagedChanges() async throws {
        // Create a file (untracked = unstaged)
        createTestFile(named: "test.txt")

        // Should have unstaged changes
        let initialHasUnstagedChanges = try await stagingManager.hasUnstagedChanges()
        XCTAssertTrue(initialHasUnstagedChanges)

        // Stage the file
        try await stagingManager.stageFile("test.txt")

        // Should not have unstaged changes
        let finalHasUnstagedChanges = try await stagingManager.hasUnstagedChanges()
        XCTAssertFalse(finalHasUnstagedChanges)
    }

    // MARK: - Error Handling Tests

    func testStageNonExistentFile() async throws {
        // Try to stage a file that doesn't exist
        do {
            try await stagingManager.stageFile("nonexistent.txt")
            XCTFail("Should have thrown an error")
        } catch {
            // Expected to throw an error
            XCTAssertTrue(error is GitError)
        }
    }

    func testUnstageNonExistentFile() async throws {
        // Try to unstage a file that doesn't exist
        do {
            try await stagingManager.unstageFile("nonexistent.txt")
            XCTFail("Should have thrown an error")
        } catch {
            // Expected to throw an error
            XCTAssertTrue(error is GitError)
        }
    }

    // MARK: - Performance Tests

    func testStagingPerformanceWithManyFiles() async throws {
        // Create many files
        let fileCount = 100
        var filePaths: [String] = []

        for i in 0..<fileCount {
            let fileName = "file\(i).txt"
            createTestFile(named: fileName)
            filePaths.append(fileName)
        }

        // Measure staging performance
        let startTime = Date()
        try await stagingManager.stageFiles(filePaths)
        let endTime = Date()

        let duration = endTime.timeIntervalSince(startTime)
        print("Staging \(fileCount) files took \(duration) seconds")

        // Should complete within reasonable time (10 seconds)
        XCTAssertLessThan(duration, 10.0)

        // Verify all files are staged
        let status = try await stagingManager.getStagingStatus()
        XCTAssertEqual(status.stagedFiles.count, fileCount)
    }
}
