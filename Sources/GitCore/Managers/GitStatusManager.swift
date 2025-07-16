//
// GitStatusManager.swift
// GitCthulhu
//
// Created by GitCthulhu Team on 2025-07-15.
//

import Foundation
import Utilities

/// Manages Git status operations and provides detailed status information
public class GitStatusManager {
    private let repositoryURL: URL
    private let gitExecutor: GitCommandExecutor
    private let logger = Logger(category: "GitStatusManager")

    /// Cache for status entries to improve performance
    private var statusCache: [String: GitStatusEntry] = [:]
    private var cachedEntries: [GitStatusEntry] = [] // Maintain order
    private var lastCacheUpdate: Date = .distantPast
    private let cacheValidityDuration: TimeInterval = 1.0 // 1 second cache

    public init(repositoryURL: URL) {
        self.repositoryURL = repositoryURL
        gitExecutor = GitCommandExecutor(repositoryURL: repositoryURL)
    }

    /// Gets the complete repository status with detailed information
    public func getDetailedStatus(useCache: Bool = true) async throws -> [GitStatusEntry] {
        if useCache, isCacheValid() {
            logger.debug("Using cached status entries (count: \(cachedEntries.count))")
            return cachedEntries
        }

        let output = try await gitExecutor.execute(["status", "--porcelain=v1"])
        let entries = parseStatusOutput(output)

        // Sort entries by file path for consistent ordering
        let sortedEntries = entries.sorted { $0.filePath < $1.filePath }

        // Update cache - maintain both dictionary for fast lookup and array for order
        statusCache = Dictionary(uniqueKeysWithValues: sortedEntries.map { ($0.filePath, $0) })
        cachedEntries = sortedEntries
        lastCacheUpdate = Date()

        logger.info("Loaded detailed status for \(sortedEntries.count) files")
        return sortedEntries
    }

    /// Gets status for a specific file
    public func getFileStatus(_ filePath: String) async throws -> GitStatusEntry? {
        // Check cache first
        if isCacheValid(), let cachedEntry = statusCache[filePath] {
            return cachedEntry
        }

        let output = try await gitExecutor.execute(["status", "--porcelain=v1", filePath])
        guard !output.isEmpty else { return nil }

        let entries = parseStatusOutput(output)
        let entry = entries.first { $0.filePath == filePath }

        // Update cache for this file
        if let entry {
            statusCache[filePath] = entry
            // Also update the ordered cache if this file is not already present
            if !cachedEntries.contains(where: { $0.filePath == filePath }) {
                cachedEntries.append(entry)
            } else {
                // Update existing entry in the ordered cache
                if let index = cachedEntries.firstIndex(where: { $0.filePath == filePath }) {
                    cachedEntries[index] = entry
                }
            }
        }

        return entry
    }

    /// Gets only staged files
    public func getStagedFiles() async throws -> [GitStatusEntry] {
        let allEntries = try await getDetailedStatus()
        return allEntries.filter(\.isStaged)
    }

    /// Gets only unstaged files (working directory changes)
    public func getUnstagedFiles() async throws -> [GitStatusEntry] {
        let allEntries = try await getDetailedStatus()
        return allEntries.filter(\.hasWorkingDirectoryChanges)
    }

    /// Gets only untracked files
    public func getUntrackedFiles() async throws -> [GitStatusEntry] {
        let allEntries = try await getDetailedStatus()
        return allEntries.filter(\.isUntracked)
    }

    /// Gets files with conflicts
    public func getConflictedFiles() async throws -> [GitStatusEntry] {
        let allEntries = try await getDetailedStatus()
        return allEntries.filter(\.hasConflicts)
    }

    /// Checks if the repository is clean (no changes)
    public func isRepositoryClean() async throws -> Bool {
        let output = try await gitExecutor.execute(["status", "--porcelain=v1"])
        return output.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    /// Gets a summary of repository status
    public func getStatusSummary() async throws -> GitStatusSummary {
        let entries = try await getDetailedStatus()

        let staged = entries.filter(\.isStaged)
        let unstaged = entries.filter(\.hasWorkingDirectoryChanges)
        let untracked = entries.filter(\.isUntracked)
        let conflicted = entries.filter(\.hasConflicts)

        return GitStatusSummary(
            stagedCount: staged.count,
            unstagedCount: unstaged.count,
            untrackedCount: untracked.count,
            conflictedCount: conflicted.count,
            isClean: entries.isEmpty
        )
    }

    /// Invalidates the status cache
    public func invalidateCache() {
        statusCache.removeAll()
        cachedEntries.removeAll()
        lastCacheUpdate = .distantPast
        logger.debug("Status cache invalidated")
    }

    /// Refreshes the status cache
    public func refreshCache() async throws {
        invalidateCache()
        _ = try await getDetailedStatus(useCache: false)
    }

    // MARK: - Private Methods

    private func isCacheValid() -> Bool {
        Date().timeIntervalSince(lastCacheUpdate) < cacheValidityDuration
    }

    private func parseStatusOutput(_ output: String) -> [GitStatusEntry] {
        let lines = output.components(separatedBy: .newlines)
            .filter { !$0.isEmpty }

        var entries: [GitStatusEntry] = []

        for line in lines {
            if let entry = GitStatusEntry.fromPorcelainLine(line) {
                entries.append(entry)
            } else {
                logger.warning("Failed to parse status line: \(line)")
            }
        }

        logger.debug("Parsed \(entries.count) status entries in order")
        return entries
    }
}

/// Summary of repository status
public struct GitStatusSummary {
    /// Number of staged files
    public let stagedCount: Int

    /// Number of unstaged files
    public let unstagedCount: Int

    /// Number of untracked files
    public let untrackedCount: Int

    /// Number of conflicted files
    public let conflictedCount: Int

    /// Whether the repository is clean
    public let isClean: Bool

    /// Total number of changed files
    public var totalChanges: Int {
        stagedCount + unstagedCount + untrackedCount
    }

    /// Whether there are any changes
    public var hasChanges: Bool {
        !isClean
    }

    /// Status message for UI display
    public var statusMessage: String {
        if isClean {
            return "Working directory clean"
        }

        var parts: [String] = []

        if stagedCount > 0 {
            parts.append("\(stagedCount) staged")
        }

        if unstagedCount > 0 {
            parts.append("\(unstagedCount) unstaged")
        }

        if untrackedCount > 0 {
            parts.append("\(untrackedCount) untracked")
        }

        if conflictedCount > 0 {
            parts.append("\(conflictedCount) conflicted")
        }

        return parts.joined(separator: ", ")
    }
}
