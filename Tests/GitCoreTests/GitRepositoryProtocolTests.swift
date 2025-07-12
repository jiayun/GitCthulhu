//
// GitRepositoryProtocolTests.swift
// GitCthulhu
//
// Created by GitCthulhu Team on 2025-07-12.
//

import Foundation
@testable import GitCore
import Testing

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
        name = url.lastPathComponent
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
        return branches.filter { !$0.isRemote }.map(\.name)
    }

    func getRemoteBranches() async throws -> [String] {
        if shouldThrowError {
            throw GitError.libgit2Error("Mock error")
        }
        return branches.filter(\.isRemote).map(\.name)
    }

    func createBranch(_ name: String, from baseBranch: String?) async throws {
        if shouldThrowError {
            throw GitError.libgit2Error("Mock error")
        }
        let branch = GitBranch(
            name: name,
            shortName: name,
            isRemote: false,
            isCurrent: false
        )
        branches.append(branch)
    }

    func switchToBranch(_ branchName: String) async throws {
        if shouldThrowError {
            throw GitError.checkoutFailed("Mock error")
        }
        if let branch = branches.first(where: { $0.name == branchName }) {
            currentBranch = branch
            branches = branches.map { branch in
                GitBranch(
                    name: branch.name,
                    shortName: branch.shortName,
                    isRemote: branch.isRemote,
                    isCurrent: branch.name == branchName
                )
            }
        }
    }

    func deleteBranch(_ name: String, force: Bool) async throws {
        if shouldThrowError {
            throw GitError.libgit2Error("Mock error")
        }
        branches.removeAll { $0.name == name }
    }

    func renameBranch(from oldName: String, to newName: String) async throws {
        if shouldThrowError {
            throw GitError.libgit2Error("Mock error")
        }
        if let index = branches.firstIndex(where: { $0.name == oldName }) {
            branches[index] = GitBranch(
                name: newName,
                shortName: newName,
                isRemote: branches[index].isRemote,
                isCurrent: branches[index].isCurrent
            )
        }
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
        for key in status.keys {
            status[key] = .added
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
        for key in status.keys {
            status[key] = .modified
        }
    }

    func commit(message _: String, author _: String?) async throws -> String {
        if shouldThrowError {
            throw GitError.commitFailed("Mock error")
        }
        if status.isEmpty {
            throw GitError.noChangesToCommit
        }
        status.removeAll()
        return "abc123"
    }

    func amendCommit(message _: String?) async throws -> String {
        if shouldThrowError {
            throw GitError.commitFailed("Mock error")
        }
        return "def456"
    }

    func getCommitHistory(limit _: Int, branch _: String?) async throws -> [String] {
        if shouldThrowError {
            throw GitError.libgit2Error("Mock error")
        }
        return ["abc123 Initial commit", "def456 Add feature"]
    }

    func getDiff(filePath _: String?, staged _: Bool) async throws -> String {
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

    func fetch(remote _: String) async throws {
        if shouldThrowError {
            throw GitError.fetchFailed("Mock error")
        }
    }

    func pull(remote _: String, branch _: String?) async throws {
        if shouldThrowError {
            throw GitError.pullFailed("Mock error")
        }
    }

    func push(remote _: String, branch _: String?) async throws {
        if shouldThrowError {
            throw GitError.pushFailed("Mock error")
        }
    }

    func close() async {
        // No-op in mock
    }
}

@Suite("GitRepositoryProtocol Tests")
struct GitRepositoryProtocolTests {
    @Test("Protocol default implementations")
    func defaultImplementations() async throws {
        let repo = await MockGitRepository(url: URL(fileURLWithPath: "/tmp/test"))

        // Test default name
        let name = await repo.name
        #expect(name == "test")

        // Test default validation
        let isValid = await repo.isValidRepository()
        #expect(isValid == true)

        // Test default status (empty)
        let status1 = await repo.status
        #expect(status1.isEmpty)

        // Test default branches (empty)
        let branches1 = await repo.branches
        #expect(branches1.isEmpty)

        // Test default current branch (nil)
        let currentBranch1 = await repo.currentBranch
        #expect(currentBranch1 == nil)

        // Test default loading state
        let isLoading = await repo.isLoading
        #expect(isLoading == false)

        // Test default commit history
        let history = try await repo.getCommitHistory()
        #expect(!history.isEmpty)

        // Test default commit (no author)
        await repo.setFileStatus("test.txt", status: .modified)
        let commitId = try await repo.commit(message: "Test commit")
        #expect(!commitId.isEmpty)
    }

    @Test("Error handling")
    func errorHandling() async throws {
        let repo = await MockGitRepository(url: URL(fileURLWithPath: "/tmp/test"))
        await repo.setShouldThrowError(true)

        // Test that all operations throw errors when shouldThrowError is true
        await #expect(throws: GitError.self) {
            _ = try await repo.getRepositoryRoot()
        }

        await #expect(throws: GitError.self) {
            _ = try await repo.getCurrentBranch()
        }

        await #expect(throws: GitError.self) {
            _ = try await repo.getBranches()
        }

        await #expect(throws: GitError.self) {
            _ = try await repo.getRemoteBranches()
        }

        await #expect(throws: GitError.self) {
            try await repo.createBranch("test", from: nil)
        }

        await #expect(throws: GitError.self) {
            try await repo.switchToBranch("test")
        }

        await #expect(throws: GitError.self) {
            try await repo.deleteBranch("test", force: false)
        }

        await #expect(throws: GitError.self) {
            try await repo.stageFile("test.txt")
        }

        await #expect(throws: GitError.self) {
            try await repo.commit(message: "Test")
        }

        await #expect(throws: GitError.self) {
            _ = try await repo.getCommitHistory()
        }

        await #expect(throws: GitError.self) {
            _ = try await repo.getDiff(filePath: nil, staged: false)
        }

        await #expect(throws: GitError.self) {
            _ = try await repo.getRemotes()
        }

        await #expect(throws: GitError.self) {
            try await repo.fetch(remote: "origin")
        }

        await #expect(throws: GitError.self) {
            try await repo.pull(remote: "origin", branch: "main")
        }

        await #expect(throws: GitError.self) {
            try await repo.push(remote: "origin", branch: "main")
        }
    }

    @Test("Staging operations")
    func stagingOperations() async throws {
        let repo = await MockGitRepository(url: URL(fileURLWithPath: "/tmp/test"))

        // Add some files to status
        await repo.addTestFiles()

        // Test staging individual file
        try await repo.stageFile("file1.txt")
        let status1 = await repo.status
        #expect(status1["file1.txt"] == .added)

        // Test staging all files
        try await repo.stageAllFiles()
        let status2 = await repo.status
        #expect(status2["file2.txt"] == .added)
        #expect(status2["file3.txt"] == .added)

        // Test unstaging individual file
        try await repo.unstageFile("file1.txt")
        let status3 = await repo.status
        #expect(status3["file1.txt"] == .modified)

        // Test unstaging all files
        try await repo.unstageAllFiles()
        let status4 = await repo.status
        #expect(status4["file2.txt"] == .modified)
        #expect(status4["file3.txt"] == .modified)
    }
}

// Helper extension for testing
extension MockGitRepository {
    func setShouldThrowError(_ value: Bool) {
        shouldThrowError = value
    }

    func setFileStatus(_ filePath: String, status: GitFileStatus) {
        self.status[filePath] = status
    }

    func addTestFiles() {
        status["file1.txt"] = .modified
        status["file2.txt"] = .modified
        status["file3.txt"] = .modified
    }
}
