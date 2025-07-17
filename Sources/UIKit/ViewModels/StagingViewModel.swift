//
// StagingViewModel.swift
// GitCthulhu
//
// Created by GitCthulhu Team on 2025-07-16.
//

import Foundation
import GitCore
import SwiftUI
import Utilities

/// ViewModel for managing staging operations and state
@MainActor
public class StagingViewModel: ObservableObject {
    @Published public var isLoading = false
    @Published public var stagingStatus: StagingStatus?
    @Published public var lastOperationResult: StagingOperationResult?
    @Published public var errorMessage: String?

    private let repository: GitRepository
    private let stagingManager: GitStagingManager
    private let stagingOperations: GitStagingOperations
    private let logger = Logger(category: "StagingViewModel")

    public init(repository: GitRepository) {
        self.repository = repository
        stagingManager = GitStagingManager(repositoryURL: repository.url)
        stagingOperations = GitStagingOperations(repositoryURL: repository.url)

        // Initial load
        Task {
            await loadStagingStatus()
        }
    }

    public convenience init(repositoryPath: String) {
        let url = URL(fileURLWithPath: repositoryPath)
        let repository = try! GitRepository(url: url)
        self.init(repository: repository)
    }

    // MARK: - Public Methods

    /// Loads the current staging status
    public func loadStagingStatus() async {
        isLoading = true
        errorMessage = nil

        do {
            let status = try await stagingManager.getStagingStatus()
            stagingStatus = status
            logger.debug("Loaded staging status: \(status.statusMessage)")
        } catch {
            errorMessage = "Failed to load staging status: \(error.localizedDescription)"
            logger.error("Failed to load staging status: \(error)")
        }

        isLoading = false
    }

    /// Refreshes the staging status
    public func refreshStagingStatus() async {
        await loadStagingStatus()
    }

    /// Alias for refreshStagingStatus to match interface expected by IntegratedRepositoryView
    public func refreshStatus() async {
        await refreshStagingStatus()
    }

    // MARK: - Single File Operations

    /// Stages a single file
    public func stageFile(_ filePath: String) async {
        await performStagingOperation {
            try await stagingManager.stageFile(filePath)
            return StagingOperationResult(
                operation: .stage,
                successfulFiles: [filePath],
                failedFiles: [],
                skippedFiles: []
            )
        }
    }

    /// Unstages a single file
    public func unstageFile(_ filePath: String) async {
        await performStagingOperation {
            try await stagingManager.unstageFile(filePath)
            return StagingOperationResult(
                operation: .unstage,
                successfulFiles: [filePath],
                failedFiles: [],
                skippedFiles: []
            )
        }
    }

    /// Toggles staging status of a file
    public func toggleFileStaging(_ filePath: String) async {
        await performStagingOperation {
            try await stagingManager.toggleFileStaging(filePath)

            // Determine the operation that was performed
            let updatedStatus = try await stagingManager.getStagingStatus()
            let wasStaged = updatedStatus.stagedFiles.contains { $0.filePath == filePath }

            return StagingOperationResult(
                operation: wasStaged ? .stage : .unstage,
                successfulFiles: [filePath],
                failedFiles: [],
                skippedFiles: []
            )
        }
    }

    // MARK: - Batch Operations

    /// Stages multiple files
    public func stageFiles(_ filePaths: [String]) async {
        await performStagingOperation {
            try await stagingOperations.smartStageFiles(filePaths)
        }
    }

    /// Unstages multiple files
    public func unstageFiles(_ filePaths: [String]) async {
        await performStagingOperation {
            try await stagingOperations.smartUnstageFiles(filePaths)
        }
    }

    /// Toggles staging for multiple files
    public func toggleFilesStaging(_ filePaths: [String]) async {
        await performStagingOperation {
            try await stagingOperations.toggleFilesStaging(filePaths)
        }
    }

    /// Stages all files
    public func stageAllFiles() async {
        await performStagingOperation {
            try await stagingOperations.stageAllFilesWithProgress()
        }
    }

    /// Unstages all files
    public func unstageAllFiles() async {
        await performStagingOperation {
            try await stagingOperations.unstageAllFilesWithProgress()
        }
    }

    // MARK: - Selective Operations

    /// Stages only modified files
    public func stageModifiedFiles() async {
        await performStagingOperation {
            try await stagingOperations.stageModifiedFiles()
        }
    }

    /// Stages only untracked files
    public func stageUntrackedFiles() async {
        await performStagingOperation {
            try await stagingOperations.stageUntrackedFiles()
        }
    }

    // MARK: - Status Queries

    /// Gets detailed staging status
    public func getDetailedStagingStatus() async -> DetailedStagingStatus? {
        do {
            return try await stagingOperations.getDetailedStagingStatus()
        } catch {
            logger.error("Failed to get detailed staging status: \(error)")
            return nil
        }
    }

    /// Checks if there are staged changes
    public func hasStagedChanges() async -> Bool {
        do {
            return try await stagingManager.hasStagedChanges()
        } catch {
            logger.error("Failed to check staged changes: \(error)")
            return false
        }
    }

    /// Checks if there are unstaged changes
    public func hasUnstagedChanges() async -> Bool {
        do {
            return try await stagingManager.hasUnstagedChanges()
        } catch {
            logger.error("Failed to check unstaged changes: \(error)")
            return false
        }
    }

    // MARK: - Error Handling

    /// Clears the current error message
    public func clearError() {
        errorMessage = nil
    }

    /// Clears the last operation result
    public func clearLastResult() {
        lastOperationResult = nil
    }

    // MARK: - Private Methods

    private func performStagingOperation(_ operation: () async throws -> StagingOperationResult) async {
        isLoading = true
        errorMessage = nil

        do {
            let result = try await operation()
            lastOperationResult = result

            // Log the operation result
            logger.info("Staging operation completed: \(result.summary)")

            // If operation was successful, refresh the status
            if result.isSuccess {
                await loadStagingStatus()

                // Also refresh the repository status
                await repository.refreshStatus()
            } else {
                // If some files failed, still refresh to get current state
                await loadStagingStatus()

                // Set error message for failed files
                if !result.failedFiles.isEmpty {
                    let failedFilesList = result.failedFiles.joined(separator: ", ")
                    errorMessage = "Failed to process \(result.failedFiles.count) files: \(failedFilesList)"
                }
            }

        } catch {
            errorMessage = "Operation failed: \(error.localizedDescription)"
            logger.error("Staging operation failed: \(error)")
        }

        isLoading = false
    }
}

// MARK: - Computed Properties

public extension StagingViewModel {
    /// Whether staging operations are available
    var canPerformStagingOperations: Bool {
        !isLoading && errorMessage == nil
    }

    /// Number of staged files
    var stagedFilesCount: Int {
        stagingStatus?.stagedFiles.count ?? 0
    }

    /// Number of unstaged files
    var unstagedFilesCount: Int {
        (stagingStatus?.modifiedFiles.count ?? 0) + (stagingStatus?.untrackedFiles.count ?? 0)
    }

    /// Total number of changed files
    var totalChangedFiles: Int {
        stagingStatus?.totalChangedFiles ?? 0
    }

    /// Whether there are changes to stage
    var hasChangesToStage: Bool {
        stagingStatus?.hasChangesToStage ?? false
    }

    /// Whether there are staged changes
    var hasStagedChanges: Bool {
        stagingStatus?.hasStagedChanges ?? false
    }

    /// Status message for display
    var statusMessage: String {
        stagingStatus?.statusMessage ?? "No changes"
    }

    /// Whether the last operation was successful
    var lastOperationWasSuccessful: Bool {
        lastOperationResult?.isSuccess ?? false
    }

    /// Success message for the last operation
    var lastOperationSuccessMessage: String? {
        guard let result = lastOperationResult, result.isSuccess else { return nil }
        return "\(result.operation.displayName) completed successfully: \(result.summary)"
    }
}

// MARK: - Convenience Methods

public extension StagingViewModel {
    /// Stages files from selected file paths
    func stageSelectedFiles(_ selectedFiles: Set<String>) async {
        guard !selectedFiles.isEmpty else { return }
        await stageFiles(Array(selectedFiles))
    }

    /// Unstages files from selected file paths
    func unstageSelectedFiles(_ selectedFiles: Set<String>) async {
        guard !selectedFiles.isEmpty else { return }
        await unstageFiles(Array(selectedFiles))
    }

    /// Toggles staging for selected files
    func toggleSelectedFilesStaging(_ selectedFiles: Set<String>) async {
        guard !selectedFiles.isEmpty else { return }
        await toggleFilesStaging(Array(selectedFiles))
    }
}
