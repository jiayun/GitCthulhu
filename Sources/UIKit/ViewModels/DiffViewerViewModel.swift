//
// DiffViewerViewModel.swift
// GitCthulhu
//
// Created by GitCthulhu Team on 2025-07-17.
//

import Foundation
import GitCore
import SwiftUI

/// ViewModel for the diff viewer
@MainActor
public class DiffViewerViewModel: ObservableObject {
    private let diffManager: GitDiffManager

    /// Current diffs being displayed
    @Published public private(set) var diffs: [GitDiff] = []

    /// Currently selected file for viewing
    @Published public var selectedFilePath: String?

    /// Current view mode
    @Published public var viewMode: DiffViewMode = .unified

    /// Show whitespace characters
    @Published public var showWhitespace: Bool = false

    /// Show line numbers
    @Published public var showLineNumbers: Bool = true

    /// Loading state
    @Published public private(set) var isLoading: Bool = false

    /// Error state
    @Published public private(set) var error: GitError?

    /// Search query for filtering files
    @Published public var searchQuery: String = ""

    /// Whether to show staged or unstaged diffs
    @Published public var showStaged: Bool = false

    public init(repositoryPath: String) {
        diffManager = GitDiffManager(repositoryPath: repositoryPath)
    }

    // MARK: - Public Methods

    /// Load diffs for all files
    public func loadDiffs() async {
        isLoading = true
        error = nil

        do {
            let loadedDiffs = try await diffManager.getAllDiffs(staged: showStaged)
            diffs = loadedDiffs

            // Auto-select first file if none selected
            if selectedFilePath == nil, let firstDiff = loadedDiffs.first {
                selectedFilePath = firstDiff.filePath
            }
        } catch let gitError as GitError {
            error = gitError
        } catch {
            self.error = GitError.unknown(error.localizedDescription)
        }

        isLoading = false
    }

    /// Load diff for a specific file
    public func loadDiff(for filePath: String) async {
        do {
            if let diff = try await diffManager.getDiff(for: filePath, staged: showStaged) {
                // Update the specific diff in our array
                if let index = diffs.firstIndex(where: { $0.filePath == filePath }) {
                    diffs[index] = diff
                } else {
                    diffs.append(diff)
                }
            }
        } catch let gitError as GitError {
            error = gitError
        } catch {
            self.error = GitError.unknown(error.localizedDescription)
        }
    }

    /// Select a file for viewing
    public func selectFile(_ filePath: String) {
        selectedFilePath = filePath

        // Load diff if not already loaded
        Task {
            await loadDiff(for: filePath)
        }
    }

    /// Get the currently selected diff
    public var selectedDiff: GitDiff? {
        guard let selectedFilePath else { return nil }
        return diffs.first { $0.filePath == selectedFilePath }
    }

    /// Toggle between staged and unstaged view
    public func toggleStaged() {
        showStaged.toggle()
        Task {
            await loadDiffs()
        }
    }

    /// Refresh all diffs
    public func refresh() {
        Task {
            await loadDiffs()
        }
    }

    /// Clear current error
    public func clearError() {
        error = nil
    }

    // MARK: - Computed Properties

    /// Filtered diffs based on search query
    public var filteredDiffs: [GitDiff] {
        guard !searchQuery.trimmingCharacters(in: .whitespaces).isEmpty else {
            return diffs
        }

        let query = searchQuery.lowercased()
        return diffs.filter { diff in
            diff.filePath.lowercased().contains(query) ||
                diff.fileName.lowercased().contains(query) ||
                (diff.oldPath?.lowercased().contains(query) ?? false)
        }
    }

    /// Total statistics for all diffs
    public var totalStats: GitDiffStats {
        let totalAdditions = diffs.reduce(0) { $0 + $1.additionsCount }
        let totalDeletions = diffs.reduce(0) { $0 + $1.deletionsCount }
        let totalContext = diffs.reduce(0) { $0 + $1.contextCount }
        let totalChunks = diffs.reduce(0) { $0 + $1.chunks.count }
        let hasBinary = diffs.contains { $0.isBinary }

        return GitDiffStats(
            additions: totalAdditions,
            deletions: totalDeletions,
            context: totalContext,
            chunks: totalChunks,
            isBinary: hasBinary
        )
    }

    /// Navigation methods
    public func selectNextFile() {
        guard let currentPath = selectedFilePath,
              let currentIndex = filteredDiffs.firstIndex(where: { $0.filePath == currentPath }),
              currentIndex < filteredDiffs.count - 1 else { return }

        selectFile(filteredDiffs[currentIndex + 1].filePath)
    }

    public func selectPreviousFile() {
        guard let currentPath = selectedFilePath,
              let currentIndex = filteredDiffs.firstIndex(where: { $0.filePath == currentPath }),
              currentIndex > 0 else { return }

        selectFile(filteredDiffs[currentIndex - 1].filePath)
    }

    /// Check if navigation is possible
    public var canNavigateNext: Bool {
        guard let currentPath = selectedFilePath,
              let currentIndex = filteredDiffs.firstIndex(where: { $0.filePath == currentPath }) else { return false }
        return currentIndex < filteredDiffs.count - 1
    }

    public var canNavigatePrevious: Bool {
        guard let currentPath = selectedFilePath,
              let currentIndex = filteredDiffs.firstIndex(where: { $0.filePath == currentPath }) else { return false }
        return currentIndex > 0
    }
}

/// Diff view modes
public enum DiffViewMode: String, CaseIterable, Identifiable {
    case unified
    case sideBySide

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .unified:
            "Unified"
        case .sideBySide:
            "Side by Side"
        }
    }

    public var icon: String {
        switch self {
        case .unified:
            "list.bullet"
        case .sideBySide:
            "rectangle.split.2x1"
        }
    }
}
