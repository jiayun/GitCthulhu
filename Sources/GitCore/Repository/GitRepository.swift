//
// GitRepository.swift
// GitCthulhu
//
// Created by GitCthulhu Team on 2025-07-11.
//

import Foundation
import Utilities

/// CLI-based implementation of GitRepositoryProtocol
/// This implementation uses the git command-line interface
@MainActor
public class GitRepository: ObservableObject, GitRepositoryProtocol, Identifiable {
    public let id = UUID()
    public let url: URL
    public let name: String

    private let gitExecutor: GitCommandExecutor
    private let logger = Logger(category: "GitRepository")

    @Published public var status: [String: GitFileStatus] = [:]
    @Published public var branches: [GitBranch] = []
    @Published public var currentBranch: GitBranch?
    @Published public var isLoading = false

    public init(url: URL) throws {
        self.url = url
        name = url.lastPathComponent
        gitExecutor = GitCommandExecutor(repositoryURL: url)

        // Validate that this is a git repository
        let gitDir = url.appendingPathComponent(".git")
        guard FileManager.default.fileExists(atPath: gitDir.path) else {
            throw GitError.failedToOpenRepository("No .git directory found at \(url.path)")
        }

        // Load initial data
        Task { @MainActor in
            await loadRepositoryData()
        }
    }

    @MainActor
    private func loadRepositoryData() async {
        isLoading = true

        // Verify this is a valid Git repository first
        guard await gitExecutor.isValidRepository() else {
            logger.error("Invalid Git repository at \(url.path)")
            isLoading = false
            return
        }

        await loadCurrentBranch()
        await loadBranches()
        await loadStatus()

        isLoading = false
    }

    @MainActor
    private func loadCurrentBranch() async {
        do {
            if let branchName = try await gitExecutor.getCurrentBranch() {
                currentBranch = GitBranch(
                    name: branchName,
                    shortName: branchName,
                    isCurrent: true
                )
                logger.info("Current branch: \(branchName)")
            }
        } catch {
            logger.warning("Could not load current branch: \(error.localizedDescription)")
        }
    }

    @MainActor
    private func loadBranches() async {
        do {
            // Load local branches
            let localBranchNames = try await gitExecutor.getBranches()
            let localBranches = localBranchNames.map { branchName in
                let isCurrent = branchName == currentBranch?.shortName
                return GitBranch(
                    name: branchName,
                    shortName: branchName,
                    isRemote: false,
                    isCurrent: isCurrent
                )
            }

            // Load remote branches
            let remoteBranchNames = try await gitExecutor.getRemoteBranches()
            let remoteBranches = remoteBranchNames.map { branchName in
                GitBranch(
                    name: branchName,
                    shortName: branchName.components(separatedBy: "/").last ?? branchName,
                    isRemote: true,
                    isCurrent: false
                )
            }

            branches = localBranches + remoteBranches
            logger.info("Loaded \(localBranches.count) local and \(remoteBranches.count) remote branches")
        } catch {
            logger.warning("Could not load branches: \(error.localizedDescription)")
        }
    }

    @MainActor
    private func loadStatus() async {
        do {
            let statusMap = try await gitExecutor.getRepositoryStatus()
            var convertedStatus: [String: GitFileStatus] = [:]

            for (fileName, statusCode) in statusMap {
                let gitStatus = convertGitStatus(statusCode)
                convertedStatus[fileName] = gitStatus
            }

            status = convertedStatus
            logger.info("Loaded status for \(status.count) files")
        } catch {
            logger.warning("Could not load repository status: \(error.localizedDescription)")
        }
    }

    private func convertGitStatus(_ statusCode: String) -> GitFileStatus {
        switch statusCode.prefix(2) {
        case "??": .untracked
        case "A ", " A": .added
        case "M ", " M", "MM": .modified
        case "D ", " D": .deleted
        case "R ", " R": .renamed
        case "C ", " C": .copied
        case "UU", "AA", "DD": .unmerged
        default: .modified
        }
    }

    // MARK: - GitRepositoryProtocol Implementation

    public func isValidRepository() async -> Bool {
        await gitExecutor.isValidRepository()
    }

    public func getRepositoryRoot() async throws -> String {
        try await gitExecutor.getRepositoryRoot()
    }

    public func getCurrentBranch() async throws -> String? {
        try await gitExecutor.getCurrentBranch()
    }

    public func getBranches() async throws -> [String] {
        try await gitExecutor.getBranches()
    }

    public func getRemoteBranches() async throws -> [String] {
        try await gitExecutor.getRemoteBranches()
    }

    public func deleteBranch(_ name: String, force: Bool) async throws {
        try await gitExecutor.deleteBranch(name, force: force)
        await loadBranches()
    }

    public func getRepositoryStatus() async throws -> [String: GitFileStatus] {
        let statusMap = try await gitExecutor.getRepositoryStatus()
        var convertedStatus: [String: GitFileStatus] = [:]

        for (fileName, statusCode) in statusMap {
            let gitStatus = convertGitStatus(statusCode)
            convertedStatus[fileName] = gitStatus
        }

        return convertedStatus
    }

    public func refreshStatus() async {
        await loadStatus()
    }

    public func stageFile(_ filePath: String) async throws {
        try await gitExecutor.stageFile(filePath)
        await refreshStatus()
    }

    public func stageAllFiles() async throws {
        try await gitExecutor.stageAllFiles()
        await refreshStatus()
    }

    public func unstageFile(_ filePath: String) async throws {
        try await gitExecutor.unstageFile(filePath)
        await refreshStatus()
    }

    public func unstageAllFiles() async throws {
        try await gitExecutor.unstageAllFiles()
        await refreshStatus()
    }

    public func commit(message: String, author: String? = nil) async throws -> String {
        let result = try await gitExecutor.commit(message: message, author: author)
        await loadRepositoryData()
        return result
    }

    public func amendCommit(message: String?) async throws -> String {
        let result = try await gitExecutor.amendCommit(message: message)
        await loadRepositoryData()
        return result
    }

    public func getCommitHistory(limit: Int, branch: String?) async throws -> [String] {
        try await gitExecutor.getCommitHistory(limit: limit, branch: branch)
    }

    public func getDiff(filePath: String?, staged: Bool) async throws -> String {
        try await gitExecutor.getDiff(filePath: filePath, staged: staged)
    }

    public func getRemotes() async throws -> [String: String] {
        try await gitExecutor.getRemotes()
    }

    public func fetch(remote: String) async throws {
        try await gitExecutor.fetch(remote: remote)
    }

    public func pull(remote: String, branch: String?) async throws {
        try await gitExecutor.pull(remote: remote, branch: branch)
        await loadRepositoryData()
    }

    public func push(remote: String, branch: String?, setUpstream: Bool) async throws {
        try await gitExecutor.push(remote: remote, branch: branch, setUpstream: setUpstream)
    }

    public func switchBranch(_ branchName: String) async throws {
        try await gitExecutor.switchBranch(branchName)
        await loadRepositoryData()
    }

    public func createBranch(_ name: String, from baseBranch: String? = nil) async throws {
        try await gitExecutor.createBranch(name, from: baseBranch)
        await loadBranches()
    }

    public func close() async {
        // No special cleanup needed for CLI-based implementation
        logger.info("Repository closed")
    }
}
