//
// GitError.swift
// GitCthulhu
//
// Created by GitCthulhu Team on 2025-07-11.
//

import Foundation

public enum GitError: Error, LocalizedError, Equatable {
    case failedToOpenRepository(String)
    case failedToInitializeRepository(String)
    case invalidRepositoryPath
    case libgit2Error(String)
    case fileNotFound(String)
    case permissionDenied
    case networkError(String)
    case authenticationRequired
    case mergeConflict(String)
    case invalidBranch(String)
    case invalidRemote(String)
    case commitFailed(String)
    case fetchFailed(String)
    case pushFailed(String)
    case pullFailed(String)
    case checkoutFailed(String)
    case stagingFailed(String)
    case unstagingFailed(String)
    case statusFailed(String)
    case indexCorrupted
    case headDetached
    case noChangesToCommit
    case repositoryLocked
    case unknown(String)

    public var errorDescription: String? {
        switch self {
        case let .failedToOpenRepository(message):
            "Failed to open repository: \(message)"
        case let .failedToInitializeRepository(message):
            "Failed to initialize repository: \(message)"
        case .invalidRepositoryPath:
            "Invalid repository path"
        case let .libgit2Error(message):
            "Git operation failed: \(message)"
        case let .fileNotFound(path):
            "File not found: \(path)"
        case .permissionDenied:
            "Permission denied"
        case let .networkError(message):
            "Network error: \(message)"
        case .authenticationRequired:
            "Authentication required for this operation"
        case let .mergeConflict(message):
            "Merge conflict: \(message)"
        case let .invalidBranch(branch):
            "Invalid branch: \(branch)"
        case let .invalidRemote(remote):
            "Invalid remote: \(remote)"
        case let .commitFailed(message):
            "Commit failed: \(message)"
        case let .fetchFailed(message):
            "Fetch failed: \(message)"
        case let .pushFailed(message):
            "Push failed: \(message)"
        case let .pullFailed(message):
            "Pull failed: \(message)"
        case let .checkoutFailed(message):
            "Checkout failed: \(message)"
        case let .stagingFailed(message):
            "Staging failed: \(message)"
        case let .unstagingFailed(message):
            "Unstaging failed: \(message)"
        case let .statusFailed(message):
            "Status check failed: \(message)"
        case .indexCorrupted:
            "Repository index is corrupted"
        case .headDetached:
            "HEAD is in detached state"
        case .noChangesToCommit:
            "No changes to commit"
        case .repositoryLocked:
            "Repository is locked by another process"
        case let .unknown(message):
            "Unknown error: \(message)"
        }
    }

    public var recoverySuggestion: String? {
        switch self {
        case .failedToOpenRepository:
            "Ensure the directory contains a valid Git repository"
        case .failedToInitializeRepository:
            "Check write permissions and disk space"
        case .invalidRepositoryPath:
            "Select a valid Git repository directory"
        case .libgit2Error:
            "Check the Git repository state and try again"
        case .fileNotFound:
            "Verify the file exists and the path is correct"
        case .permissionDenied:
            "Check file permissions or run with appropriate privileges"
        case .networkError:
            "Check your internet connection and try again"
        case .authenticationRequired:
            "Configure your Git credentials or SSH keys"
        case .mergeConflict:
            "Resolve the conflicts before continuing"
        case .invalidBranch:
            "Specify a valid branch name"
        case .invalidRemote:
            "Add or configure the remote repository"
        case .commitFailed:
            "Stage changes before committing"
        case .fetchFailed:
            "Check network connection and remote configuration"
        case .pushFailed:
            "Pull latest changes and resolve any conflicts"
        case .pullFailed:
            "Commit or stash local changes first"
        case .checkoutFailed:
            "Commit or stash changes before switching branches"
        case .stagingFailed:
            "Check file permissions and repository state"
        case .unstagingFailed:
            "Verify files exist and are staged"
        case .statusFailed:
            "Check repository state and try again"
        case .indexCorrupted:
            "Try running 'git fsck' to repair the repository"
        case .headDetached:
            "Create a new branch or checkout an existing one"
        case .noChangesToCommit:
            "Make changes to files before committing"
        case .repositoryLocked:
            "Wait for other operations to complete or remove lock file"
        case .unknown:
            "Try the operation again or check repository state"
        }
    }
}
