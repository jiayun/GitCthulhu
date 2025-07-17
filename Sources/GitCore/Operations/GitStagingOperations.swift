//
// GitStagingOperations.swift
// GitCthulhu
//
// Created by GitCthulhu Team on 2025-07-16.
//

import Foundation
import Utilities

/// High-level staging operations with advanced features
public class GitStagingOperations {
    private let stagingManager: GitStagingManager
    private let logger = Logger(category: "GitStagingOperations")

    public init(repositoryURL: URL) {
        stagingManager = GitStagingManager(repositoryURL: repositoryURL)
    }

    // MARK: - Smart Staging Operations

    /// Intelligently stages files based on their current status
    public func smartStageFiles(_ filePaths: [String]) async throws -> StagingOperationResult {
        logger.debug("Smart staging \(filePaths.count) files")

        var stagedFiles: [String] = []
        var failedFiles: [String] = []
        var skippedFiles: [String] = []

        for filePath in filePaths {
            do {
                let status = try await stagingManager.getStagingStatus()

                // Skip files that are already staged
                if status.stagedFiles.contains(where: { $0.filePath == filePath }) {
                    skippedFiles.append(filePath)
                    continue
                }

                // Stage the file
                try await stagingManager.stageFile(filePath)
                stagedFiles.append(filePath)

            } catch {
                failedFiles.append(filePath)
                logger.warning("Failed to stage file \(filePath): \(error.localizedDescription)")
            }
        }

        let result = StagingOperationResult(
            operation: .stage,
            successfulFiles: stagedFiles,
            failedFiles: failedFiles,
            skippedFiles: skippedFiles
        )

        logger.info("Smart staging completed: \(result.summary)")
        return result
    }

    /// Intelligently unstages files based on their current status
    public func smartUnstageFiles(_ filePaths: [String]) async throws -> StagingOperationResult {
        logger.debug("Smart unstaging \(filePaths.count) files")

        var unstagedFiles: [String] = []
        var failedFiles: [String] = []
        var skippedFiles: [String] = []

        for filePath in filePaths {
            do {
                let status = try await stagingManager.getStagingStatus()

                // Skip files that are not staged
                if !status.stagedFiles.contains(where: { $0.filePath == filePath }) {
                    skippedFiles.append(filePath)
                    continue
                }

                // Unstage the file
                try await stagingManager.unstageFile(filePath)
                unstagedFiles.append(filePath)

            } catch {
                failedFiles.append(filePath)
                logger.warning("Failed to unstage file \(filePath): \(error.localizedDescription)")
            }
        }

        let result = StagingOperationResult(
            operation: .unstage,
            successfulFiles: unstagedFiles,
            failedFiles: failedFiles,
            skippedFiles: skippedFiles
        )

        logger.info("Smart unstaging completed: \(result.summary)")
        return result
    }

    /// Toggles staging status for multiple files
    public func toggleFilesStaging(_ filePaths: [String]) async throws -> StagingOperationResult {
        logger.debug("Toggling staging for \(filePaths.count) files")

        var stagedFiles: [String] = []
        var unstagedFiles: [String] = []
        var failedFiles: [String] = []

        for filePath in filePaths {
            do {
                let status = try await stagingManager.getStagingStatus()

                if status.stagedFiles.contains(where: { $0.filePath == filePath }) {
                    // File is staged, unstage it
                    try await stagingManager.unstageFile(filePath)
                    unstagedFiles.append(filePath)
                } else {
                    // File is not staged, stage it
                    try await stagingManager.stageFile(filePath)
                    stagedFiles.append(filePath)
                }

            } catch {
                failedFiles.append(filePath)
                logger.warning("Failed to toggle staging for file \(filePath): \(error.localizedDescription)")
            }
        }

        let result = StagingOperationResult(
            operation: .toggle,
            successfulFiles: stagedFiles + unstagedFiles,
            failedFiles: failedFiles,
            skippedFiles: []
        )

        logger.info("Toggle staging completed: \(result.summary)")
        return result
    }

    // MARK: - Batch Operations with Progress

    /// Stages all files with progress tracking
    public func stageAllFilesWithProgress() async throws -> StagingOperationResult {
        logger.debug("Staging all files with progress")

        do {
            try await stagingManager.stageAllFiles()

            // Get final status to determine what was staged
            let finalStatus = try await stagingManager.getStagingStatus()

            let result = StagingOperationResult(
                operation: .stageAll,
                successfulFiles: finalStatus.stagedFiles.map(\.filePath),
                failedFiles: [],
                skippedFiles: []
            )

            logger.info("Stage all completed: \(result.summary)")
            return result

        } catch {
            logger.error("Failed to stage all files: \(error.localizedDescription)")
            throw error
        }
    }

    /// Unstages all files with progress tracking
    public func unstageAllFilesWithProgress() async throws -> StagingOperationResult {
        logger.debug("Unstaging all files with progress")

        do {
            // Get initial status to know what will be unstaged
            let initialStatus = try await stagingManager.getStagingStatus()
            let initiallyStaged = initialStatus.stagedFiles.map(\.filePath)

            try await stagingManager.unstageAllFiles()

            let result = StagingOperationResult(
                operation: .unstageAll,
                successfulFiles: initiallyStaged,
                failedFiles: [],
                skippedFiles: []
            )

            logger.info("Unstage all completed: \(result.summary)")
            return result

        } catch {
            logger.error("Failed to unstage all files: \(error.localizedDescription)")
            throw error
        }
    }

    // MARK: - Selective Operations

    /// Stages only modified files (excluding untracked)
    public func stageModifiedFiles() async throws -> StagingOperationResult {
        logger.debug("Staging modified files")

        do {
            let status = try await stagingManager.getStagingStatus()
            let modifiedFiles = status.modifiedFiles.map(\.filePath)

            if modifiedFiles.isEmpty {
                return StagingOperationResult(
                    operation: .stageModified,
                    successfulFiles: [],
                    failedFiles: [],
                    skippedFiles: []
                )
            }

            try await stagingManager.stageFiles(modifiedFiles)

            let result = StagingOperationResult(
                operation: .stageModified,
                successfulFiles: modifiedFiles,
                failedFiles: [],
                skippedFiles: []
            )

            logger.info("Stage modified files completed: \(result.summary)")
            return result

        } catch {
            logger.error("Failed to stage modified files: \(error.localizedDescription)")
            throw error
        }
    }

    /// Stages only untracked files
    public func stageUntrackedFiles() async throws -> StagingOperationResult {
        logger.debug("Staging untracked files")

        do {
            let status = try await stagingManager.getStagingStatus()
            let untrackedFiles = status.untrackedFiles.map(\.filePath)

            if untrackedFiles.isEmpty {
                return StagingOperationResult(
                    operation: .stageUntracked,
                    successfulFiles: [],
                    failedFiles: [],
                    skippedFiles: []
                )
            }

            try await stagingManager.stageFiles(untrackedFiles)

            let result = StagingOperationResult(
                operation: .stageUntracked,
                successfulFiles: untrackedFiles,
                failedFiles: [],
                skippedFiles: []
            )

            logger.info("Stage untracked files completed: \(result.summary)")
            return result

        } catch {
            logger.error("Failed to stage untracked files: \(error.localizedDescription)")
            throw error
        }
    }

    // MARK: - Validation Operations

    /// Validates files before staging
    public func validateAndStageFiles(_ filePaths: [String]) async throws -> StagingOperationResult {
        logger.debug("Validating and staging \(filePaths.count) files")

        var validFiles: [String] = []
        let invalidFiles: [String] = []

        // Basic validation: check if files exist and are within repository
        for filePath in filePaths {
            // Add basic validation logic here
            // For now, assume all files are valid
            validFiles.append(filePath)
        }

        if validFiles.isEmpty {
            return StagingOperationResult(
                operation: .stage,
                successfulFiles: [],
                failedFiles: invalidFiles,
                skippedFiles: []
            )
        }

        return try await smartStageFiles(validFiles)
    }

    // MARK: - Status Queries

    /// Gets comprehensive staging status
    public func getDetailedStagingStatus() async throws -> DetailedStagingStatus {
        let stagingStatus = try await stagingManager.getStagingStatus()

        return DetailedStagingStatus(
            totalFiles: stagingStatus.totalChangedFiles,
            stagedFiles: stagingStatus.stagedFiles.count,
            modifiedFiles: stagingStatus.modifiedFiles.count,
            untrackedFiles: stagingStatus.untrackedFiles.count,
            canStageAll: stagingStatus.hasChangesToStage,
            canUnstageAll: stagingStatus.hasStagedChanges
        )
    }
}

// MARK: - Supporting Types

/// Represents the result of a staging operation
public struct StagingOperationResult {
    public let operation: StagingOperation
    public let successfulFiles: [String]
    public let failedFiles: [String]
    public let skippedFiles: [String]

    public init(operation: StagingOperation, successfulFiles: [String], failedFiles: [String], skippedFiles: [String]) {
        self.operation = operation
        self.successfulFiles = successfulFiles
        self.failedFiles = failedFiles
        self.skippedFiles = skippedFiles
    }

    public var isSuccess: Bool {
        failedFiles.isEmpty
    }

    public var totalFiles: Int {
        successfulFiles.count + failedFiles.count + skippedFiles.count
    }

    public var summary: String {
        var parts: [String] = []

        if !successfulFiles.isEmpty {
            parts.append("\(successfulFiles.count) successful")
        }

        if !failedFiles.isEmpty {
            parts.append("\(failedFiles.count) failed")
        }

        if !skippedFiles.isEmpty {
            parts.append("\(skippedFiles.count) skipped")
        }

        return parts.joined(separator: ", ")
    }
}

/// Types of staging operations
public enum StagingOperation {
    case stage
    case unstage
    case toggle
    case stageAll
    case unstageAll
    case stageModified
    case stageUntracked

    public var displayName: String {
        switch self {
        case .stage: "Stage"
        case .unstage: "Unstage"
        case .toggle: "Toggle"
        case .stageAll: "Stage All"
        case .unstageAll: "Unstage All"
        case .stageModified: "Stage Modified"
        case .stageUntracked: "Stage Untracked"
        }
    }
}

/// Detailed staging status for UI display
public struct DetailedStagingStatus {
    public let totalFiles: Int
    public let stagedFiles: Int
    public let modifiedFiles: Int
    public let untrackedFiles: Int
    public let canStageAll: Bool
    public let canUnstageAll: Bool

    public var statusText: String {
        if totalFiles == 0 {
            return "No changes"
        }

        var parts: [String] = []

        if stagedFiles > 0 {
            parts.append("\(stagedFiles) staged")
        }

        if modifiedFiles > 0 {
            parts.append("\(modifiedFiles) modified")
        }

        if untrackedFiles > 0 {
            parts.append("\(untrackedFiles) untracked")
        }

        return parts.joined(separator: ", ")
    }
}
