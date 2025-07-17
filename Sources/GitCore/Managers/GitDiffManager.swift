//
// GitDiffManager.swift
// GitCthulhu
//
// Created by GitCthulhu Team on 2025-07-17.
//

import Foundation

/// Manager for Git diff operations
@MainActor
public class GitDiffManager: ObservableObject {
    private let commandExecutor: GitCommandExecutor
    private let repositoryPath: String

    /// Current diffs being displayed
    @Published public private(set) var currentDiffs: [GitDiff] = []

    /// Loading state
    @Published public private(set) var isLoading: Bool = false

    /// Current error state
    @Published public private(set) var error: GitError?

    public init(repositoryPath: String, commandExecutor: GitCommandExecutor? = nil) {
        self.repositoryPath = repositoryPath
        self.commandExecutor = commandExecutor ?? GitCommandExecutor(repositoryURL: URL(fileURLWithPath: repositoryPath))
    }

    // MARK: - Public Methods

    /// Get diff for a specific file
    public func getDiff(for filePath: String, staged: Bool = false) async throws -> GitDiff? {
        clearError()

        let arguments = buildDiffArguments(for: filePath, staged: staged)

        do {
            let output = try await commandExecutor.execute(arguments)

            return try parseSingleFileDiff(output: output, filePath: filePath)
        } catch {
            let gitError = GitError.unknown("Failed to get diff: \(error.localizedDescription)")
            await setError(gitError)
            throw gitError
        }
    }

    /// Get diffs for all changed files
    public func getAllDiffs(staged: Bool = false) async throws -> [GitDiff] {
        clearError()
        setLoading(true)

        defer { setLoading(false) }

        do {
            let arguments = buildDiffArguments(staged: staged)

            let output = try await commandExecutor.execute(arguments)

            let diffs = try parseMultiFileDiff(output: output)
            await MainActor.run {
                self.currentDiffs = diffs
            }

            return diffs
        } catch {
            let gitError = GitError.unknown("Failed to get diffs: \(error.localizedDescription)")
            await setError(gitError)
            throw gitError
        }
    }

    /// Get diff between two commits
    public func getDiffBetween(
        commit1: String,
        commit2: String,
        filePath: String? = nil
    ) async throws -> [GitDiff] {
        clearError()

        var arguments = ["diff", commit1, commit2]
        if let filePath = filePath {
            arguments.append("--")
            arguments.append(filePath)
        }

        do {
            let output = try await commandExecutor.execute(arguments)

            return try parseMultiFileDiff(output: output)
        } catch {
            let gitError = GitError.unknown("Failed to get diff between commits: \(error.localizedDescription)")
            await setError(gitError)
            throw gitError
        }
    }

    /// Get diff statistics
    public func getDiffStats(staged: Bool = false) async throws -> GitDiffStats {
        let arguments = buildDiffArguments(staged: staged) + ["--numstat"]

        do {
            let output = try await commandExecutor.execute(arguments)

            return parseDiffStats(output: output)
        } catch {
            let gitError = GitError.unknown("Failed to get diff stats: \(error.localizedDescription)")
            await setError(gitError)
            throw gitError
        }
    }

    /// Refresh current diffs
    public func refresh(staged: Bool = false) async {
        do {
            _ = try await getAllDiffs(staged: staged)
        } catch {
            // Error is already set in getAllDiffs
        }
    }

    // MARK: - Private Methods

    private func buildDiffArguments(for filePath: String? = nil, staged: Bool = false) -> [String] {
        var arguments = ["diff"]

        if staged {
            arguments.append("--cached")
        }

        // Add options for better parsing
        arguments.append(contentsOf: [
            "--no-color",
            "--no-ext-diff",
            "--unified=3",
            "--no-prefix"
        ])

        if let filePath = filePath {
            arguments.append("--")
            arguments.append(filePath)
        }

        return arguments
    }

    private func parseSingleFileDiff(output: String, filePath: String) throws -> GitDiff? {
        guard !output.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return nil
        }

        let parser = UnifiedDiffParser()
        let diffs = try parser.parse(output)

        // Find the diff for the specific file
        return diffs.first { $0.filePath == filePath || $0.oldPath == filePath }
    }

    private func parseMultiFileDiff(output: String) throws -> [GitDiff] {
        guard !output.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return []
        }

        let parser = UnifiedDiffParser()
        return try parser.parse(output)
    }

    private func parseDiffStats(output: String) -> GitDiffStats {
        let lines = output.components(separatedBy: .newlines)
            .filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }

        var totalAdditions = 0
        var totalDeletions = 0
        var fileCount = 0

        for line in lines {
            let components = line.components(separatedBy: .whitespaces)
            guard components.count >= 3 else { continue }

            let additions = Int(components[0]) ?? 0
            let deletions = Int(components[1]) ?? 0

            totalAdditions += additions
            totalDeletions += deletions
            fileCount += 1
        }

        return GitDiffStats(
            additions: totalAdditions,
            deletions: totalDeletions,
            context: 0,
            chunks: fileCount
        )
    }

    private func setLoading(_ loading: Bool) {
        Task { @MainActor in
            self.isLoading = loading
        }
    }

    private func setError(_ error: GitError) async {
        await MainActor.run {
            self.error = error
        }
    }

    private func clearError() {
        Task { @MainActor in
            self.error = nil
        }
    }
}

// MARK: - Error Handling

extension GitDiffManager {
    /// Clear the current error state
    public func clearCurrentError() {
        error = nil
    }

    /// Returns true if there's currently an error
    public var hasError: Bool {
        return error != nil
    }
}

// MARK: - Convenience Methods

extension GitDiffManager {
    /// Get diff for file with automatic staging detection
    public func getDiffForFile(_ filePath: String) async throws -> GitDiff? {
        // Try unstaged first, then staged
        if let unstagedDiff = try await getDiff(for: filePath, staged: false) {
            return unstagedDiff
        }

        return try await getDiff(for: filePath, staged: true)
    }

    /// Get both staged and unstaged diffs for a file
    public func getAllDiffsForFile(_ filePath: String) async throws -> (staged: GitDiff?, unstaged: GitDiff?) {
        async let stagedDiff = try? await getDiff(for: filePath, staged: true)
        async let unstagedDiff = try? await getDiff(for: filePath, staged: false)

        return (await stagedDiff, await unstagedDiff)
    }

    /// Check if a file has any diffs
    public func hasDiff(for filePath: String) async -> Bool {
        do {
            let diff = try await getDiffForFile(filePath)
            return diff?.hasChanges ?? false
        } catch {
            return false
        }
    }
}
