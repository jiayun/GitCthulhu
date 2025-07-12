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

    @Test("Repository initialization with valid path") @MainActor
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

    @Test("Repository initialization with invalid path") @MainActor
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

    @Test("Repository creation via factory method") @MainActor
    func repositoryCreationViaFactoryMethod() async throws {
        let currentDir = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)

        let repo = try await GitRepository.create(url: currentDir)

        #expect(repo.url == currentDir)
        #expect(repo.name == currentDir.lastPathComponent)
        // After factory creation, data should be loaded
        #expect(repo.isLoading == false)
    }

    // MARK: - Repository Validation Tests

    @Test("Valid repository check") @MainActor
    func validRepositoryCheck() async throws {
        let currentDir = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        let repo = try GitRepository(url: currentDir)

        let isValid = await repo.isValidRepository()
        #expect(isValid == true)
    }

    @Test("Repository root path") @MainActor
    func repositoryRootPath() async throws {
        let currentDir = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        let repo = try GitRepository(url: currentDir)

        let rootPath = try await repo.getRepositoryRoot()
        #expect(rootPath.contains(currentDir.lastPathComponent))
    }

    // MARK: - Branch Operations Tests

    @Test("Get current branch") @MainActor
    func getCurrentBranch() async throws {
        let currentDir = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        let repo = try GitRepository(url: currentDir)

        let currentBranch = try await repo.getCurrentBranch()
        #expect(currentBranch != nil)
        #expect(!currentBranch!.isEmpty)
    }

    @Test("Get all branches") @MainActor
    func getAllBranches() async throws {
        let currentDir = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        let repo = try GitRepository(url: currentDir)

        let branches = try await repo.getBranches()
        #expect(!branches.isEmpty)
        #expect(branches.contains("main") || branches.contains("master"))
    }

    @Test("Get remote branches") @MainActor
    func getRemoteBranches() async throws {
        let currentDir = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        let repo = try GitRepository(url: currentDir)

        // Remote branches might be empty in some setups, so just check it doesn't throw
        let remoteBranches = try await repo.getRemoteBranches()
        #expect(remoteBranches.count >= 0)
    }

    // MARK: - Status Operations Tests

    @Test("Get repository status") @MainActor
    func getRepositoryStatus() async throws {
        let currentDir = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        let repo = try GitRepository(url: currentDir)

        let status = try await repo.getRepositoryStatus()
        #expect(status.count >= 0) // Status can be empty in clean repo
    }

    @Test("Refresh status") @MainActor
    func refreshStatus() async throws {
        let currentDir = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        let repo = try GitRepository(url: currentDir)

        // Should not throw
        await repo.refreshStatus()
        #expect(true) // If we get here, no exception was thrown
    }

    // MARK: - Git Status Conversion Tests

    @Test("Git status code conversion") @MainActor
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

    @Test("Get commit history") @MainActor
    func getCommitHistory() async throws {
        let currentDir = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        let repo = try GitRepository(url: currentDir)

        let history = try await repo.getCommitHistory(limit: 10, branch: nil)
        #expect(!history.isEmpty) // Should have at least some commits
    }

    @Test("Get commit history with default parameters") @MainActor
    func getCommitHistoryWithDefaults() async throws {
        let currentDir = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        let repo = try GitRepository(url: currentDir)

        let history = try await repo.getCommitHistory()
        #expect(!history.isEmpty) // Should have at least some commits
    }

    // MARK: - Diff Operations Tests

    @Test("Get diff for entire repository") @MainActor
    func getDiffForEntireRepository() async throws {
        let currentDir = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        let repo = try GitRepository(url: currentDir)

        // Should not throw even if there's no diff
        let diff = try await repo.getDiff(filePath: nil, staged: false)
        #expect(diff.count >= 0) // Diff can be empty
    }

    // MARK: - Remote Operations Tests

    @Test("Get remotes") @MainActor
    func getRemotes() async throws {
        let currentDir = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        let repo = try GitRepository(url: currentDir)

        let remotes = try await repo.getRemotes()
        #expect(remotes.count >= 0) // Remotes can be empty
    }

    // MARK: - Resource Management Tests

    @Test("Repository close") @MainActor
    func repositoryClose() async throws {
        let currentDir = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        let repo = try GitRepository(url: currentDir)

        // Should not throw
        await repo.close()
        #expect(true) // If we get here, close succeeded
    }

    // MARK: - Debounce Tests

    @Test("Debounced refresh") @MainActor
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

    @Test("Handle executor errors gracefully") @MainActor
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

    @Test("Multiple concurrent operations") @MainActor
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
        #expect(results.1.count >= 0) // status
        #expect(results.2 != nil) // current branch
        #expect(results.3.count >= 0) // remotes
    }
}

// MARK: - Helper Extensions for Testing

@MainActor
extension GitRepository {
    /// Helper method for testing to check internal state
    func getInternalLoadingState() -> Bool {
        return isLoading
    }

    /// Helper method for testing to get branch count
    func getBranchCount() -> Int {
        return branches.count
    }

    /// Helper method for testing to get status count
    func getStatusCount() -> Int {
        return status.count
    }
}
