//
// LibGit2Repository.swift
// GitCthulhu
//
// Created by GitCthulhu Team on 2025-07-12.
//

import Foundation
import SwiftGit2
import Utilities

/// Implementation of GitRepositoryProtocol using libgit2
@MainActor
public class LibGit2Repository: ObservableObject, GitRepositoryProtocol, Identifiable {
    public let id = UUID()
    public let url: URL
    public let name: String

    @Published public var status: [String: GitFileStatus] = [:]
    @Published public var branches: [GitBranch] = []
    @Published public var currentBranch: GitBranch?
    @Published public var isLoading = false

    private var repository: Repository?
    private let logger = Logger(category: "LibGit2Repository")
    private let wrapper: LibGit2Wrapper

    public init(url: URL) throws {
        self.url = url
        self.name = url.lastPathComponent
        self.wrapper = LibGit2Wrapper()

        // Open the repository
        do {
            self.repository = try Repository.at(url)
            logger.info("Successfully opened repository at \(url.path)")

            // Load initial data
            Task { @MainActor in
                await loadRepositoryData()
            }
        } catch {
            logger.error("Failed to open repository: \(error.localizedDescription)")
            throw GitError.failedToOpenRepository(error.localizedDescription)
        }
    }

    // MARK: - Private Methods

    private func loadRepositoryData() async {
        isLoading = true

        do {
            // Load current branch
            if let currentBranchName = try await getCurrentBranch() {
                currentBranch = GitBranch(
                    name: currentBranchName,
                    shortName: currentBranchName,
                    isCurrent: true
                )
            }

            // Load all branches
            let localBranches = try await getBranches()
            let remoteBranches = try await getRemoteBranches()

            self.branches = localBranches.map { branchName in
                GitBranch(
                    name: branchName,
                    shortName: branchName,
                    isRemote: false,
                    isCurrent: branchName == currentBranch?.name
                )
            } + remoteBranches.map { branchName in
                GitBranch(
                    name: branchName,
                    shortName: branchName.components(separatedBy: "/").last ?? branchName,
                    isRemote: true,
                    isCurrent: false
                )
            }

            // Load status
            await refreshStatus()

        } catch {
            logger.error("Failed to load repository data: \(error.localizedDescription)")
        }

        isLoading = false
    }

    // MARK: - GitRepositoryProtocol Implementation

    public func isValidRepository() async -> Bool {
        repository != nil
    }

    public func getRepositoryRoot() async throws -> String {
        guard let repo = repository else {
            throw GitError.failedToOpenRepository("Repository not initialized")
        }
        return repo.directoryURL?.path ?? url.path
    }

    // MARK: - Branch Operations

    public func getCurrentBranch() async throws -> String? {
        guard let repo = repository else {
            throw GitError.failedToOpenRepository("Repository not initialized")
        }

        do {
            let head = try repo.HEAD()
            return head.shortName ?? head.name
        } catch {
            // Might be in detached HEAD state
            logger.warning("Could not get current branch: \(error.localizedDescription)")
            return nil
        }
    }

    public func getBranches() async throws -> [String] {
        guard let repo = repository else {
            throw GitError.failedToOpenRepository("Repository not initialized")
        }

        do {
            let branches = try repo.localBranches()
            return branches.compactMap { $0.shortName }
        } catch {
            logger.error("Failed to get branches: \(error.localizedDescription)")
            throw GitError.libgit2Error(error.localizedDescription)
        }
    }

    public func getRemoteBranches() async throws -> [String] {
        guard let repo = repository else {
            throw GitError.failedToOpenRepository("Repository not initialized")
        }

        do {
            let branches = try repo.remoteBranches()
            return branches.compactMap { $0.name }
        } catch {
            logger.error("Failed to get remote branches: \(error.localizedDescription)")
            throw GitError.libgit2Error(error.localizedDescription)
        }
    }

    public func createBranch(_ name: String, from baseBranch: String?) async throws {
        guard let repo = repository else {
            throw GitError.failedToOpenRepository("Repository not initialized")
        }

        do {
            let commit: Commit
            if let baseBranch = baseBranch {
                // Create from specific branch
                let branch = try repo.localBranches().first { $0.shortName == baseBranch }
                guard let branch = branch else {
                    throw GitError.libgit2Error("Branch '\(baseBranch)' not found")
                }
                commit = try branch.commit()
            } else {
                // Create from HEAD
                commit = try repo.HEAD().commit()
            }

            _ = try repo.createBranch(name, from: commit)
            await loadRepositoryData()
        } catch {
            logger.error("Failed to create branch: \(error.localizedDescription)")
            throw GitError.libgit2Error(error.localizedDescription)
        }
    }

    public func switchBranch(_ branchName: String) async throws {
        guard let repo = repository else {
            throw GitError.failedToOpenRepository("Repository not initialized")
        }

        do {
            let branches = try repo.localBranches()
            guard let branch = branches.first(where: { $0.shortName == branchName }) else {
                throw GitError.libgit2Error("Branch '\(branchName)' not found")
            }

            try repo.checkout(branch)
            await loadRepositoryData()
        } catch {
            logger.error("Failed to switch branch: \(error.localizedDescription)")
            throw GitError.libgit2Error(error.localizedDescription)
        }
    }

    public func deleteBranch(_ name: String, force: Bool) async throws {
        guard let repo = repository else {
            throw GitError.failedToOpenRepository("Repository not initialized")
        }

        do {
            let branches = try repo.localBranches()
            guard let branch = branches.first(where: { $0.shortName == name }) else {
                throw GitError.libgit2Error("Branch '\(name)' not found")
            }

            try branch.delete()
            await loadRepositoryData()
        } catch {
            logger.error("Failed to delete branch: \(error.localizedDescription)")
            throw GitError.libgit2Error(error.localizedDescription)
        }
    }

    // MARK: - Status Operations

    public func getRepositoryStatus() async throws -> [String: GitFileStatus] {
        guard let repo = repository else {
            throw GitError.failedToOpenRepository("Repository not initialized")
        }

        do {
            let statusEntries = try repo.status()
            var statusMap: [String: GitFileStatus] = [:]

            for entry in statusEntries {
                let status = convertStatusFlags(entry.status)
                statusMap[entry.path] = status
            }

            return statusMap
        } catch {
            logger.error("Failed to get repository status: \(error.localizedDescription)")
            throw GitError.libgit2Error(error.localizedDescription)
        }
    }

    public func refreshStatus() async {
        do {
            status = try await getRepositoryStatus()
        } catch {
            logger.error("Failed to refresh status: \(error.localizedDescription)")
        }
    }

    private func convertStatusFlags(_ flags: Diff.Status) -> GitFileStatus {
        if flags.contains(.workTreeNew) || flags.contains(.indexNew) {
            return .untracked
        } else if flags.contains(.indexModified) || flags.contains(.workTreeModified) {
            return .modified
        } else if flags.contains(.indexDeleted) || flags.contains(.workTreeDeleted) {
            return .deleted
        } else if flags.contains(.indexRenamed) || flags.contains(.workTreeRenamed) {
            return .renamed
        } else if flags.contains(.conflicted) {
            return .unmerged
        } else {
            return .modified
        }
    }

    // MARK: - Staging Operations

    public func stageFile(_ filePath: String) async throws {
        guard let repo = repository else {
            throw GitError.failedToOpenRepository("Repository not initialized")
        }

        do {
            try wrapper.stageFile(in: repo, path: filePath)
            await refreshStatus()
        } catch {
            logger.error("Failed to stage file: \(error.localizedDescription)")
            throw GitError.libgit2Error(error.localizedDescription)
        }
    }

    public func stageAllFiles() async throws {
        guard let repo = repository else {
            throw GitError.failedToOpenRepository("Repository not initialized")
        }

        do {
            try wrapper.stageAllFiles(in: repo)
            await refreshStatus()
        } catch {
            logger.error("Failed to stage all files: \(error.localizedDescription)")
            throw GitError.libgit2Error(error.localizedDescription)
        }
    }

    public func unstageFile(_ filePath: String) async throws {
        guard let repo = repository else {
            throw GitError.failedToOpenRepository("Repository not initialized")
        }

        do {
            try wrapper.unstageFile(in: repo, path: filePath)
            await refreshStatus()
        } catch {
            logger.error("Failed to unstage file: \(error.localizedDescription)")
            throw GitError.libgit2Error(error.localizedDescription)
        }
    }

    public func unstageAllFiles() async throws {
        guard let repo = repository else {
            throw GitError.failedToOpenRepository("Repository not initialized")
        }

        do {
            try wrapper.unstageAllFiles(in: repo)
            await refreshStatus()
        } catch {
            logger.error("Failed to unstage all files: \(error.localizedDescription)")
            throw GitError.libgit2Error(error.localizedDescription)
        }
    }

    // MARK: - Commit Operations

    public func commit(message: String, author: String?) async throws -> String {
        guard let repo = repository else {
            throw GitError.failedToOpenRepository("Repository not initialized")
        }

        do {
            let commitOid = try wrapper.createCommit(in: repo, message: message, author: author)
            await loadRepositoryData()
            return commitOid.description
        } catch {
            logger.error("Failed to create commit: \(error.localizedDescription)")
            throw GitError.libgit2Error(error.localizedDescription)
        }
    }

    public func amendCommit(message: String?) async throws -> String {
        guard let repo = repository else {
            throw GitError.failedToOpenRepository("Repository not initialized")
        }

        do {
            let commitOid = try wrapper.amendCommit(in: repo, message: message)
            await loadRepositoryData()
            return commitOid.description
        } catch {
            logger.error("Failed to amend commit: \(error.localizedDescription)")
            throw GitError.libgit2Error(error.localizedDescription)
        }
    }

    public func getCommitHistory(limit: Int, branch: String?) async throws -> [String] {
        guard let repo = repository else {
            throw GitError.failedToOpenRepository("Repository not initialized")
        }

        do {
            let commits = try wrapper.getCommitHistory(in: repo, limit: limit, branch: branch)
            return commits.map { commit in
                "\(commit.oid.description.prefix(7)) \(commit.message.trimmingCharacters(in: .whitespacesAndNewlines))"
            }
        } catch {
            logger.error("Failed to get commit history: \(error.localizedDescription)")
            throw GitError.libgit2Error(error.localizedDescription)
        }
    }

    // MARK: - Diff Operations

    public func getDiff(filePath: String?, staged: Bool) async throws -> String {
        guard let repo = repository else {
            throw GitError.failedToOpenRepository("Repository not initialized")
        }

        do {
            return try wrapper.getDiff(in: repo, filePath: filePath, staged: staged)
        } catch {
            logger.error("Failed to get diff: \(error.localizedDescription)")
            throw GitError.libgit2Error(error.localizedDescription)
        }
    }

    // MARK: - Remote Operations

    public func getRemotes() async throws -> [String: String] {
        guard let repo = repository else {
            throw GitError.failedToOpenRepository("Repository not initialized")
        }

        do {
            let remotes = try repo.remotes()
            var remoteMap: [String: String] = [:]

            for remote in remotes {
                if let url = remote.url {
                    remoteMap[remote.name] = url
                }
            }

            return remoteMap
        } catch {
            logger.error("Failed to get remotes: \(error.localizedDescription)")
            throw GitError.libgit2Error(error.localizedDescription)
        }
    }

    public func fetch(remote: String) async throws {
        guard let repo = repository else {
            throw GitError.failedToOpenRepository("Repository not initialized")
        }

        do {
            try wrapper.fetch(in: repo, remote: remote)
        } catch {
            logger.error("Failed to fetch: \(error.localizedDescription)")
            throw GitError.libgit2Error(error.localizedDescription)
        }
    }

    public func pull(remote: String, branch: String?) async throws {
        guard let repo = repository else {
            throw GitError.failedToOpenRepository("Repository not initialized")
        }

        do {
            try wrapper.pull(in: repo, remote: remote, branch: branch)
            await loadRepositoryData()
        } catch {
            logger.error("Failed to pull: \(error.localizedDescription)")
            throw GitError.libgit2Error(error.localizedDescription)
        }
    }

    public func push(remote: String, branch: String?, setUpstream: Bool) async throws {
        guard let repo = repository else {
            throw GitError.failedToOpenRepository("Repository not initialized")
        }

        do {
            try wrapper.push(in: repo, remote: remote, branch: branch, setUpstream: setUpstream)
        } catch {
            logger.error("Failed to push: \(error.localizedDescription)")
            throw GitError.libgit2Error(error.localizedDescription)
        }
    }

    // MARK: - Resource Management

    public func close() async {
        repository = nil
        logger.info("Repository closed")
    }

    deinit {
        repository = nil
    }
}
