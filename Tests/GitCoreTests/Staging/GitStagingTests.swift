//
// GitStagingTests.swift
// GitCthulhu
//
// Created by GitCthulhu Team on 2025-07-15.
//

import Foundation
@testable import GitCore
import Testing

struct GitStagingTests {
    
    // MARK: - Test Setup Helper
    
    @MainActor
    private func createTestRepository() async throws -> GitRepository {
        let currentDir = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        return try await GitRepository.create(url: currentDir)
    }
    
    private func createTestStagingManager() async throws -> GitStagingManager {
        let repository = try await createTestRepository()
        return GitStagingManager(repository: repository)
    }
    
    // MARK: - Initialization Tests
    
    @MainActor
    @Test("GitStagingManager initialization")
    func gitStagingManagerInitialization() async throws {
        let repository = try await createTestRepository()
        let stagingManager = GitStagingManager(repository: repository)
        
        #expect(stagingManager.repository === repository)
    }
    
    // MARK: - Single File Staging Tests
    
    @MainActor
    @Test("Stage single file - valid file")
    func stageSingleFileValid() async throws {
        let stagingManager = try await createTestStagingManager()
        
        // Create a test file
        let testFile = "test-staging-file.txt"
        let testFilePath = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent(testFile)
        
        try "Test content".write(to: testFilePath, atomically: true, encoding: .utf8)
        defer {
            try? FileManager.default.removeItem(at: testFilePath)
        }
        
        // Stage the file
        try await stagingManager.stageFile(testFile)
        
        // Verify file is staged
        let isStaged = try await stagingManager.isFileStaged(testFile)
        #expect(isStaged == true)
        
        // Clean up - unstage the file
        try await stagingManager.unstageFile(testFile)
    }
    
    @MainActor
    @Test("Stage single file - invalid file")
    func stageSingleFileInvalid() async throws {
        let stagingManager = try await createTestStagingManager()
        
        let nonExistentFile = "non-existent-file-\(UUID().uuidString).txt"
        
        // Staging a non-existent file should fail
        await #expect(throws: GitError.self) {
            try await stagingManager.stageFile(nonExistentFile)
        }
    }
    
    @MainActor
    @Test("Unstage single file - valid file")
    func unstageSingleFileValid() async throws {
        let stagingManager = try await createTestStagingManager()
        
        // Create and stage a test file
        let testFile = "test-unstaging-file.txt"
        let testFilePath = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent(testFile)
        
        try "Test content".write(to: testFilePath, atomically: true, encoding: .utf8)
        defer {
            try? FileManager.default.removeItem(at: testFilePath)
        }
        
        // Stage the file first
        try await stagingManager.stageFile(testFile)
        
        // Verify file is staged
        let isStaged = try await stagingManager.isFileStaged(testFile)
        #expect(isStaged == true)
        
        // Unstage the file
        try await stagingManager.unstageFile(testFile)
        
        // Verify file is no longer staged
        let isUnstaged = try await stagingManager.isFileStaged(testFile)
        #expect(isUnstaged == false)
    }
    
    // MARK: - Batch Operations Tests
    
    @MainActor
    @Test("Stage multiple files")
    func stageMultipleFiles() async throws {
        let stagingManager = try await createTestStagingManager()
        
        // Create multiple test files
        let testFiles = ["batch-test-1.txt", "batch-test-2.txt", "batch-test-3.txt"]
        let testFilePaths = testFiles.map { fileName in
            URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
                .appendingPathComponent(fileName)
        }
        
        // Create files
        for (index, filePath) in testFilePaths.enumerated() {
            try "Test content \(index)".write(to: filePath, atomically: true, encoding: .utf8)
        }
        
        defer {
            // Clean up
            for filePath in testFilePaths {
                try? FileManager.default.removeItem(at: filePath)
            }
        }
        
        // Stage all files
        try await stagingManager.stageFiles(testFiles)
        
        // Verify all files are staged
        for testFile in testFiles {
            let isStaged = try await stagingManager.isFileStaged(testFile)
            #expect(isStaged == true)
        }
        
        // Clean up - unstage all files
        try await stagingManager.unstageFiles(testFiles)
    }
    
    @MainActor
    @Test("Unstage multiple files")
    func unstageMultipleFiles() async throws {
        let stagingManager = try await createTestStagingManager()
        
        // Create multiple test files
        let testFiles = ["batch-unstage-1.txt", "batch-unstage-2.txt"]
        let testFilePaths = testFiles.map { fileName in
            URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
                .appendingPathComponent(fileName)
        }
        
        // Create files
        for (index, filePath) in testFilePaths.enumerated() {
            try "Test content \(index)".write(to: filePath, atomically: true, encoding: .utf8)
        }
        
        defer {
            // Clean up
            for filePath in testFilePaths {
                try? FileManager.default.removeItem(at: filePath)
            }
        }
        
        // Stage all files first
        try await stagingManager.stageFiles(testFiles)
        
        // Verify all files are staged
        for testFile in testFiles {
            let isStaged = try await stagingManager.isFileStaged(testFile)
            #expect(isStaged == true)
        }
        
        // Unstage all files
        try await stagingManager.unstageFiles(testFiles)
        
        // Verify all files are no longer staged
        for testFile in testFiles {
            let isStaged = try await stagingManager.isFileStaged(testFile)
            #expect(isStaged == false)
        }
    }
    
    @MainActor
    @Test("Stage empty file array")
    func stageEmptyFileArray() async throws {
        let stagingManager = try await createTestStagingManager()
        
        // Staging empty array should not throw
        try await stagingManager.stageFiles([])
        
        #expect(true) // If we get here, no exception was thrown
    }
    
    @MainActor
    @Test("Unstage empty file array")
    func unstageEmptyFileArray() async throws {
        let stagingManager = try await createTestStagingManager()
        
        // Unstaging empty array should not throw
        try await stagingManager.unstageFiles([])
        
        #expect(true) // If we get here, no exception was thrown
    }
    
    // MARK: - Status Operation Tests
    
    @MainActor
    @Test("Get staging status")
    func getStagingStatus() async throws {
        let stagingManager = try await createTestStagingManager()
        
        // Should not throw
        let status = try await stagingManager.getStagingStatus()
        
        // Status should be a dictionary
        #expect(status is [String: GitFileStatus])
    }
    
    @MainActor
    @Test("Get staged files")
    func getStagedFiles() async throws {
        let stagingManager = try await createTestStagingManager()
        
        // Should not throw
        let stagedFiles = try await stagingManager.getStagedFiles()
        
        // Should return an array
        #expect(stagedFiles is [String])
    }
    
    @MainActor
    @Test("Get unstaged files")
    func getUnstagedFiles() async throws {
        let stagingManager = try await createTestStagingManager()
        
        // Should not throw
        let unstagedFiles = try await stagingManager.getUnstagedFiles()
        
        // Should return an array
        #expect(unstagedFiles is [String])
    }
    
    @MainActor
    @Test("Check if file is staged")
    func checkIfFileIsStaged() async throws {
        let stagingManager = try await createTestStagingManager()
        
        // Create a test file
        let testFile = "staged-check-test.txt"
        let testFilePath = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent(testFile)
        
        try "Test content".write(to: testFilePath, atomically: true, encoding: .utf8)
        defer {
            try? FileManager.default.removeItem(at: testFilePath)
        }
        
        // Initially should not be staged
        let initiallyStaged = try await stagingManager.isFileStaged(testFile)
        #expect(initiallyStaged == false)
        
        // Stage the file
        try await stagingManager.stageFile(testFile)
        
        // Should now be staged
        let afterStaging = try await stagingManager.isFileStaged(testFile)
        #expect(afterStaging == true)
        
        // Clean up
        try await stagingManager.unstageFile(testFile)
    }
    
    // MARK: - Convenience Methods Tests
    
    @MainActor
    @Test("Stage files by status")
    func stageFilesByStatus() async throws {
        let stagingManager = try await createTestStagingManager()
        
        // This should not throw even if no files match the status
        try await stagingManager.stageFilesByStatus(.modified)
        
        #expect(true) // If we get here, no exception was thrown
    }
    
    @MainActor
    @Test("Get staging statistics")
    func getStagingStatistics() async throws {
        let stagingManager = try await createTestStagingManager()
        
        let stats = try await stagingManager.getStagingStatistics()
        
        // Should return valid statistics
        #expect(stats.staged >= 0)
        #expect(stats.unstaged >= 0)
        #expect(stats.untracked >= 0)
    }
    
    // MARK: - Error Handling Tests
    
    @MainActor
    @Test("Handle invalid file path")
    func handleInvalidFilePath() async throws {
        let stagingManager = try await createTestStagingManager()
        
        // Test with invalid characters
        let invalidPath = "invalid/path/with/\0/null/character"
        
        await #expect(throws: GitError.self) {
            try await stagingManager.stageFile(invalidPath)
        }
    }
    
    @MainActor
    @Test("Handle staging non-existent file")
    func handleStagingNonExistentFile() async throws {
        let stagingManager = try await createTestStagingManager()
        
        let nonExistentFile = "absolutely-does-not-exist-\(UUID().uuidString).txt"
        
        await #expect(throws: GitError.self) {
            try await stagingManager.stageFile(nonExistentFile)
        }
    }
    
    @MainActor
    @Test("Handle unstaging non-staged file")
    func handleUnstagingNonStagedFile() async throws {
        let stagingManager = try await createTestStagingManager()
        
        // Create a file but don't stage it
        let testFile = "unstage-non-staged-test.txt"
        let testFilePath = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent(testFile)
        
        try "Test content".write(to: testFilePath, atomically: true, encoding: .utf8)
        defer {
            try? FileManager.default.removeItem(at: testFilePath)
        }
        
        // Unstaging a non-staged file should not throw (git reset HEAD succeeds)
        try await stagingManager.unstageFile(testFile)
        
        #expect(true) // If we get here, no exception was thrown
    }
    
    // MARK: - Integration Tests
    
    @MainActor
    @Test("Complete staging workflow")
    func completeStagingWorkflow() async throws {
        let stagingManager = try await createTestStagingManager()
        
        // Create multiple test files
        let testFiles = ["workflow-1.txt", "workflow-2.txt", "workflow-3.txt"]
        let testFilePaths = testFiles.map { fileName in
            URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
                .appendingPathComponent(fileName)
        }
        
        // Create files
        for (index, filePath) in testFilePaths.enumerated() {
            try "Workflow test content \(index)".write(to: filePath, atomically: true, encoding: .utf8)
        }
        
        defer {
            // Clean up
            for filePath in testFilePaths {
                try? FileManager.default.removeItem(at: filePath)
            }
        }
        
        // 1. Stage individual files
        try await stagingManager.stageFile(testFiles[0])
        
        // 2. Stage multiple files
        try await stagingManager.stageFiles(Array(testFiles[1...]))
        
        // 3. Verify all files are staged
        for testFile in testFiles {
            let isStaged = try await stagingManager.isFileStaged(testFile)
            #expect(isStaged == true)
        }
        
        // 4. Get staging statistics
        let stats = try await stagingManager.getStagingStatistics()
        #expect(stats.staged >= testFiles.count)
        
        // 5. Unstage some files
        try await stagingManager.unstageFile(testFiles[0])
        
        // 6. Verify selective unstaging
        let firstFileStaged = try await stagingManager.isFileStaged(testFiles[0])
        #expect(firstFileStaged == false)
        
        let secondFileStaged = try await stagingManager.isFileStaged(testFiles[1])
        #expect(secondFileStaged == true)
        
        // 7. Unstage all remaining files
        try await stagingManager.unstageFiles(Array(testFiles[1...]))
        
        // 8. Verify all files are unstaged
        for testFile in testFiles {
            let isStaged = try await stagingManager.isFileStaged(testFile)
            #expect(isStaged == false)
        }
    }
    
    // MARK: - Performance Tests
    
    @MainActor
    @Test("Concurrent staging operations")
    func concurrentStagingOperations() async throws {
        let stagingManager = try await createTestStagingManager()
        
        // Create multiple test files
        let testFiles = ["concurrent-1.txt", "concurrent-2.txt", "concurrent-3.txt"]
        let testFilePaths = testFiles.map { fileName in
            URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
                .appendingPathComponent(fileName)
        }
        
        // Create files
        for (index, filePath) in testFilePaths.enumerated() {
            try "Concurrent test content \(index)".write(to: filePath, atomically: true, encoding: .utf8)
        }
        
        defer {
            // Clean up
            for filePath in testFilePaths {
                try? FileManager.default.removeItem(at: filePath)
            }
        }
        
        // Run multiple operations concurrently
        async let status = stagingManager.getStagingStatus()
        async let stagedFiles = stagingManager.getStagedFiles()
        async let unstagedFiles = stagingManager.getUnstagedFiles()
        async let stats = stagingManager.getStagingStatistics()
        
        let results = try await (status, stagedFiles, unstagedFiles, stats)
        
        // Verify all operations completed successfully
        #expect(results.0 is [String: GitFileStatus])
        #expect(results.1 is [String])
        #expect(results.2 is [String])
        #expect(results.3.staged >= 0)
        #expect(results.3.unstaged >= 0)
        #expect(results.3.untracked >= 0)
        
        // Clean up - try to unstage any files that might have been staged
        try? await stagingManager.unstageFiles(testFiles)
    }
}