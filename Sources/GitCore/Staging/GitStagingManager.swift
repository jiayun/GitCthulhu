//
// GitStagingManager.swift
// GitCthulhu
//
// Created by GitCthulhu Team on 2025-07-15.
//

import Foundation
import Utilities

/// Main implementation of Git staging operations
@MainActor
public class GitStagingManager: GitStagingProtocol {
    public let repository: GitRepository
    
    private let gitExecutor: GitCommandExecutor
    private let stageOperation: StageOperation
    private let unstageOperation: UnstageOperation
    private let logger = Logger(category: "GitStagingManager")
    
    /// Initialize with a Git repository
    /// - Parameter repository: The Git repository to operate on
    public init(repository: GitRepository) {
        self.repository = repository
        self.gitExecutor = GitCommandExecutor(repositoryURL: repository.url)
        self.stageOperation = StageOperation(gitExecutor: gitExecutor)
        self.unstageOperation = UnstageOperation(gitExecutor: gitExecutor)
    }
    
    // MARK: - Single File Operations
    
    /// Stages a single file for commit
    /// - Parameter path: The relative path to the file to stage
    /// - Throws: GitError if the staging operation fails
    public func stageFile(_ path: String) async throws {
        logger.debug("Staging single file: \(path)")
        
        try await stageOperation.stageFile(path)
        
        // Refresh repository status after staging
        await repository.refreshStatus()
        
        logger.info("Successfully staged file: \(path)")
    }
    
    /// Unstages a single file
    /// - Parameter path: The relative path to the file to unstage
    /// - Throws: GitError if the unstaging operation fails
    public func unstageFile(_ path: String) async throws {
        logger.debug("Unstaging single file: \(path)")
        
        try await unstageOperation.unstageFile(path)
        
        // Refresh repository status after unstaging
        await repository.refreshStatus()
        
        logger.info("Successfully unstaged file: \(path)")
    }
    
    // MARK: - Batch Operations
    
    /// Stages multiple files for commit
    /// - Parameter paths: Array of relative paths to files to stage
    /// - Throws: GitError if any staging operation fails
    public func stageFiles(_ paths: [String]) async throws {
        guard !paths.isEmpty else {
            logger.warning("No files provided for staging")
            return
        }
        
        logger.debug("Staging \(paths.count) files")
        
        try await stageOperation.stageFiles(paths)
        
        // Refresh repository status after staging
        await repository.refreshStatus()
        
        logger.info("Successfully staged \(paths.count) files")
    }
    
    /// Unstages multiple files
    /// - Parameter paths: Array of relative paths to files to unstage
    /// - Throws: GitError if any unstaging operation fails
    public func unstageFiles(_ paths: [String]) async throws {
        guard !paths.isEmpty else {
            logger.warning("No files provided for unstaging")
            return
        }
        
        logger.debug("Unstaging \(paths.count) files")
        
        try await unstageOperation.unstageFiles(paths)
        
        // Refresh repository status after unstaging
        await repository.refreshStatus()
        
        logger.info("Successfully unstaged \(paths.count) files")
    }
    
    // MARK: - Bulk Operations
    
    /// Stages all modified and untracked files
    /// - Throws: GitError if the staging operation fails
    public func stageAll() async throws {
        logger.debug("Staging all files")
        
        try await stageOperation.stageAll()
        
        // Refresh repository status after staging
        await repository.refreshStatus()
        
        logger.info("Successfully staged all files")
    }
    
    /// Unstages all staged files
    /// - Throws: GitError if the unstaging operation fails
    public func unstageAll() async throws {
        logger.debug("Unstaging all files")
        
        try await unstageOperation.unstageAll()
        
        // Refresh repository status after unstaging
        await repository.refreshStatus()
        
        logger.info("Successfully unstaged all files")
    }
    
    // MARK: - Status Operations
    
    /// Gets the current staging status
    /// - Returns: Dictionary mapping file paths to their staging status
    /// - Throws: GitError if unable to get status
    public func getStagingStatus() async throws -> [String: GitFileStatus] {
        logger.debug("Getting staging status")
        
        do {
            let status = try await repository.getRepositoryStatus()
            logger.info("Retrieved staging status for \(status.count) files")
            return status
        } catch {
            logger.error("Failed to get staging status: \(error.localizedDescription)")
            throw GitError.statusFailed("Failed to get staging status: \(error.localizedDescription)")
        }
    }
    
    /// Checks if a file is staged
    /// - Parameter path: The relative path to the file
    /// - Returns: True if the file is staged, false otherwise
    /// - Throws: GitError if unable to check status
    public func isFileStaged(_ path: String) async throws -> Bool {
        logger.debug("Checking if file is staged: \(path)")
        
        do {
            let isStaged = try await stageOperation.isFileStaged(path)
            logger.debug("File \(path) staged status: \(isStaged)")
            return isStaged
        } catch {
            logger.error("Failed to check if file is staged \(path): \(error.localizedDescription)")
            throw error
        }
    }
    
    /// Gets list of all staged files
    /// - Returns: Array of relative paths to staged files
    /// - Throws: GitError if unable to get staged files
    public func getStagedFiles() async throws -> [String] {
        logger.debug("Getting staged files")
        
        do {
            let stagedFiles = try await stageOperation.getStagedFiles()
            logger.info("Found \(stagedFiles.count) staged files")
            return stagedFiles
        } catch {
            logger.error("Failed to get staged files: \(error.localizedDescription)")
            throw error
        }
    }
    
    /// Gets list of all unstaged files
    /// - Returns: Array of relative paths to unstaged files
    /// - Throws: GitError if unable to get unstaged files
    public func getUnstagedFiles() async throws -> [String] {
        logger.debug("Getting unstaged files")
        
        do {
            let unstagedFiles = try await unstageOperation.getUnstagedFiles()
            logger.info("Found \(unstagedFiles.count) unstaged files")
            return unstagedFiles
        } catch {
            logger.error("Failed to get unstaged files: \(error.localizedDescription)")
            throw error
        }
    }
    
    // MARK: - Convenience Methods
    
    /// Stages files by their current status
    /// - Parameter status: The file status to stage (e.g., .modified, .untracked)
    /// - Throws: GitError if staging fails
    public func stageFilesByStatus(_ status: GitFileStatus) async throws {
        logger.debug("Staging files by status: \(status)")
        
        let allStatus = try await getStagingStatus()
        let filesToStage = allStatus.compactMap { path, fileStatus in
            fileStatus == status ? path : nil
        }
        
        guard !filesToStage.isEmpty else {
            logger.info("No files found with status: \(status)")
            return
        }
        
        try await stageFiles(filesToStage)
        logger.info("Successfully staged \(filesToStage.count) files with status: \(status)")
    }
    
    /// Gets staging statistics
    /// - Returns: Tuple with counts of staged, unstaged, and untracked files
    /// - Throws: GitError if unable to get statistics
    public func getStagingStatistics() async throws -> (staged: Int, unstaged: Int, untracked: Int) {
        logger.debug("Getting staging statistics")
        
        do {
            let status = try await getStagingStatus()
            var staged = 0
            var unstaged = 0
            var untracked = 0
            
            for (_, fileStatus) in status {
                switch fileStatus {
                case .added:
                    staged += 1
                case .modified:
                    unstaged += 1
                case .untracked:
                    untracked += 1
                default:
                    break
                }
            }
            
            // Also count staged files separately to get accurate count
            let stagedFiles = try await getStagedFiles()
            staged = stagedFiles.count
            
            let statistics = (staged: staged, unstaged: unstaged, untracked: untracked)
            logger.info("Staging statistics - Staged: \(staged), Unstaged: \(unstaged), Untracked: \(untracked)")
            return statistics
        } catch {
            logger.error("Failed to get staging statistics: \(error.localizedDescription)")
            throw GitError.statusFailed("Failed to get staging statistics: \(error.localizedDescription)")
        }
    }
}