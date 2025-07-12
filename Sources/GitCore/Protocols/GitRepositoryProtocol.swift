//
// GitRepositoryProtocol.swift
// GitCthulhu
//
// Created by GitCthulhu Team on 2025-07-12.
//

import Foundation

/// Protocol defining the interface for Git repository operations
@MainActor
public protocol GitRepositoryProtocol: AnyObject {
    /// The file system URL of the repository
    var url: URL { get }

    /// The name of the repository (usually the directory name)
    var name: String { get }

    /// Current status of files in the repository
    var status: [String: GitFileStatus] { get }

    /// List of all branches in the repository
    var branches: [GitBranch] { get }

    /// The currently checked out branch
    var currentBranch: GitBranch? { get }

    /// Whether the repository is currently loading data
    var isLoading: Bool { get }

    // MARK: - Repository Information

    /// Validates if the repository is valid
    func isValidRepository() async -> Bool

    /// Gets the root directory of the repository
    func getRepositoryRoot() async throws -> String

    // MARK: - Branch Operations

    /// Gets the current branch name
    func getCurrentBranch() async throws -> String?

    /// Gets all local branches
    func getBranches() async throws -> [String]

    /// Gets all remote branches
    func getRemoteBranches() async throws -> [String]

    /// Creates a new branch
    func createBranch(_ name: String, from baseBranch: String?) async throws

    /// Switches to a different branch
    func switchBranch(_ branchName: String) async throws

    /// Deletes a branch
    func deleteBranch(_ name: String, force: Bool) async throws

    // MARK: - Status Operations

    /// Gets the status of all files in the repository
    func getRepositoryStatus() async throws -> [String: GitFileStatus]

    /// Refreshes the repository status
    func refreshStatus() async

    // MARK: - Staging Operations

    /// Stages a file for commit
    func stageFile(_ filePath: String) async throws

    /// Stages all files for commit
    func stageAllFiles() async throws

    /// Unstages a file
    func unstageFile(_ filePath: String) async throws

    /// Unstages all files
    func unstageAllFiles() async throws

    // MARK: - Commit Operations

    /// Creates a commit with the staged changes
    func commit(message: String, author: String?) async throws -> String

    /// Amends the last commit
    func amendCommit(message: String?) async throws -> String

    /// Gets the commit history
    func getCommitHistory(limit: Int, branch: String?) async throws -> [String]

    // MARK: - Diff Operations

    /// Gets the diff for a file or the entire repository
    func getDiff(filePath: String?, staged: Bool) async throws -> String

    // MARK: - Remote Operations

    /// Gets all configured remotes
    func getRemotes() async throws -> [String: String]

    /// Fetches from a remote
    func fetch(remote: String) async throws

    /// Pulls from a remote
    func pull(remote: String, branch: String?) async throws

    /// Pushes to a remote
    func push(remote: String, branch: String?, setUpstream: Bool) async throws

    // MARK: - Resource Management

    /// Closes the repository and releases resources
    func close() async
}

// MARK: - Default Implementations

public extension GitRepositoryProtocol {
    /// Default implementation for creating a branch from current HEAD
    func createBranch(_ name: String) async throws {
        try await createBranch(name, from: nil)
    }

    /// Default implementation for fetching from origin
    func fetch() async throws {
        try await fetch(remote: "origin")
    }

    /// Default implementation for pulling from origin
    func pull() async throws {
        try await pull(remote: "origin", branch: nil)
    }

    /// Default implementation for pushing to origin
    func push() async throws {
        try await push(remote: "origin", branch: nil, setUpstream: false)
    }

    /// Default implementation for getting recent commit history
    func getCommitHistory() async throws -> [String] {
        try await getCommitHistory(limit: 100, branch: nil)
    }

    /// Default implementation for committing without author
    func commit(message: String) async throws -> String {
        try await commit(message: message, author: nil)
    }
}
