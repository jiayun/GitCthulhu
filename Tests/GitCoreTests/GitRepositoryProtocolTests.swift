//
// GitRepositoryProtocolTests.swift
// GitCthulhuTests
//
// Created by GitCthulhu Team on 2025-07-12.
//

import Testing
@testable import GitCore
import Foundation

@Suite("GitRepositoryProtocol Tests")
struct GitRepositoryProtocolTests {

    // Mock implementation for testing
    actor MockGitRepository: GitRepositoryProtocol {
        let url: URL
        let name: String
        var status: [String: GitFileStatus] = [:]
        var branches: [GitBranch] = []
        var currentBranch: GitBranch?
        var isLoading = false

        // Mock state
        var isValid = true
        var shouldThrowError = false

        init(url: URL) {
            self.url = url
            self.name = url.lastPathComponent
        }

        func isValidRepository() async -> Bool {
            isValid
        }

        func getRepositoryRoot() async throws -> String {
            if shouldThrowError {
                throw GitError.failedToOpenRepository("Mock error")
            }
            return url.path
        }

        func getCurrentBranch() async throws -> String? {
            if shouldThrowError {
                throw GitError.libgit2Error("Mock error")
            }
            return currentBranch?.name ?? "main"
        }

        func getBranches() async throws -> [String] {
            if shouldThrowError {
                throw GitError.libgit2Error("Mock error")
            }
            return branches.filter { !$0.isRemote }.map { $0.name }
        }

        func getRemoteBranches() async throws -> [String] {
            if shouldThrowError {
                throw GitError.libgit2Error("Mock error")
            }
            return branches.filter { $0.isRemote }.map { $0.name }
        }

        func createBranch(_ name: String, from baseBranch: String?) async throws {
            if shouldThrowError {
                throw GitError.libgit2Error("Mock error")
            }
            let newBranch = GitBranch(name: name, shortName: name, isRemote: false, isCurrent: false)
            branches.append(newBranch)
        }

        func switchBranch(_ branchName: String) async throws {
            if shouldThrowError {
                throw GitError.checkoutFailed("Mock error")
            }
            if let branch = branches.first(where: { $0.name == branchName }) {
                currentBranch = branch
                branches = branches.map { b in
                    GitBranch(name: b.name, shortName: b.shortName, isRemote: b.isRemote, isCurrent: b.name == branchName)
                }
            } else {
                throw GitError.invalidBranch(branchName)
            }
        }

        func deleteBranch(_ name: String, force: Bool) async throws {
            if shouldThrowError {
                throw GitError.libgit2Error("Mock error")
            }
            branches.removeAll { $0.name == name }
        }

        func getRepositoryStatus() async throws -> [String: GitFileStatus] {
            if shouldThrowError {
                throw GitError.libgit2Error("Mock error")
            }
            return status
        }

        func refreshStatus() async {
            // No-op in mock
        }

        func stageFile(_ filePath: String) async throws {
            if shouldThrowError {
                throw GitError.libgit2Error("Mock error")
            }
            status[filePath] = .added
        }

        func stageAllFiles() async throws {
            if shouldThrowError {
                throw GitError.libgit2Error("Mock error")
            }
            for (path, _) in status {
                status[path] = .added
            }
        }

        func unstageFile(_ filePath: String) async throws {
            if shouldThrowError {
                throw GitError.libgit2Error("Mock error")
            }
            status[filePath] = .modified
        }

        func unstageAllFiles() async throws {
            if shouldThrowError {
                throw GitError.libgit2Error("Mock error")
            }
            for (path, _) in status {
                status[path] = .modified
            }
        }

        func commit(message: String, author: String?) async throws -> String {
            if shouldThrowError {
                throw GitError.commitFailed("Mock error")
            }
            if status.isEmpty {
                throw GitError.noChangesToCommit
            }
            status.removeAll()
            return "abc123"
        }

        func amendCommit(message: String?) async throws -> String {
            if shouldThrowError {
                throw GitError.commitFailed("Mock error")
            }
            return "def456"
        }

        func getCommitHistory(limit: Int, branch: String?) async throws -> [String] {
            if shouldThrowError {
                throw GitError.libgit2Error("Mock error")
            }
            return ["abc123 Initial commit", "def456 Add feature"]
        }

        func getDiff(filePath: String?, staged: Bool) async throws -> String {
            if shouldThrowError {
                throw GitError.libgit2Error("Mock error")
            }
            return "diff --git a/file.txt b/file.txt\n+Hello World"
        }

        func getRemotes() async throws -> [String: String] {
            if shouldThrowError {
                throw GitError.libgit2Error("Mock error")
            }
            return ["origin": "https://github.com/user/repo.git"]
        }

        func fetch(remote: String) async throws {
            if shouldThrowError {
                throw GitError.fetchFailed("Mock error")
            }
        }

        func pull(remote: String, branch: String?) async throws {
            if shouldThrowError {
                throw GitError.pullFailed("Mock error")
            }
        }

        func push(remote: String, branch: String?, setUpstream: Bool) async throws {
            if shouldThrowError {
                throw GitError.pushFailed("Mock error")
            }
        }

        func close() async {
            // No-op in mock
        }
    }

    @Test("Protocol default implementations")
    func testDefaultImplementations() async throws {
        let repo = MockGitRepository(url: URL(fileURLWithPath: "/tmp/test"))

        // Test default branch creation (from current HEAD)
        try await repo.createBranch("feature")
        let branches = try await repo.getBranches()
        #expect(branches.contains("feature"))

        // Test default fetch (origin)
        try await repo.fetch()

        // Test default pull (origin, current branch)
        try await repo.pull()

        // Test default push (origin, current branch)
        try await repo.push()

        // Test default commit history
        let history = try await repo.getCommitHistory()
        #expect(history.count > 0)

        // Test default commit (no author)
        await repo.status["test.txt"] = .modified
        let commitId = try await repo.commit(message: "Test commit")
        #expect(commitId.count > 0)
    }

    @Test("Error handling")
    func testErrorHandling() async throws {
        let repo = MockGitRepository(url: URL(fileURLWithPath: "/tmp/test"))
        await repo.setShouldThrowError(true)

        // Test various error scenarios
        await #expect(throws: GitError.self) {
            _ = try await repo.getRepositoryRoot()
        }

        await #expect(throws: GitError.self) {
            _ = try await repo.getCurrentBranch()
        }

        await #expect(throws: GitError.self) {
            try await repo.createBranch("test")
        }

        await #expect(throws: GitError.self) {
            try await repo.switchBranch("main")
        }

        await #expect(throws: GitError.self) {
            try await repo.stageFile("test.txt")
        }

        await #expect(throws: GitError.self) {
            _ = try await repo.commit(message: "Test")
        }

        await #expect(throws: GitError.self) {
            try await repo.fetch(remote: "origin")
        }

        await #expect(throws: GitError.self) {
            try await repo.pull(remote: "origin", branch: nil)
        }

        await #expect(throws: GitError.self) {
            try await repo.push(remote: "origin", branch: nil, setUpstream: false)
        }
    }

    @Test("Branch operations")
    func testBranchOperations() async throws {
        let repo = MockGitRepository(url: URL(fileURLWithPath: "/tmp/test"))

        // Setup initial branches
        await repo.branches = [
            GitBranch(name: "main", shortName: "main", isRemote: false, isCurrent: true),
            GitBranch(name: "develop", shortName: "develop", isRemote: false, isCurrent: false),
            GitBranch(name: "origin/main", shortName: "main", isRemote: true, isCurrent: false)
        ]
        await repo.currentBranch = repo.branches[0]

        // Test getting branches
        let localBranches = try await repo.getBranches()
        #expect(localBranches.count == 2)
        #expect(localBranches.contains("main"))
        #expect(localBranches.contains("develop"))

        let remoteBranches = try await repo.getRemoteBranches()
        #expect(remoteBranches.count == 1)
        #expect(remoteBranches.contains("origin/main"))

        // Test branch creation
        try await repo.createBranch("feature", from: "main")
        let updatedBranches = try await repo.getBranches()
        #expect(updatedBranches.contains("feature"))

        // Test branch switching
        try await repo.switchBranch("develop")
        let currentBranch = try await repo.getCurrentBranch()
        #expect(currentBranch == "develop")

        // Test branch deletion
        try await repo.deleteBranch("feature", force: false)
        let finalBranches = try await repo.getBranches()
        #expect(!finalBranches.contains("feature"))
    }

    @Test("Staging operations")
    func testStagingOperations() async throws {
        let repo = MockGitRepository(url: URL(fileURLWithPath: "/tmp/test"))

        // Setup initial status
        await repo.status = [
            "file1.txt": .modified,
            "file2.txt": .modified,
            "file3.txt": .untracked
        ]

        // Test staging single file
        try await repo.stageFile("file1.txt")
        let status1 = try await repo.getRepositoryStatus()
        #expect(status1["file1.txt"] == .added)

        // Test staging all files
        try await repo.stageAllFiles()
        let status2 = try await repo.getRepositoryStatus()
        #expect(status2["file1.txt"] == .added)
        #expect(status2["file2.txt"] == .added)
        #expect(status2["file3.txt"] == .added)

        // Test unstaging single file
        try await repo.unstageFile("file1.txt")
        let status3 = try await repo.getRepositoryStatus()
        #expect(status3["file1.txt"] == .modified)

        // Test unstaging all files
        try await repo.unstageAllFiles()
        let status4 = try await repo.getRepositoryStatus()
        #expect(status4["file1.txt"] == .modified)
        #expect(status4["file2.txt"] == .modified)
        #expect(status4["file3.txt"] == .modified)
    }
}

// Helper extension for testing
extension MockGitRepository {
    func setShouldThrowError(_ value: Bool) {
        shouldThrowError = value
    }
}
