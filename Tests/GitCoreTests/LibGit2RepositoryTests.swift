//
// LibGit2RepositoryTests.swift
// GitCthulhu
//
// Created by GitCthulhu Team on 2025-07-12.
//

import Foundation
@testable import GitCore
import Testing

// TODO: Re-enable when LibGit2Repository is available
/*
 @Suite("LibGit2Repository Tests")
 struct LibGit2RepositoryTests {

     // Helper to create a temporary test repository
     func createTestRepository() async throws -> (URL, LibGit2Repository) {
         let tempDir = FileManager.default.temporaryDirectory
             .appendingPathComponent(UUID().uuidString)
         try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)

         // Initialize a git repository
         let process = Process()
         process.executableURL = URL(fileURLWithPath: "/usr/bin/git")
         process.arguments = ["init"]
         process.currentDirectoryURL = tempDir

         let pipe = Pipe()
         process.standardOutput = pipe
         process.standardError = pipe

         try process.run()
         process.waitUntilExit()

         guard process.terminationStatus == 0 else {
             throw GitError.failedToInitializeRepository("Failed to create test repository")
         }

         // Configure git user for tests
         let configProcess1 = Process()
         configProcess1.executableURL = URL(fileURLWithPath: "/usr/bin/git")
         configProcess1.arguments = ["config", "user.email", "test@example.com"]
         configProcess1.currentDirectoryURL = tempDir
         try configProcess1.run()
         configProcess1.waitUntilExit()

         let configProcess2 = Process()
         configProcess2.executableURL = URL(fileURLWithPath: "/usr/bin/git")
         configProcess2.arguments = ["config", "user.name", "Test User"]
         configProcess2.currentDirectoryURL = tempDir
         try configProcess2.run()
         configProcess2.waitUntilExit()

         let repository = try LibGit2Repository(url: tempDir)
         return (tempDir, repository)
     }

     func cleanupTestRepository(_ url: URL) {
         try? FileManager.default.removeItem(at: url)
     }

     @Test("Repository initialization")
     func testRepositoryInitialization() async throws {
         let (tempDir, repository) = try await createTestRepository()
         defer { cleanupTestRepository(tempDir) }

         #expect(repository.url == tempDir)
         #expect(repository.name == tempDir.lastPathComponent)
         #expect(await repository.isValidRepository())

         let root = try await repository.getRepositoryRoot()
         #expect(root == tempDir.path)
     }

     @Test("Invalid repository handling")
     func testInvalidRepository() async throws {
         let tempDir = FileManager.default.temporaryDirectory
             .appendingPathComponent(UUID().uuidString)
         try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
         defer { cleanupTestRepository(tempDir) }

         await #expect(throws: GitError.self) {
             _ = try LibGit2Repository(url: tempDir)
         }
     }

     @Test("Branch operations")
     func testBranchOperations() async throws {
         let (tempDir, repository) = try await createTestRepository()
         defer { cleanupTestRepository(tempDir) }

         // Create initial commit
         let testFile = tempDir.appendingPathComponent("test.txt")
         try "Hello World".write(to: testFile, atomically: true, encoding: .utf8)
         try await repository.stageAllFiles()
         _ = try await repository.commit(message: "Initial commit")

         // Test branch creation
         try await repository.createBranch("feature", from: nil)
         let branches = try await repository.getBranches()
         #expect(branches.contains("feature"))

         // Test branch switching
         try await repository.switchBranch("feature")
         let currentBranch = try await repository.getCurrentBranch()
         #expect(currentBranch == "feature")

         // Test branch deletion
         try await repository.switchBranch("main")
         try await repository.deleteBranch("feature", force: false)
         let updatedBranches = try await repository.getBranches()
         #expect(!updatedBranches.contains("feature"))
     }

     @Test("Staging and commit operations")
     func testStagingAndCommit() async throws {
         let (tempDir, repository) = try await createTestRepository()
         defer { cleanupTestRepository(tempDir) }

         // Create test files
         let file1 = tempDir.appendingPathComponent("file1.txt")
         let file2 = tempDir.appendingPathComponent("file2.txt")
         try "Content 1".write(to: file1, atomically: true, encoding: .utf8)
         try "Content 2".write(to: file2, atomically: true, encoding: .utf8)

         // Test staging individual file
         try await repository.stageFile("file1.txt")
         let status1 = try await repository.getRepositoryStatus()
         #expect(status1["file1.txt"] != nil)

         // Test staging all files
         try await repository.stageAllFiles()
         let status2 = try await repository.getRepositoryStatus()
         #expect(status2["file1.txt"] != nil)
         #expect(status2["file2.txt"] != nil)

         // Test commit
         let commitId = try await repository.commit(message: "Test commit")
         #expect(!commitId.isEmpty)

         // Verify clean status after commit
         let status3 = try await repository.getRepositoryStatus()
         #expect(status3.isEmpty)

         // Test amend commit
         try "Modified content".write(to: file1, atomically: true, encoding: .utf8)
         try await repository.stageFile("file1.txt")
         let amendedId = try await repository.amendCommit(message: "Amended commit")
         #expect(!amendedId.isEmpty)
         #expect(amendedId != commitId)
     }

     @Test("Diff operations")
     func testDiffOperations() async throws {
         let (tempDir, repository) = try await createTestRepository()
         defer { cleanupTestRepository(tempDir) }

         // Create and commit initial file
         let testFile = tempDir.appendingPathComponent("test.txt")
         try "Line 1\nLine 2\nLine 3".write(to: testFile, atomically: true, encoding: .utf8)
         try await repository.stageAllFiles()
         _ = try await repository.commit(message: "Initial commit")

         // Modify file
         try "Line 1\nModified Line 2\nLine 3".write(to: testFile, atomically: true, encoding: .utf8)

         // Test working directory diff
         let workingDiff = try await repository.getDiff(filePath: "test.txt", staged: false)
         #expect(workingDiff.contains("Modified Line 2"))

         // Stage and test staged diff
         try await repository.stageFile("test.txt")
         let stagedDiff = try await repository.getDiff(filePath: "test.txt", staged: true)
         #expect(stagedDiff.contains("Modified Line 2"))
     }

     @Test("Resource cleanup")
     func testResourceCleanup() async throws {
         let (tempDir, repository) = try await createTestRepository()
         defer { cleanupTestRepository(tempDir) }

         // Perform some operations
         _ = try await repository.getBranches()
         _ = try await repository.getRepositoryStatus()

         // Close repository
         await repository.close()

         // Verify repository is properly closed
         // Further operations should not crash but may fail gracefully
         #expect(await repository.isValidRepository() == false)
     }

     @Test("Commit history")
     func testCommitHistory() async throws {
         let (tempDir, repository) = try await createTestRepository()
         defer { cleanupTestRepository(tempDir) }

         // Create multiple commits
         for i in 1...3 {
             let file = tempDir.appendingPathComponent("file\(i).txt")
             try "Content \(i)".write(to: file, atomically: true, encoding: .utf8)
             try await repository.stageAllFiles()
             _ = try await repository.commit(message: "Commit \(i)")
         }

         // Test commit history
         let history = try await repository.getCommitHistory(limit: 10, branch: nil)
         #expect(history.count == 3)
         #expect(history[0].contains("Commit 3"))
         #expect(history[1].contains("Commit 2"))
         #expect(history[2].contains("Commit 1"))
     }
 }
 */
