//
// StageOperation.swift
// GitCthulhu
//
// Created by GitCthulhu Team on 2025-07-15.
//

import Foundation
import Utilities

/// Operation for staging files in a Git repository
public class StageOperation {
    private let gitExecutor: GitCommandExecutor
    private let logger = Logger(category: "StageOperation")
    
    /// Initialize stage operation with a git command executor
    /// - Parameter gitExecutor: The git command executor to use
    public init(gitExecutor: GitCommandExecutor) {
        self.gitExecutor = gitExecutor
    }
    
    // MARK: - Single File Operations
    
    /// Stages a single file
    /// - Parameter filePath: The relative path to the file to stage
    /// - Throws: GitError if the staging operation fails
    public func stageFile(_ filePath: String) async throws {
        logger.debug("Staging file: \(filePath)")
        
        do {
            let sanitizedPath = try GitInputValidator.sanitizeFilePath(filePath)
            try await gitExecutor.execute(["add", sanitizedPath])
            logger.info("Successfully staged file: \(filePath)")
        } catch {
            logger.error("Failed to stage file \(filePath): \(error.localizedDescription)")
            throw GitError.stagingFailed("Failed to stage file \(filePath): \(error.localizedDescription)")
        }
    }
    
    // MARK: - Batch Operations
    
    /// Stages multiple files
    /// - Parameter filePaths: Array of relative paths to files to stage
    /// - Throws: GitError if any staging operation fails
    public func stageFiles(_ filePaths: [String]) async throws {
        guard !filePaths.isEmpty else {
            logger.warning("No files provided for staging")
            return
        }
        
        logger.debug("Staging \(filePaths.count) files")
        
        do {
            let sanitizedPaths = try filePaths.map { try GitInputValidator.sanitizeFilePath($0) }
            let args = ["add"] + sanitizedPaths
            try await gitExecutor.execute(args)
            logger.info("Successfully staged \(filePaths.count) files")
        } catch {
            logger.error("Failed to stage files: \(error.localizedDescription)")
            throw GitError.stagingFailed("Failed to stage files: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Bulk Operations
    
    /// Stages all modified and untracked files
    /// - Throws: GitError if the staging operation fails
    public func stageAll() async throws {
        logger.debug("Staging all files")
        
        do {
            try await gitExecutor.execute(["add", "."])
            logger.info("Successfully staged all files")
        } catch {
            logger.error("Failed to stage all files: \(error.localizedDescription)")
            throw GitError.stagingFailed("Failed to stage all files: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Status Operations
    
    /// Gets list of staged files
    /// - Returns: Array of relative paths to staged files
    /// - Throws: GitError if unable to get staged files
    public func getStagedFiles() async throws -> [String] {
        logger.debug("Getting staged files")
        
        do {
            let output = try await gitExecutor.execute(["diff", "--cached", "--name-only"])
            let stagedFiles = output.components(separatedBy: .newlines)
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
            
            logger.info("Found \(stagedFiles.count) staged files")
            return stagedFiles
        } catch {
            logger.error("Failed to get staged files: \(error.localizedDescription)")
            throw GitError.statusFailed("Failed to get staged files: \(error.localizedDescription)")
        }
    }
    
    /// Checks if a file is staged
    /// - Parameter filePath: The relative path to the file
    /// - Returns: True if the file is staged, false otherwise
    /// - Throws: GitError if unable to check status
    public func isFileStaged(_ filePath: String) async throws -> Bool {
        logger.debug("Checking if file is staged: \(filePath)")
        
        do {
            let sanitizedPath = try GitInputValidator.sanitizeFilePath(filePath)
            let output = try await gitExecutor.execute(["diff", "--cached", "--name-only", sanitizedPath])
            let isStaged = !output.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            
            logger.debug("File \(filePath) staged status: \(isStaged)")
            return isStaged
        } catch {
            logger.error("Failed to check if file is staged \(filePath): \(error.localizedDescription)")
            throw GitError.statusFailed("Failed to check if file is staged \(filePath): \(error.localizedDescription)")
        }
    }
}