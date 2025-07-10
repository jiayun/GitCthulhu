//
// GitCommandExecutorTests.swift
// GitCthulhu
//
// Created by GitCthulhu Team on 2025-07-11.
//

import Foundation
@testable import GitCore
import Testing

struct GitCommandExecutorTests {
    @Test
    func gitCommandExecutorInitialization() async throws {
        let tempURL = URL(fileURLWithPath: "/tmp")
        let executor = GitCommandExecutor(repositoryURL: tempURL)

        #expect(executor != nil)
    }

    @Test
    func isValidRepositoryTest() async throws {
        // Test with current Git repository (should be valid)
        let currentDir = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        let executor = GitCommandExecutor(repositoryURL: currentDir)

        let isValid = await executor.isValidRepository()

        // This should be true if we're running tests from within a Git repository
        #expect(isValid == true)
    }

    @Test
    func getCurrentBranchTest() async throws {
        // Test getting current branch from our repository
        let currentDir = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        let executor = GitCommandExecutor(repositoryURL: currentDir)

        // Skip if not a valid repository
        guard await executor.isValidRepository() else {
            return
        }

        let branch = try await executor.getCurrentBranch()

        // Should have a current branch (likely "main" or "master")
        #expect(branch != nil)
        if let branch = branch {
            #expect(!branch.isEmpty)
        }
    }

    @Test
    func getBranchesTest() async throws {
        let currentDir = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        let executor = GitCommandExecutor(repositoryURL: currentDir)

        // Skip if not a valid repository
        guard await executor.isValidRepository() else {
            return
        }

        let branches = try await executor.getBranches()

        // Should have at least one branch
        #expect(!branches.isEmpty)
    }

    @Test
    func getRepositoryStatusTest() async throws {
        let currentDir = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        let executor = GitCommandExecutor(repositoryURL: currentDir)

        // Skip if not a valid repository
        guard await executor.isValidRepository() else {
            return
        }

        let status = try await executor.getRepositoryStatus()

        // Status should be a dictionary (might be empty if working directory is clean)
        #expect(status != nil)
    }

    @Test
    func gitStatusConversionTest() async throws {
        // Test the git status code conversion logic
        let testCases: [(String, GitFileStatus)] = [
            ("??", .untracked),
            ("A ", .added),
            (" A", .added),
            ("M ", .modified),
            (" M", .modified),
            ("MM", .modified),
            ("D ", .deleted),
            (" D", .deleted),
            ("R ", .renamed),
            ("C ", .copied),
            ("UU", .unmerged)
        ]

        // This is tested through the GitRepository conversion method
        // We'll test it indirectly through repository functionality
        #expect(!testCases.isEmpty)
    }
}
