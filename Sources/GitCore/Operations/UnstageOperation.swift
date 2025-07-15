//
// UnstageOperation.swift
// GitCthulhu
//
// Created by GitCthulhu Team on 2025-07-15.
//

import Foundation
import Utilities

/// Operation for unstaging files in a Git repository
public class UnstageOperation {
    private let gitExecutor: GitCommandExecutor
    private let logger = Logger(category: "UnstageOperation")
    
    /// Initialize unstage operation with a git command executor
    /// - Parameter gitExecutor: The git command executor to use
    public init(gitExecutor: GitCommandExecutor) {
        self.gitExecutor = gitExecutor
    }
    
    // MARK: - Single File Operations
    
    /// Unstages a single file
    /// - Parameter filePath: The relative path to the file to unstage
    /// - Throws: GitError if the unstaging operation fails
    public func unstageFile(_ filePath: String) async throws {
        logger.debug("Unstaging file: \(filePath)")
        
        do {
            let sanitizedPath = try GitInputValidator.sanitizeFilePath(filePath)
            try await gitExecutor.execute(["reset", "HEAD", sanitizedPath])
            logger.info("Successfully unstaged file: \(filePath)")
        } catch {
            logger.error("Failed to unstage file \(filePath): \(error.localizedDescription)")
            throw GitError.unstagingFailed("Failed to unstage file \(filePath): \(error.localizedDescription)")
        }
    }
    
    // MARK: - Batch Operations
    
    /// Unstages multiple files
    /// - Parameter filePaths: Array of relative paths to files to unstage
    /// - Throws: GitError if any unstaging operation fails
    public func unstageFiles(_ filePaths: [String]) async throws {
        guard !filePaths.isEmpty else {
            logger.warning("No files provided for unstaging")
            return
        }
        
        logger.debug("Unstaging \(filePaths.count) files")
        
        do {
            let sanitizedPaths = try filePaths.map { try GitInputValidator.sanitizeFilePath($0) }
            let args = ["reset", "HEAD"] + sanitizedPaths
            try await gitExecutor.execute(args)
            logger.info("Successfully unstaged \(filePaths.count) files")
        } catch {
            logger.error("Failed to unstage files: \(error.localizedDescription)")
            throw GitError.unstagingFailed("Failed to unstage files: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Bulk Operations
    
    /// Unstages all staged files
    /// - Throws: GitError if the unstaging operation fails
    public func unstageAll() async throws {
        logger.debug("Unstaging all files")
        
        do {
            try await gitExecutor.execute(["reset", "HEAD"])
            logger.info("Successfully unstaged all files")
        } catch {
            logger.error("Failed to unstage all files: \(error.localizedDescription)")
            throw GitError.unstagingFailed("Failed to unstage all files: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Status Operations
    
    /// Gets list of unstaged files (modified but not staged)
    /// - Returns: Array of relative paths to unstaged files
    /// - Throws: GitError if unable to get unstaged files
    public func getUnstagedFiles() async throws -> [String] {
        logger.debug("Getting unstaged files")
        
        do {
            let output = try await gitExecutor.execute(["diff", "--name-only"])
            let unstagedFiles = output.components(separatedBy: .newlines)
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
            
            logger.info("Found \(unstagedFiles.count) unstaged files")
            return unstagedFiles
        } catch {
            logger.error("Failed to get unstaged files: \(error.localizedDescription)")
            throw GitError.statusFailed("Failed to get unstaged files: \(error.localizedDescription)")
        }
    }
    
    /// Checks if a file is unstaged (modified but not staged)
    /// - Parameter filePath: The relative path to the file
    /// - Returns: True if the file is unstaged, false otherwise
    /// - Throws: GitError if unable to check status
    public func isFileUnstaged(_ filePath: String) async throws -> Bool {
        logger.debug("Checking if file is unstaged: \(filePath)")
        
        do {
            let sanitizedPath = try GitInputValidator.sanitizeFilePath(filePath)
            let output = try await gitExecutor.execute(["diff", "--name-only", sanitizedPath])
            let isUnstaged = !output.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            
            logger.debug("File \(filePath) unstaged status: \(isUnstaged)")
            return isUnstaged
        } catch {
            logger.error("Failed to check if file is unstaged \(filePath): \(error.localizedDescription)")
            throw GitError.statusFailed("Failed to check if file is unstaged \(filePath): \(error.localizedDescription)")
        }
    }
}