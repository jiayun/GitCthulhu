//
// GitStagingProtocol.swift
// GitCthulhu
//
// Created by GitCthulhu Team on 2025-07-15.
//

import Foundation

/// Protocol defining the interface for Git staging operations
@MainActor
public protocol GitStagingProtocol {
    /// The repository this staging manager operates on
    var repository: GitRepository { get }
    
    // MARK: - Single File Operations
    
    /// Stages a single file for commit
    /// - Parameter path: The relative path to the file to stage
    /// - Throws: GitError if the staging operation fails
    func stageFile(_ path: String) async throws
    
    /// Unstages a single file
    /// - Parameter path: The relative path to the file to unstage
    /// - Throws: GitError if the unstaging operation fails
    func unstageFile(_ path: String) async throws
    
    // MARK: - Batch Operations
    
    /// Stages multiple files for commit
    /// - Parameter paths: Array of relative paths to files to stage
    /// - Throws: GitError if any staging operation fails
    func stageFiles(_ paths: [String]) async throws
    
    /// Unstages multiple files
    /// - Parameter paths: Array of relative paths to files to unstage
    /// - Throws: GitError if any unstaging operation fails
    func unstageFiles(_ paths: [String]) async throws
    
    // MARK: - Bulk Operations
    
    /// Stages all modified and untracked files
    /// - Throws: GitError if the staging operation fails
    func stageAll() async throws
    
    /// Unstages all staged files
    /// - Throws: GitError if the unstaging operation fails
    func unstageAll() async throws
    
    // MARK: - Status Operations
    
    /// Gets the current staging status
    /// - Returns: Dictionary mapping file paths to their staging status
    /// - Throws: GitError if unable to get status
    func getStagingStatus() async throws -> [String: GitFileStatus]
    
    /// Checks if a file is staged
    /// - Parameter path: The relative path to the file
    /// - Returns: True if the file is staged, false otherwise
    /// - Throws: GitError if unable to check status
    func isFileStaged(_ path: String) async throws -> Bool
    
    /// Gets list of all staged files
    /// - Returns: Array of relative paths to staged files
    /// - Throws: GitError if unable to get staged files
    func getStagedFiles() async throws -> [String]
    
    /// Gets list of all unstaged files
    /// - Returns: Array of relative paths to unstaged files
    /// - Throws: GitError if unable to get unstaged files
    func getUnstagedFiles() async throws -> [String]
}

// MARK: - Default Implementations

public extension GitStagingProtocol {
    /// Default implementation for staging a single file using batch operation
    func stageFile(_ path: String) async throws {
        try await stageFiles([path])
    }
    
    /// Default implementation for unstaging a single file using batch operation
    func unstageFile(_ path: String) async throws {
        try await unstageFiles([path])
    }
    
    /// Default implementation for checking if a file is staged
    func isFileStaged(_ path: String) async throws -> Bool {
        let stagedFiles = try await getStagedFiles()
        return stagedFiles.contains(path)
    }
}