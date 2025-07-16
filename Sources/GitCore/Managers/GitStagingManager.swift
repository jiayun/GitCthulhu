//
// GitStagingManager.swift
// GitCthulhu
//
// Created by GitCthulhu Team on 2025-07-16.
//

import Foundation
import Utilities

/// Manages Git staging operations with comprehensive support for stage/unstage operations
public class GitStagingManager {
    private let repositoryURL: URL
    private let gitExecutor: GitCommandExecutor
    private let statusManager: GitStatusManager
    private let logger = Logger(category: "GitStagingManager")

    public init(repositoryURL: URL) {
        self.repositoryURL = repositoryURL
        self.gitExecutor = GitCommandExecutor(repositoryURL: repositoryURL)
        self.statusManager = GitStatusManager(repositoryURL: repositoryURL)
    }

    // MARK: - Single File Operations

    /// Stages a single file
    public func stageFile(_ filePath: String) async throws {
        logger.debug("Staging file: \(filePath)")

        // Pre-validation: Check if file path is valid
        guard !filePath.isEmpty else {
            throw GitError.stagingFailed("File path cannot be empty")
        }

        // Check if file is already staged
        // Note: For files that come from directory expansion, getFileStatus might not find them
        // in the cache, so we use a more lenient approach here
        if let currentStatus = try? await statusManager.getFileStatus(filePath) {
            if currentStatus.isStaged {
                logger.info("File \(filePath) is already staged, skipping")
                return
            }
        } else {
            // File not found in status cache, this might be from directory expansion
            logger.debug("File \(filePath) not found in status cache, proceeding with staging")
        }

        do {
            try await gitExecutor.stageFile(filePath)

            // Invalidate status cache to ensure fresh data
            statusManager.invalidateCache()

            logger.info("Successfully staged file: \(filePath)")
        } catch let error as GitError {
            logger.error("Failed to stage file \(filePath): \(error.localizedDescription)")
            throw error
        } catch {
            logger.error("Failed to stage file \(filePath): \(error.localizedDescription)")
            throw GitError.stagingFailed("Failed to stage file \(filePath): \(error.localizedDescription)")
        }
    }

    /// Unstages a single file
    public func unstageFile(_ filePath: String) async throws {
        logger.debug("Unstaging file: \(filePath)")

        // Pre-validation: Check if file path is valid
        guard !filePath.isEmpty else {
            throw GitError.stagingFailed("File path cannot be empty")
        }

        // Check if file is already unstaged
        // Note: For files that come from directory expansion, getFileStatus might not find them
        // in the cache, so we use a more lenient approach here
        if let currentStatus = try? await statusManager.getFileStatus(filePath) {
            if !currentStatus.isStaged {
                logger.info("File \(filePath) is already unstaged, skipping")
                return
            }
        } else {
            // File not found in status cache, this might be from directory expansion
            logger.debug("File \(filePath) not found in status cache, proceeding with unstaging")
        }

        do {
            try await gitExecutor.unstageFile(filePath)

            // Invalidate status cache to ensure fresh data
            statusManager.invalidateCache()

            logger.info("Successfully unstaged file: \(filePath)")
        } catch let error as GitError {
            logger.error("Failed to unstage file \(filePath): \(error.localizedDescription)")
            throw error
        } catch {
            logger.error("Failed to unstage file \(filePath): \(error.localizedDescription)")
            throw GitError.stagingFailed("Failed to unstage file \(filePath): \(error.localizedDescription)")
        }
    }

    /// Toggles staging status of a file
    public func toggleFileStaging(_ filePath: String) async throws {
        // Get current status to determine action
        let statusEntry = try await statusManager.getFileStatus(filePath)

        guard let entry = statusEntry else {
            throw GitError.stagingFailed("File not found in repository status: \(filePath)")
        }

        if entry.isStaged {
            try await unstageFile(filePath)
        } else {
            try await stageFile(filePath)
        }
    }

    // MARK: - Batch Operations

    /// Stages multiple files
    public func stageFiles(_ filePaths: [String]) async throws {
        logger.debug("Staging \(filePaths.count) files")

        var failedFiles: [String] = []

        for filePath in filePaths {
            do {
                try await stageFile(filePath)
            } catch {
                failedFiles.append(filePath)
                logger.warning("Failed to stage file \(filePath): \(error.localizedDescription)")
            }
        }

        if !failedFiles.isEmpty {
            throw GitError.stagingFailed("Failed to stage \(failedFiles.count) files: \(failedFiles.joined(separator: ", "))")
        }

        logger.info("Successfully staged \(filePaths.count) files")
    }

    /// Unstages multiple files
    public func unstageFiles(_ filePaths: [String]) async throws {
        logger.debug("Unstaging \(filePaths.count) files")

        var failedFiles: [String] = []

        for filePath in filePaths {
            do {
                try await unstageFile(filePath)
            } catch {
                failedFiles.append(filePath)
                logger.warning("Failed to unstage file \(filePath): \(error.localizedDescription)")
            }
        }

        if !failedFiles.isEmpty {
            throw GitError.stagingFailed("Failed to unstage \(failedFiles.count) files: \(failedFiles.joined(separator: ", "))")
        }

        logger.info("Successfully unstaged \(filePaths.count) files")
    }

    /// Stages all unstaged files
    public func stageAllFiles() async throws {
        logger.debug("Staging all files")

        do {
            try await gitExecutor.stageAllFiles()

            // Invalidate status cache to ensure fresh data
            statusManager.invalidateCache()

            logger.info("Successfully staged all files")
        } catch {
            logger.error("Failed to stage all files: \(error.localizedDescription)")
            throw GitError.stagingFailed("Failed to stage all files: \(error.localizedDescription)")
        }
    }

    /// Unstages all staged files
    public func unstageAllFiles() async throws {
        logger.debug("Unstaging all files")

        do {
            try await gitExecutor.unstageAllFiles()

            // Invalidate status cache to ensure fresh data
            statusManager.invalidateCache()

            logger.info("Successfully unstaged all files")
        } catch {
            logger.error("Failed to unstage all files: \(error.localizedDescription)")
            throw GitError.stagingFailed("Failed to unstage all files: \(error.localizedDescription)")
        }
    }

    // MARK: - Status-based Operations

    /// Stages all modified files (excluding untracked)
    public func stageAllModifiedFiles() async throws {
        let statusEntries = try await statusManager.getDetailedStatus()
        let modifiedFiles = statusEntries
            .filter { $0.hasWorkingDirectoryChanges && !$0.isUntracked }
            .map { $0.filePath }

        if !modifiedFiles.isEmpty {
            try await stageFiles(modifiedFiles)
        }
    }

    /// Stages all untracked files
    public func stageAllUntrackedFiles() async throws {
        let statusEntries = try await statusManager.getDetailedStatus()
        let untrackedFiles = statusEntries
            .filter { $0.isUntracked }
            .map { $0.filePath }

        if !untrackedFiles.isEmpty {
            try await stageFiles(untrackedFiles)
        }
    }

    /// Unstages all staged files
    public func unstageAllStagedFiles() async throws {
        let statusEntries = try await statusManager.getDetailedStatus()
        let stagedFiles = statusEntries
            .filter { $0.isStaged }
            .map { $0.filePath }

        if !stagedFiles.isEmpty {
            try await unstageFiles(stagedFiles)
        }
    }

    // MARK: - Staging Status Queries

    /// Gets current staging status
    public func getStagingStatus() async throws -> StagingStatus {
        let statusEntries = try await statusManager.getDetailedStatus()

        let stagedFiles = statusEntries.filter { $0.isStaged }
        let modifiedFiles = statusEntries.filter { $0.hasWorkingDirectoryChanges && !$0.isUntracked }
        let untrackedFiles = statusEntries.filter { $0.isUntracked }

        return StagingStatus(
            stagedFiles: stagedFiles,
            modifiedFiles: modifiedFiles,
            untrackedFiles: untrackedFiles
        )
    }

    /// Checks if repository has staged changes
    public func hasStagedChanges() async throws -> Bool {
        let statusEntries = try await statusManager.getDetailedStatus()
        return statusEntries.contains { $0.isStaged }
    }

    /// Checks if repository has unstaged changes
    public func hasUnstagedChanges() async throws -> Bool {
        let statusEntries = try await statusManager.getDetailedStatus()
        return statusEntries.contains { $0.hasWorkingDirectoryChanges || $0.isUntracked }
    }

    // MARK: - Rollback Operations

    /// Attempts to rollback staging operation by refreshing status
    public func rollbackLastOperation() async throws {
        logger.debug("Rolling back last staging operation")

        // Force refresh the status to reflect actual Git state
        try await statusManager.refreshCache()

        logger.info("Rolled back last staging operation")
    }
}

// MARK: - Supporting Types

/// Represents the current staging status of the repository
public struct StagingStatus {
    /// Files that are staged for commit
    public let stagedFiles: [GitStatusEntry]

    /// Files that are modified but not staged
    public let modifiedFiles: [GitStatusEntry]

    /// Files that are untracked
    public let untrackedFiles: [GitStatusEntry]

    /// Total number of files with changes
    public var totalChangedFiles: Int {
        stagedFiles.count + modifiedFiles.count + untrackedFiles.count
    }

    /// Whether there are any changes to stage
    public var hasChangesToStage: Bool {
        !modifiedFiles.isEmpty || !untrackedFiles.isEmpty
    }

    /// Whether there are any staged changes
    public var hasStagedChanges: Bool {
        !stagedFiles.isEmpty
    }

    /// Status message for UI display
    public var statusMessage: String {
        if totalChangedFiles == 0 {
            return "No changes to stage"
        }

        var parts: [String] = []

        if !stagedFiles.isEmpty {
            parts.append("\(stagedFiles.count) staged")
        }

        if !modifiedFiles.isEmpty {
            parts.append("\(modifiedFiles.count) modified")
        }

        if !untrackedFiles.isEmpty {
            parts.append("\(untrackedFiles.count) untracked")
        }

        return parts.joined(separator: ", ")
    }
}

// MARK: - Error Extensions

extension GitError {
    static func stagingFailed(_ message: String) -> GitError {
        .libgit2Error("Staging operation failed: \(message)")
    }
}
