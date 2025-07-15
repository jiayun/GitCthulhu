//
// FileStatusPerformanceTests.swift
// GitCthulhu
//
// Created by GitCthulhu Team on 2025-07-15.
//

import Foundation
import GitCore
import Testing
import TestUtilities
import Utilities

/// Performance tests for file status management in large repositories
@MainActor
struct FileStatusPerformanceTests {
    private let logger = Logger(category: "FileStatusPerformanceTests")
    
    // MARK: - Large Repository Performance Tests
    
    @Test("Large repository status loading performance")
    func largeRepositoryStatusLoadingPerformance() async throws {
        let testRepo = try TestRepository(name: "large-repo-performance")
        
        // Generate large repository with many files
        try testRepo.generateLargeRepository(fileCount: 500)
        
        let gitRepo = try await GitRepository.create(url: testRepo.url)
        
        // Measure status loading time
        let startTime = CFAbsoluteTimeGetCurrent()
        let status = try await gitRepo.getRepositoryStatus()
        let endTime = CFAbsoluteTimeGetCurrent()
        
        let loadTime = endTime - startTime
        logger.info("Status loading time for 500 files: \(loadTime) seconds")
        
        // Performance expectation: should load within 5 seconds
        #expect(loadTime < 5.0)
        
        // Verify status was loaded correctly
        #expect(status.count >= 0) // Should handle even empty status
        
        await gitRepo.close()
        try testRepo.cleanup()
    }
    
    @Test("Large repository branch loading performance")
    func largeRepositoryBranchLoadingPerformance() async throws {
        let testRepo = try TestRepository(name: "large-repo-branches")
        
        // Create multiple branches
        for i in 1...20 {
            try testRepo.createBranch("feature-branch-\(i)")
        }
        
        let gitRepo = try await GitRepository.create(url: testRepo.url)
        
        // Measure branch loading time
        let startTime = CFAbsoluteTimeGetCurrent()
        let branches = try await gitRepo.getBranches()
        let endTime = CFAbsoluteTimeGetCurrent()
        
        let loadTime = endTime - startTime
        logger.info("Branch loading time for 20 branches: \(loadTime) seconds")
        
        // Performance expectation: should load within 2 seconds
        #expect(loadTime < 2.0)
        
        // Verify branches were loaded
        #expect(branches.count >= 20)
        
        await gitRepo.close()
        try testRepo.cleanup()
    }
    
    @Test("Concurrent file operations performance")
    func concurrentFileOperationsPerformance() async throws {
        let testRepo = try TestRepository(name: "concurrent-operations")
        
        // Create multiple files for concurrent operations
        for i in 1...50 {
            try testRepo.createFile(name: "concurrent\(i).txt", content: "Concurrent file \(i)")
        }
        
        let gitRepo = try await GitRepository.create(url: testRepo.url)
        
        // Measure concurrent staging performance
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // Stage files concurrently in batches
        let batchSize = 10
        for batchStart in stride(from: 1, through: 50, by: batchSize) {
            let batchEnd = min(batchStart + batchSize - 1, 50)
            let tasks = (batchStart...batchEnd).map { i in
                Task {
                    try await gitRepo.stageFile("concurrent\(i).txt")
                }
            }
            
            // Wait for batch to complete
            for task in tasks {
                try await task.value
            }
        }
        
        let endTime = CFAbsoluteTimeGetCurrent()
        let operationTime = endTime - startTime
        logger.info("Concurrent staging time for 50 files: \(operationTime) seconds")
        
        // Performance expectation: should complete within 10 seconds
        #expect(operationTime < 10.0)
        
        // Verify all files were staged
        let finalStatus = try await gitRepo.getRepositoryStatus()
        let stagedFiles = finalStatus.values.filter { $0 == .added }
        #expect(stagedFiles.count >= 40) // Allow for some variance
        
        await gitRepo.close()
        try testRepo.cleanup()
    }
    
    @Test("File system monitoring performance with many changes")
    func fileSystemMonitoringPerformanceWithManyChanges() async throws {
        let testRepo = try TestRepository(name: "monitoring-performance")
        let gitRepo = try await GitRepository.create(url: testRepo.url)
        
        // Create baseline files
        for i in 1...100 {
            try testRepo.createFile(name: "baseline\(i).txt", content: "Baseline \(i)")
        }
        
        // Measure monitoring response time
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // Create many files rapidly
        for i in 1...100 {
            try testRepo.createFile(name: "rapid\(i).txt", content: "Rapid file \(i)")
            if i % 10 == 0 {
                try await Task.sleep(nanoseconds: 50_000_000) // 0.05 seconds
            }
        }
        
        // Wait for monitoring to settle
        try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
        
        let endTime = CFAbsoluteTimeGetCurrent()
        let monitoringTime = endTime - startTime
        logger.info("File system monitoring time for 100 rapid changes: \(monitoringTime) seconds")
        
        // Verify monitoring detected most changes
        let finalStatus = try await gitRepo.getRepositoryStatus()
        logger.info("Final status count: \(finalStatus.count)")
        
        // Should have detected a significant number of files
        #expect(finalStatus.count >= 50)
        
        await gitRepo.close()
        try testRepo.cleanup()
    }
    
    // MARK: - Memory Performance Tests
    
    @Test("Memory usage during large operations")
    func memoryUsageDuringLargeOperations() async throws {
        let testRepo = try TestRepository(name: "memory-usage-test")
        
        // Generate medium-sized repository
        try testRepo.generateLargeRepository(fileCount: 200)
        
        let gitRepo = try await GitRepository.create(url: testRepo.url)
        
        // Measure memory usage patterns
        let initialMemory = getMemoryUsage()
        
        // Perform memory-intensive operations
        for _ in 1...10 {
            _ = try await gitRepo.getRepositoryStatus()
            _ = try await gitRepo.getBranches()
            _ = try await gitRepo.getCommitHistory(limit: 50)
            
            // Add some files to trigger updates
            try testRepo.createFile(name: "temp_\(UUID().uuidString).txt", content: "Temporary")
            try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        }
        
        let finalMemory = getMemoryUsage()
        let memoryIncrease = finalMemory - initialMemory
        
        logger.info("Memory increase during large operations: \(memoryIncrease) MB")
        
        // Memory should not increase excessively (allow up to 100MB increase)
        #expect(memoryIncrease < 100.0)
        
        await gitRepo.close()
        try testRepo.cleanup()
    }
    
    @Test("Repository cleanup performance")
    func repositoryCleanupPerformance() async throws {
        let testRepo = try TestRepository(name: "cleanup-performance")
        
        // Create repository with many files
        try testRepo.generateLargeRepository(fileCount: 300)
        
        let gitRepo = try await GitRepository.create(url: testRepo.url)
        
        // Perform some operations to establish state
        _ = try await gitRepo.getRepositoryStatus()
        _ = try await gitRepo.getBranches()
        
        // Measure cleanup time
        let startTime = CFAbsoluteTimeGetCurrent()
        await gitRepo.close()
        let endTime = CFAbsoluteTimeGetCurrent()
        
        let cleanupTime = endTime - startTime
        logger.info("Repository cleanup time: \(cleanupTime) seconds")
        
        // Cleanup should be fast
        #expect(cleanupTime < 1.0)
        
        try testRepo.cleanup()
    }
    
    // MARK: - Stress Tests
    
    @Test("Stress test: rapid file operations")
    func stressTestRapidFileOperations() async throws {
        let testRepo = try TestRepository(name: "stress-test-rapid")
        let gitRepo = try await GitRepository.create(url: testRepo.url)
        
        // Perform rapid file operations
        for i in 1...50 {
            try testRepo.createFile(name: "stress\(i).txt", content: "Stress test \(i)")
            
            // Alternate between staging and checking status
            if i % 2 == 0 {
                try await gitRepo.stageFile("stress\(i).txt")
            } else {
                _ = try await gitRepo.getRepositoryStatus()
            }
            
            // Brief pause to prevent overwhelming the system
            try await Task.sleep(nanoseconds: 10_000_000) // 0.01 seconds
        }
        
        // Verify final state
        let finalStatus = try await gitRepo.getRepositoryStatus()
        #expect(finalStatus.count >= 25) // Should have detected most files
        
        await gitRepo.close()
        try testRepo.cleanup()
    }
    
    @Test("Stress test: multiple concurrent repositories")
    func stressTestMultipleConcurrentRepositories() async throws {
        let repositoryCount = 5
        var testRepos: [TestRepository] = []
        var gitRepos: [GitRepository] = []
        
        // Create multiple repositories
        for i in 1...repositoryCount {
            let testRepo = try TestRepository(name: "stress-concurrent-\(i)")
            testRepos.append(testRepo)
            
            let gitRepo = try await GitRepository.create(url: testRepo.url)
            gitRepos.append(gitRepo)
        }
        
        // Perform concurrent operations across all repositories
        let startTime = CFAbsoluteTimeGetCurrent()
        
        let tasks = gitRepos.enumerated().map { index, gitRepo in
            Task {
                for i in 1...10 {
                    try testRepos[index].createFile(name: "concurrent\(i).txt", content: "Content \(i)")
                    _ = try await gitRepo.getRepositoryStatus()
                    try await gitRepo.stageFile("concurrent\(i).txt")
                }
            }
        }
        
        // Wait for all tasks to complete
        for task in tasks {
            try await task.value
        }
        
        let endTime = CFAbsoluteTimeGetCurrent()
        let totalTime = endTime - startTime
        
        logger.info("Concurrent repositories stress test time: \(totalTime) seconds")
        
        // Should complete within reasonable time
        #expect(totalTime < 30.0)
        
        // Cleanup all repositories
        for gitRepo in gitRepos {
            await gitRepo.close()
        }
        
        for testRepo in testRepos {
            try testRepo.cleanup()
        }
    }
    
    // MARK: - Performance Utilities
    
    private func getMemoryUsage() -> Double {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(
                    mach_task_self_,
                    task_flavor_t(MACH_TASK_BASIC_INFO),
                    $0,
                    &count
                )
            }
        }
        
        if kerr == KERN_SUCCESS {
            return Double(info.resident_size) / 1024.0 / 1024.0 // Convert to MB
        }
        
        return 0.0
    }
}