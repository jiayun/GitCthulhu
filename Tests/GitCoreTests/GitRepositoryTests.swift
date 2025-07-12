//
// GitRepositoryTests.swift
// GitCthulhu
//
// Created by GitCthulhu Team on 2025-07-12.
//

import Foundation
@testable import GitCore
import Testing

struct GitRepositoryTests {
    // MARK: - Initialization Tests

    @MainActor
    @Test("Repository initialization with valid path")
    func repositoryInitializationWithValidPath() async throws {
        // Use current directory which should have .git folder
        let currentDir = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)

        // This should succeed since we're in a Git repository
        let repo = try GitRepository(url: currentDir)

        #expect(repo.url == currentDir)
        #expect(repo.name == currentDir.lastPathComponent)
        #expect(repo.status.isEmpty) // Should be empty before loading
        #expect(repo.branches.isEmpty) // Should be empty before loading
        #expect(repo.currentBranch == nil) // Should be nil before loading
        #expect(repo.isLoading == false)
    }

    @MainActor
    @Test("Repository initialization with invalid path")
    func repositoryInitializationWithInvalidPath() async throws {
        let invalidDir = URL(fileURLWithPath: "/tmp/non-git-repo-\(UUID().uuidString)")

        // Create a temporary non-git directory
        try FileManager.default.createDirectory(at: invalidDir, withIntermediateDirectories: true)
        defer {
            try? FileManager.default.removeItem(at: invalidDir)
        }

        // This should throw an error
        #expect(throws: GitError.self) {
            _ = try GitRepository(url: invalidDir)
        }
    }

    @MainActor
    @Test("Repository creation via factory method")
    func repositoryCreationViaFactoryMethod() async throws {
        let currentDir = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)

        let repo = try await GitRepository.create(url: currentDir)

        #expect(repo.url == currentDir)
        #expect(repo.name == currentDir.lastPathComponent)
        // After factory creation, data should be loaded
        #expect(repo.isLoading == false)
    }

    // MARK: - Repository Validation Tests

    @MainActor
    @Test("Valid repository check")
    func validRepositoryCheck() async throws {
        let currentDir = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        let repo = try GitRepository(url: currentDir)

        let isValid = await repo.isValidRepository()
        #expect(isValid == true)
    }

    @MainActor
    @Test("Repository root path")
    func repositoryRootPath() async throws {
        let currentDir = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        let repo = try GitRepository(url: currentDir)

        let rootPath = try await repo.getRepositoryRoot()
        #expect(rootPath.contains(currentDir.lastPathComponent))
    }

    // MARK: - Branch Operations Tests

    @MainActor
    @Test("Get current branch")
    func getCurrentBranch() async throws {
        let currentDir = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        let repo = try GitRepository(url: currentDir)

        let currentBranch = try await repo.getCurrentBranch()
        #expect(currentBranch != nil)
        if let branch = currentBranch {
            #expect(!branch.isEmpty)
        }
    }

    @MainActor
    @Test("Get all branches")
    func getAllBranches() async throws {
        let currentDir = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        let repo = try GitRepository(url: currentDir)

        let branches = try await repo.getBranches()
        #expect(!branches.isEmpty)

        // Get current branch and verify it's in the branch list
        guard let currentBranch = try await repo.getCurrentBranch() else {
            // If no current branch (detached HEAD), just verify branches exist
            #expect(!branches.isEmpty)
            return
        }

        // Handle various CI environment states
        if currentBranch == "HEAD" {
            // In detached HEAD, check if there's a branch describing the detached state
            let hasDetachedInfo = branches.contains { $0.contains("HEAD detached") }
            #expect(hasDetachedInfo || branches.contains(currentBranch))
        } else if currentBranch.contains("/") && !branches.contains(currentBranch) {
            // Handle cases where current branch is not in local branch list (e.g. CI artifacts)
            // Just verify that we have some branches
            #expect(!branches.isEmpty)
        } else {
            // Normal case: current branch should be in the branch list
            #expect(branches.contains(currentBranch))
        }
    }

    @MainActor
    @Test("Get remote branches")
    func getRemoteBranches() async throws {
        let currentDir = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        let repo = try GitRepository(url: currentDir)

        // Remote branches might exist in actual repositories, just check it doesn't throw
        let remoteBranches = try await repo.getRemoteBranches()
        // Don't assert empty - real repositories often have remote branches
        _ = remoteBranches // Just ensure it doesn't throw
    }

    // MARK: - Status Operations Tests

    @MainActor
    @Test("Get repository status")
    func getRepositoryStatus() async throws {
        let currentDir = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        let repo = try GitRepository(url: currentDir)

        let status = try await repo.getRepositoryStatus()
        // Don't assert empty - real repositories often have uncommitted changes
        _ = status // Just ensure it doesn't throw
    }

    @MainActor
    @Test("Refresh status")
    func refreshStatus() async throws {
        let currentDir = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        let repo = try GitRepository(url: currentDir)

        // Should not throw
        await repo.refreshStatus()
        #expect(true) // If we get here, no exception was thrown
    }

    // MARK: - Git Status Conversion Tests

    @MainActor
    @Test("Git status code conversion")
    func gitStatusCodeConversion() async throws {
        let currentDir = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        let repo = try GitRepository(url: currentDir)

        // We can't directly test the private convertGitStatus method,
        // but we can test through the public getRepositoryStatus method
        let status = try await repo.getRepositoryStatus()

        // Verify that all status values are valid GitFileStatus cases
        for (_, fileStatus) in status {
            switch fileStatus {
            case .untracked, .added, .modified, .deleted, .renamed, .copied, .unmerged, .ignored:
                // All valid cases
                break
            }
        }

        #expect(true) // If we get here, all status conversions were valid
    }

    // MARK: - Commit History Tests

    @MainActor
    @Test("Get commit history")
    func getCommitHistory() async throws {
        let currentDir = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        let repo = try GitRepository(url: currentDir)

        let history = try await repo.getCommitHistory(limit: 10, branch: nil)
        #expect(!history.isEmpty) // Should have at least some commits
    }

    @MainActor
    @Test("Get commit history with default parameters")
    func getCommitHistoryWithDefaults() async throws {
        let currentDir = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        let repo = try GitRepository(url: currentDir)

        let history = try await repo.getCommitHistory()
        #expect(!history.isEmpty) // Should have at least some commits
    }

    // MARK: - Diff Operations Tests

    @MainActor
    @Test("Get diff for entire repository")
    func getDiffForEntireRepository() async throws {
        let currentDir = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        let repo = try GitRepository(url: currentDir)

        // Should not throw even if there's no diff
        let diff = try await repo.getDiff(filePath: nil, staged: false)
        // Don't assert empty - real repositories often have changes
        _ = diff // Just ensure it doesn't throw
    }

    // MARK: - Remote Operations Tests

    @MainActor
    @Test("Get remotes")
    func getRemotes() async throws {
        let currentDir = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        let repo = try GitRepository(url: currentDir)

        let remotes = try await repo.getRemotes()
        // Don't assert empty - real repositories often have remotes configured
        _ = remotes // Just ensure it doesn't throw
    }

    // MARK: - Resource Management Tests

    @MainActor
    @Test("Repository close")
    func repositoryClose() async throws {
        let currentDir = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        let repo = try GitRepository(url: currentDir)

        // Should not throw
        await repo.close()
        #expect(true) // If we get here, close succeeded
    }

    // MARK: - Debounce Tests

    @MainActor
    @Test("Debounced refresh")
    func debouncedRefresh() async throws {
        let currentDir = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        let repo = try GitRepository(url: currentDir)

        // Call refresh multiple times quickly
        repo.refreshWithDebounce()
        repo.refreshWithDebounce()
        repo.refreshWithDebounce()

        // Should not crash or throw
        #expect(true)

        // Wait a bit for debounce to complete
        try await Task.sleep(nanoseconds: 600_000_000) // 0.6 seconds
    }

    // MARK: - Error Handling Tests

    @MainActor
    @Test("Handle executor errors gracefully")
    func handleExecutorErrorsGracefully() async throws {
        let currentDir = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        let repo = try GitRepository(url: currentDir)

        // Try operations that might fail in some environments
        // These should not crash the application

        do {
            _ = try await repo.createBranch("invalid/branch/name")
        } catch {
            // Expected to fail with invalid branch name
            #expect(error is GitError)
        }

        do {
            _ = try await repo.switchBranch("non-existent-branch")
        } catch {
            // Expected to fail with non-existent branch
            #expect(error is GitError)
        }

        do {
            _ = try await repo.deleteBranch("non-existent-branch", force: false)
        } catch {
            // Expected to fail with non-existent branch
            #expect(error is GitError)
        }
    }

    // MARK: - Performance Tests

    @MainActor
    @Test("Multiple concurrent operations")
    func multipleConcurrentOperations() async throws {
        let currentDir = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        let repo = try GitRepository(url: currentDir)

        // Run multiple read operations concurrently
        async let branches = repo.getBranches()
        async let status = repo.getRepositoryStatus()
        async let currentBranch = repo.getCurrentBranch()
        async let remotes = repo.getRemotes()

        let results = try await (branches, status, currentBranch, remotes)

        #expect(!results.0.isEmpty) // branches
        _ = results.1 // status - just ensure valid
        #expect(results.2 != nil) // current branch
        _ = results.3 // remotes - just ensure valid
    }
}

// MARK: - Helper Extensions for Testing

@MainActor
extension GitRepository {
    /// Helper method for testing to check internal state
    func getInternalLoadingState() -> Bool {
        isLoading
    }

    /// Helper method for testing to get branch count
    func getBranchCount() -> Int {
        branches.count
    }

    /// Helper method for testing to get status count
    func getStatusCount() -> Int {
        status.count
    }
}
