//
// GitStatusViewModel.swift
// GitCthulhu
//
// Created by GitCthulhu Team on 2025-07-17.
//

import Foundation
import GitCore
import SwiftUI

/// ViewModel wrapper for GitStatusManager to provide ObservableObject compatibility
@MainActor
public class GitStatusViewModel: ObservableObject {
    @Published public private(set) var statusEntries: [GitStatusEntry] = []
    @Published public private(set) var isLoading: Bool = false
    @Published public private(set) var error: Error?

    private let statusManager: GitStatusManager

    public init(repositoryPath: String) {
        statusManager = GitStatusManager(repositoryURL: URL(fileURLWithPath: repositoryPath))
    }

    public init(repositoryURL: URL) {
        statusManager = GitStatusManager(repositoryURL: repositoryURL)
    }

    /// Checks status and updates the published properties for UI
    public func checkStatus() async {
        isLoading = true
        error = nil

        do {
            let entries = try await statusManager.getDetailedStatus(useCache: false)
            statusEntries = entries
        } catch {
            self.error = error
        }

        isLoading = false
    }

    /// Refreshes the status
    public func refresh() async {
        await checkStatus()
    }

    /// Gets status summary
    public func getStatusSummary() async throws -> GitStatusSummary {
        try await statusManager.getStatusSummary()
    }

    /// Gets status for a specific file
    public func getFileStatus(_ filePath: String) async throws -> GitStatusEntry? {
        try await statusManager.getFileStatus(filePath)
    }

    /// Checks if repository is clean
    public func isRepositoryClean() async throws -> Bool {
        try await statusManager.isRepositoryClean()
    }

    /// Invalidates the cache
    public func invalidateCache() {
        statusManager.invalidateCache()
    }
}
