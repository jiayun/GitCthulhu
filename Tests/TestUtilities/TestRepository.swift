//
// TestRepository.swift
// GitCthulhu
//
// Created by GitCthulhu Team on 2025-07-15.
//

import Foundation
import GitCore
import Utilities

/// Test utility for creating and managing test Git repositories
@MainActor
public class TestRepository {
    public let url: URL
    public let name: String
    private let fileManager = FileManager.default
    private let logger = Logger(category: "TestRepository")
    
    public init(name: String? = nil) throws {
        self.name = name ?? "test-repo-\(UUID().uuidString.prefix(8))"
        self.url = fileManager.temporaryDirectory.appendingPathComponent(self.name)
        
        try createTestRepository()
    }
    
    /// Create a test repository with initial structure
    private func createTestRepository() throws {
        // Create repository directory
        try fileManager.createDirectory(at: url, withIntermediateDirectories: true)
        
        // Initialize git repository
        let gitInit = Process()
        gitInit.executableURL = URL(fileURLWithPath: "/usr/bin/git")
        gitInit.arguments = ["init"]
        gitInit.currentDirectoryURL = url
        try gitInit.run()
        gitInit.waitUntilExit()
        
        // Configure git user for testing
        try configureGitUser()
        
        // Create initial commit
        try createInitialCommit()
        
        logger.info("Created test repository at: \(url.path)")
    }
    
    private func configureGitUser() throws {
        let commands = [
            ["config", "user.name", "Test User"],
            ["config", "user.email", "test@example.com"]
        ]
        
        for args in commands {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/git")
            process.arguments = args
            process.currentDirectoryURL = url
            try process.run()
            process.waitUntilExit()
        }
    }
    
    private func createInitialCommit() throws {
        // Create initial file
        let readmeURL = url.appendingPathComponent("README.md")
        let content = "# \(name)\n\nTest repository for integration testing."
        try content.write(to: readmeURL, atomically: true, encoding: .utf8)
        
        // Stage and commit
        try executeGitCommand(["add", "README.md"])
        try executeGitCommand(["commit", "-m", "Initial commit"])
    }
    
    /// Execute a git command in the test repository
    private func executeGitCommand(_ arguments: [String]) throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/git")
        process.arguments = arguments
        process.currentDirectoryURL = url
        try process.run()
        process.waitUntilExit()
        
        guard process.terminationStatus == 0 else {
            throw TestRepositoryError.gitCommandFailed(arguments.joined(separator: " "))
        }
    }
    
    // MARK: - File Management
    
    /// Create a file with specified content
    public func createFile(name: String, content: String) throws {
        let fileURL = url.appendingPathComponent(name)
        try content.write(to: fileURL, atomically: true, encoding: .utf8)
        logger.info("Created file: \(name)")
    }
    
    /// Modify an existing file
    public func modifyFile(name: String, content: String) throws {
        let fileURL = url.appendingPathComponent(name)
        try content.write(to: fileURL, atomically: true, encoding: .utf8)
        logger.info("Modified file: \(name)")
    }
    
    /// Delete a file
    public func deleteFile(name: String) throws {
        let fileURL = url.appendingPathComponent(name)
        try fileManager.removeItem(at: fileURL)
        logger.info("Deleted file: \(name)")
    }
    
    // MARK: - Git Operations
    
    /// Stage a file
    public func stageFile(_ fileName: String) throws {
        try executeGitCommand(["add", fileName])
        logger.info("Staged file: \(fileName)")
    }
    
    /// Unstage a file
    public func unstageFile(_ fileName: String) throws {
        try executeGitCommand(["restore", "--staged", fileName])
        logger.info("Unstaged file: \(fileName)")
    }
    
    /// Commit changes
    public func commit(message: String) throws {
        try executeGitCommand(["commit", "-m", message])
        logger.info("Committed with message: \(message)")
    }
    
    /// Create a new branch
    public func createBranch(_ name: String) throws {
        try executeGitCommand(["branch", name])
        logger.info("Created branch: \(name)")
    }
    
    /// Switch to a branch
    public func switchBranch(_ name: String) throws {
        try executeGitCommand(["checkout", name])
        logger.info("Switched to branch: \(name)")
    }
    
    // MARK: - Large Repository Generation
    
    /// Generate a large repository with many files for performance testing
    public func generateLargeRepository(fileCount: Int = 1000) throws {
        logger.info("Generating large repository with \(fileCount) files")
        
        // Create files in batches to avoid overwhelming the system
        let batchSize = 50
        for batchStart in stride(from: 0, to: fileCount, by: batchSize) {
            let batchEnd = min(batchStart + batchSize, fileCount)
            
            for i in batchStart..<batchEnd {
                let fileName = "file_\(String(format: "%04d", i)).txt"
                let content = "This is test file \(i)\n" + String(repeating: "content ", count: i % 100)
                try createFile(name: fileName, content: content)
            }
            
            // Stage and commit batch
            try executeGitCommand(["add", "."])
            try executeGitCommand(["commit", "-m", "Add batch \(batchStart/batchSize + 1) of files"])
        }
        
        logger.info("Generated large repository with \(fileCount) files")
    }
    
    /// Create files with various statuses for testing
    public func createFilesWithVariousStatuses() throws {
        // Untracked file
        try createFile(name: "untracked.txt", content: "Untracked file")
        
        // Modified file
        try modifyFile(name: "README.md", content: "# Modified README\n\nThis file has been modified.")
        
        // Staged file
        try createFile(name: "staged.txt", content: "Staged file")
        try stageFile("staged.txt")
        
        // Staged and modified file
        try createFile(name: "staged_modified.txt", content: "Original content")
        try stageFile("staged_modified.txt")
        try modifyFile(name: "staged_modified.txt", content: "Modified after staging")
        
        // Deleted file
        try createFile(name: "to_delete.txt", content: "Will be deleted")
        try stageFile("to_delete.txt")
        try commit(message: "Add file to delete")
        try deleteFile(name: "to_delete.txt")
        
        logger.info("Created files with various statuses")
    }
    
    // MARK: - Cleanup
    
    /// Clean up the test repository
    public func cleanup() throws {
        try fileManager.removeItem(at: url)
        logger.info("Cleaned up test repository at: \(url.path)")
    }
    
    deinit {
        try? cleanup()
    }
}

// MARK: - TestRepositoryError

public enum TestRepositoryError: Error, LocalizedError {
    case gitCommandFailed(String)
    case fileOperationFailed(String)
    
    public var errorDescription: String? {
        switch self {
        case let .gitCommandFailed(command):
            return "Git command failed: \(command)"
        case let .fileOperationFailed(operation):
            return "File operation failed: \(operation)"
        }
    }
}