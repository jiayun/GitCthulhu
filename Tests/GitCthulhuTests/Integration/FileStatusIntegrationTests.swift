//
// FileStatusIntegrationTests.swift
// GitCthulhu
//
// Created by GitCthulhu Team on 2025-07-15.
//

import Foundation
import GitCore
import Testing
import TestUtilities
import Utilities

/// Integration tests for file status management workflows
@MainActor
struct FileStatusIntegrationTests {
    private let logger = Logger(category: "FileStatusIntegrationTests")
    
    // MARK: - Complete File Status Workflow Tests
    
    @Test("Complete file status workflow from creation to commit")
    func completeFileStatusWorkflow() async throws {
        let testRepo = try TestRepository(name: "complete-workflow-test")
        
        // Create GitRepository instance
        let gitRepo = try await GitRepository.create(url: testRepo.url)
        
        // Test initial state
        let initialStatus = try await gitRepo.getRepositoryStatus()
        #expect(initialStatus.isEmpty)
        
        // Create untracked file
        try testRepo.createFile(name: "workflow.txt", content: "Test content")
        
        // Wait for file system monitoring to detect changes
        try await Task.sleep(nanoseconds: 600_000_000) // 0.6 seconds
        
        // Check untracked status
        let statusAfterCreate = try await gitRepo.getRepositoryStatus()
        #expect(statusAfterCreate["workflow.txt"] == .untracked)
        
        // Stage the file
        try await gitRepo.stageFile("workflow.txt")
        
        // Check staged status
        let statusAfterStage = try await gitRepo.getRepositoryStatus()
        #expect(statusAfterStage["workflow.txt"] == .added)
        
        // Modify the staged file
        try testRepo.modifyFile(name: "workflow.txt", content: "Modified content")
        
        // Wait for file system monitoring
        try await Task.sleep(nanoseconds: 600_000_000)
        
        // Check staged + modified status
        let statusAfterModify = try await gitRepo.getRepositoryStatus()
        #expect(statusAfterModify["workflow.txt"] == .modified || statusAfterModify["workflow.txt"] == .added)
        
        // Commit the changes
        let commitResult = try await gitRepo.commit(message: "Add workflow test file")
        #expect(!commitResult.isEmpty)
        
        // Check clean status after commit
        let statusAfterCommit = try await gitRepo.getRepositoryStatus()
        #expect(statusAfterCommit["workflow.txt"] == nil)
        
        await gitRepo.close()
        try testRepo.cleanup()
    }
    
    @Test("Stage and unstage workflow")
    func stageUnstageWorkflow() async throws {
        let testRepo = try TestRepository(name: "stage-unstage-test")
        
        // Create files with various statuses
        try testRepo.createFilesWithVariousStatuses()
        
        let gitRepo = try await GitRepository.create(url: testRepo.url)
        
        // Test staging untracked file
        try await gitRepo.stageFile("untracked.txt")
        let statusAfterStage = try await gitRepo.getRepositoryStatus()
        #expect(statusAfterStage["untracked.txt"] == .added)
        
        // Test unstaging file
        try await gitRepo.unstageFile("untracked.txt")
        let statusAfterUnstage = try await gitRepo.getRepositoryStatus()
        #expect(statusAfterUnstage["untracked.txt"] == .untracked)
        
        // Test staging all files
        try await gitRepo.stageAllFiles()
        let statusAfterStageAll = try await gitRepo.getRepositoryStatus()
        
        // Should have multiple staged files
        let stagedFiles = statusAfterStageAll.values.filter { $0 == .added || $0 == .modified }
        #expect(stagedFiles.count >= 2)
        
        // Test unstaging all files
        try await gitRepo.unstageAllFiles()
        let statusAfterUnstageAll = try await gitRepo.getRepositoryStatus()
        
        // Should have no staged files (all back to untracked/modified)
        let remainingStaged = statusAfterUnstageAll.values.filter { $0 == .added }
        #expect(remainingStaged.isEmpty)
        
        await gitRepo.close()
        try testRepo.cleanup()
    }
    
    @Test("Diff view workflow")
    func diffViewWorkflow() async throws {
        let testRepo = try TestRepository(name: "diff-workflow-test")
        
        // Create and commit initial file
        try testRepo.createFile(name: "diff_test.txt", content: "Line 1\nLine 2\nLine 3")
        try testRepo.stageFile("diff_test.txt")
        try testRepo.commit(message: "Initial commit for diff test")
        
        let gitRepo = try await GitRepository.create(url: testRepo.url)
        
        // Modify the file
        try testRepo.modifyFile(name: "diff_test.txt", content: "Modified Line 1\nLine 2\nLine 3\nNew Line 4")
        
        // Wait for file system monitoring
        try await Task.sleep(nanoseconds: 600_000_000)
        
        // Test unstaged diff
        let unstagedDiff = try await gitRepo.getDiff(filePath: "diff_test.txt", staged: false)
        #expect(unstagedDiff.contains("Modified Line 1"))
        #expect(unstagedDiff.contains("New Line 4"))
        
        // Stage the file
        try await gitRepo.stageFile("diff_test.txt")
        
        // Test staged diff
        let stagedDiff = try await gitRepo.getDiff(filePath: "diff_test.txt", staged: true)
        #expect(stagedDiff.contains("Modified Line 1"))
        #expect(stagedDiff.contains("New Line 4"))
        
        // Test full repository diff
        let fullDiff = try await gitRepo.getDiff(filePath: nil, staged: false)
        #expect(!fullDiff.isEmpty)
        
        await gitRepo.close()
        try testRepo.cleanup()
    }
    
    // MARK: - Real-time Updates Tests
    
    @Test("Real-time file system monitoring")
    func realTimeFileSystemMonitoring() async throws {
        let testRepo = try TestRepository(name: "realtime-monitoring-test")
        let gitRepo = try await GitRepository.create(url: testRepo.url)
        
        // Set up expectation for status changes
        var statusUpdates: [[String: GitFileStatus]] = []
        
        // Monitor status changes
        let monitoringTask = Task {
            for _ in 0..<5 {
                let status = try await gitRepo.getRepositoryStatus()
                statusUpdates.append(status)
                try await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
            }
        }
        
        // Create files with delays to trigger monitoring
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        try testRepo.createFile(name: "monitor1.txt", content: "File 1")
        
        try await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds
        try testRepo.createFile(name: "monitor2.txt", content: "File 2")
        
        try await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds
        try testRepo.stageFile("monitor1.txt")
        
        try await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds
        
        await monitoringTask.value
        
        // Verify that file system monitoring detected changes
        #expect(statusUpdates.count >= 3)
        
        // Should eventually detect both files
        let finalUpdate = statusUpdates.last ?? [:]
        #expect(finalUpdate.keys.contains("monitor1.txt") || finalUpdate.keys.contains("monitor2.txt"))
        
        await gitRepo.close()
        try testRepo.cleanup()
    }
    
    @Test("Debounced refresh mechanism")
    func debouncedRefreshMechanism() async throws {
        let testRepo = try TestRepository(name: "debounce-test")
        let gitRepo = try await GitRepository.create(url: testRepo.url)
        
        // Create multiple files rapidly
        for i in 1...10 {
            try testRepo.createFile(name: "rapid\(i).txt", content: "Rapid file \(i)")
        }
        
        // Call refresh multiple times rapidly
        for _ in 1...5 {
            gitRepo.refreshWithDebounce()
            try await Task.sleep(nanoseconds: 50_000_000) // 0.05 seconds
        }
        
        // Wait for debounce to settle
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        
        // Verify final state
        let finalStatus = try await gitRepo.getRepositoryStatus()
        #expect(finalStatus.count >= 5) // Should have detected most files
        
        await gitRepo.close()
        try testRepo.cleanup()
    }
    
    // MARK: - Branch Operations Integration Tests
    
    @Test("Branch operations with file status")
    func branchOperationsWithFileStatus() async throws {
        let testRepo = try TestRepository(name: "branch-operations-test")
        let gitRepo = try await GitRepository.create(url: testRepo.url)
        
        // Create and commit initial file
        try testRepo.createFile(name: "branch_test.txt", content: "Main branch content")
        try await gitRepo.stageFile("branch_test.txt")
        try await gitRepo.commit(message: "Initial commit on main")
        
        // Create and switch to feature branch
        try await gitRepo.createBranch("feature-branch")
        try await gitRepo.switchBranch("feature-branch")
        
        // Verify branch switch
        let currentBranch = try await gitRepo.getCurrentBranch()
        #expect(currentBranch == "feature-branch")
        
        // Modify file on feature branch
        try testRepo.modifyFile(name: "branch_test.txt", content: "Feature branch content")
        
        // Wait for file system monitoring
        try await Task.sleep(nanoseconds: 600_000_000)
        
        // Check status on feature branch
        let statusOnFeature = try await gitRepo.getRepositoryStatus()
        #expect(statusOnFeature["branch_test.txt"] == .modified)
        
        // Commit on feature branch
        try await gitRepo.stageFile("branch_test.txt")
        try await gitRepo.commit(message: "Update on feature branch")
        
        // Switch back to main
        try await gitRepo.switchBranch("main")
        
        // Verify clean status after branch switch
        let statusAfterSwitch = try await gitRepo.getRepositoryStatus()
        #expect(statusAfterSwitch.isEmpty)
        
        await gitRepo.close()
        try testRepo.cleanup()
    }
    
    // MARK: - Error Handling Integration Tests
    
    @Test("Error handling in file operations")
    func errorHandlingInFileOperations() async throws {
        let testRepo = try TestRepository(name: "error-handling-test")
        let gitRepo = try await GitRepository.create(url: testRepo.url)
        
        // Test staging non-existent file
        do {
            try await gitRepo.stageFile("non-existent.txt")
            #expect(false, "Should have thrown error for non-existent file")
        } catch {
            #expect(error is GitError)
        }
        
        // Test unstaging non-existent file
        do {
            try await gitRepo.unstageFile("non-existent.txt")
            #expect(false, "Should have thrown error for non-existent file")
        } catch {
            #expect(error is GitError)
        }
        
        // Test committing with no staged files
        do {
            try await gitRepo.commit(message: "Empty commit")
            #expect(false, "Should have thrown error for empty commit")
        } catch {
            #expect(error is GitError)
        }
        
        await gitRepo.close()
        try testRepo.cleanup()
    }
    
    // MARK: - Multi-Repository Integration Tests
    
    @Test("Multiple repositories management")
    func multipleRepositoriesManagement() async throws {
        let testRepo1 = try TestRepository(name: "multi-repo-1")
        let testRepo2 = try TestRepository(name: "multi-repo-2")
        
        let gitRepo1 = try await GitRepository.create(url: testRepo1.url)
        let gitRepo2 = try await GitRepository.create(url: testRepo2.url)
        
        // Create files in both repositories
        try testRepo1.createFile(name: "repo1.txt", content: "Repository 1 content")
        try testRepo2.createFile(name: "repo2.txt", content: "Repository 2 content")
        
        // Wait for file system monitoring
        try await Task.sleep(nanoseconds: 600_000_000)
        
        // Test concurrent operations
        async let status1 = gitRepo1.getRepositoryStatus()
        async let status2 = gitRepo2.getRepositoryStatus()
        
        let results = try await (status1, status2)
        
        #expect(results.0["repo1.txt"] == .untracked)
        #expect(results.1["repo2.txt"] == .untracked)
        
        // Test concurrent staging
        async let stage1 = gitRepo1.stageFile("repo1.txt")
        async let stage2 = gitRepo2.stageFile("repo2.txt")
        
        try await (stage1, stage2)
        
        // Verify both staged correctly
        let finalStatus1 = try await gitRepo1.getRepositoryStatus()
        let finalStatus2 = try await gitRepo2.getRepositoryStatus()
        
        #expect(finalStatus1["repo1.txt"] == .added)
        #expect(finalStatus2["repo2.txt"] == .added)
        
        await gitRepo1.close()
        await gitRepo2.close()
        try testRepo1.cleanup()
        try testRepo2.cleanup()
    }
}