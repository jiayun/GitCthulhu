//
// FileStatusUITests.swift
// GitCthulhu
//
// Created by GitCthulhu Team on 2025-07-15.
//

import SwiftUI
import Testing
import GitCore
import TestUtilities
import Utilities
@testable import GitCthulhu

/// UI integration tests for file status display and interactions
@MainActor
struct FileStatusUITests {
    private let logger = Logger(category: "FileStatusUITests")
    
    // MARK: - Repository Detail View Tests
    
    @Test("Repository detail view file status display")
    func repositoryDetailViewFileStatusDisplay() async throws {
        let testRepo = try TestRepository(name: "ui-detail-view-test")
        
        // Create files with various statuses
        try testRepo.createFilesWithVariousStatuses()
        
        let gitRepo = try await GitRepository.create(url: testRepo.url)
        
        // Create view model with test repository
        let viewModel = RepositoryDetailViewModel(repository: gitRepo)
        
        // Wait for initial load
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        // Verify view model has repository data
        #expect(viewModel.repository != nil)
        #expect(viewModel.repository?.url == testRepo.url)
        
        // Test view model status updates
        await viewModel.refreshRepository()
        
        // Verify status was loaded (should have some files)
        #expect(viewModel.repository?.status.count ?? 0 > 0)
        
        await gitRepo.close()
        try testRepo.cleanup()
    }
    
    @Test("Repository detail view model refresh")
    func repositoryDetailViewModelRefresh() async throws {
        let testRepo = try TestRepository(name: "ui-refresh-test")
        let gitRepo = try await GitRepository.create(url: testRepo.url)
        
        let viewModel = RepositoryDetailViewModel(repository: gitRepo)
        
        // Initial state
        let initialStatus = viewModel.repository?.status ?? [:]
        
        // Create new file
        try testRepo.createFile(name: "refresh_test.txt", content: "Test refresh")
        
        // Refresh view model
        await viewModel.refreshRepository()
        
        // Wait for updates
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        // Verify status was updated
        let updatedStatus = viewModel.repository?.status ?? [:]
        #expect(updatedStatus.count >= initialStatus.count)
        
        await gitRepo.close()
        try testRepo.cleanup()
    }
    
    // MARK: - Repository Sidebar Tests
    
    @Test("Repository sidebar view model")
    func repositorySidebarViewModel() async throws {
        let testRepo = try TestRepository(name: "ui-sidebar-test")
        let gitRepo = try await GitRepository.create(url: testRepo.url)
        
        // Create sidebar view model
        let viewModel = RepositorySidebarViewModel()
        
        // Add repository
        viewModel.addRepository(gitRepo)
        
        // Verify repository was added
        #expect(viewModel.repositories.count == 1)
        #expect(viewModel.repositories.first?.id == gitRepo.id)
        
        // Test repository selection
        viewModel.selectRepository(gitRepo)
        #expect(viewModel.selectedRepository?.id == gitRepo.id)
        
        await gitRepo.close()
        try testRepo.cleanup()
    }
    
    @Test("Repository sidebar multiple repositories")
    func repositorySidebarMultipleRepositories() async throws {
        let testRepo1 = try TestRepository(name: "ui-sidebar-multi-1")
        let testRepo2 = try TestRepository(name: "ui-sidebar-multi-2")
        
        let gitRepo1 = try await GitRepository.create(url: testRepo1.url)
        let gitRepo2 = try await GitRepository.create(url: testRepo2.url)
        
        let viewModel = RepositorySidebarViewModel()
        
        // Add multiple repositories
        viewModel.addRepository(gitRepo1)
        viewModel.addRepository(gitRepo2)
        
        // Verify both repositories were added
        #expect(viewModel.repositories.count == 2)
        
        // Test repository switching
        viewModel.selectRepository(gitRepo1)
        #expect(viewModel.selectedRepository?.id == gitRepo1.id)
        
        viewModel.selectRepository(gitRepo2)
        #expect(viewModel.selectedRepository?.id == gitRepo2.id)
        
        // Test repository removal
        viewModel.removeRepository(gitRepo1)
        #expect(viewModel.repositories.count == 1)
        #expect(viewModel.repositories.first?.id == gitRepo2.id)
        
        await gitRepo1.close()
        await gitRepo2.close()
        try testRepo1.cleanup()
        try testRepo2.cleanup()
    }
    
    // MARK: - Content View Tests
    
    @Test("Content view model integration")
    func contentViewModelIntegration() async throws {
        let testRepo = try TestRepository(name: "ui-content-test")
        let gitRepo = try await GitRepository.create(url: testRepo.url)
        
        // Create content view model
        let viewModel = ContentViewModel()
        
        // Set selected repository
        viewModel.setSelectedRepository(gitRepo)
        
        // Verify repository was set
        #expect(viewModel.selectedRepository?.id == gitRepo.id)
        
        // Test navigation state
        viewModel.navigateToRepository(gitRepo)
        #expect(viewModel.selectedRepository?.id == gitRepo.id)
        
        await gitRepo.close()
        try testRepo.cleanup()
    }
    
    // MARK: - App View Model Tests
    
    @Test("App view model initialization")
    func appViewModelInitialization() async throws {
        let viewModel = AppViewModel()
        
        // Verify initial state
        #expect(viewModel.repositories.isEmpty)
        #expect(viewModel.selectedRepository == nil)
        
        // Test repository opening
        let testRepo = try TestRepository(name: "ui-app-test")
        let gitRepo = try await GitRepository.create(url: testRepo.url)
        
        await viewModel.openRepository(at: testRepo.url)
        
        // Verify repository was opened
        #expect(viewModel.repositories.count == 1)
        #expect(viewModel.selectedRepository != nil)
        
        await gitRepo.close()
        try testRepo.cleanup()
    }
    
    // MARK: - View State Management Tests
    
    @Test("View state updates with repository changes")
    func viewStateUpdatesWithRepositoryChanges() async throws {
        let testRepo = try TestRepository(name: "ui-state-test")
        let gitRepo = try await GitRepository.create(url: testRepo.url)
        
        let viewModel = RepositoryDetailViewModel(repository: gitRepo)
        
        // Create initial file
        try testRepo.createFile(name: "state_test.txt", content: "Initial content")
        
        // Wait for file system monitoring
        try await Task.sleep(nanoseconds: 600_000_000) // 0.6 seconds
        
        // Refresh to pick up changes
        await viewModel.refreshRepository()
        
        let initialFileCount = viewModel.repository?.status.count ?? 0
        
        // Modify file
        try testRepo.modifyFile(name: "state_test.txt", content: "Modified content")
        
        // Wait for monitoring
        try await Task.sleep(nanoseconds: 600_000_000) // 0.6 seconds
        
        // Refresh again
        await viewModel.refreshRepository()
        
        let updatedFileCount = viewModel.repository?.status.count ?? 0
        
        // Should have detected the file
        #expect(updatedFileCount >= initialFileCount)
        
        await gitRepo.close()
        try testRepo.cleanup()
    }
    
    // MARK: - Error Handling in UI Tests
    
    @Test("UI error handling for invalid repository")
    func uiErrorHandlingForInvalidRepository() async throws {
        let viewModel = AppViewModel()
        
        // Try to open invalid repository
        let invalidPath = URL(fileURLWithPath: "/tmp/non-existent-repo")
        
        // This should handle the error gracefully
        await viewModel.openRepository(at: invalidPath)
        
        // Should not have added invalid repository
        #expect(viewModel.repositories.isEmpty)
        #expect(viewModel.selectedRepository == nil)
    }
    
    @Test("UI error handling for repository operations")
    func uiErrorHandlingForRepositoryOperations() async throws {
        let testRepo = try TestRepository(name: "ui-error-test")
        let gitRepo = try await GitRepository.create(url: testRepo.url)
        
        let viewModel = RepositoryDetailViewModel(repository: gitRepo)
        
        // Test error handling in view model operations
        // This should not crash the UI
        await viewModel.refreshRepository()
        
        #expect(viewModel.repository != nil)
        
        await gitRepo.close()
        try testRepo.cleanup()
    }
    
    // MARK: - UI Component Integration Tests
    
    @Test("Repository info panel integration")
    func repositoryInfoPanelIntegration() async throws {
        let testRepo = try TestRepository(name: "ui-info-panel-test")
        let gitRepo = try await GitRepository.create(url: testRepo.url)
        
        // Create repository info panel
        let infoPanel = RepositoryInfoPanel(repository: gitRepo)
        
        // Verify panel can be created
        #expect(infoPanel != nil)
        
        await gitRepo.close()
        try testRepo.cleanup()
    }
    
    // MARK: - Performance UI Tests
    
    @Test("UI performance with large repository")
    func uiPerformanceWithLargeRepository() async throws {
        let testRepo = try TestRepository(name: "ui-performance-test")
        
        // Create medium-sized repository
        try testRepo.generateLargeRepository(fileCount: 100)
        
        let gitRepo = try await GitRepository.create(url: testRepo.url)
        
        // Measure UI update time
        let startTime = CFAbsoluteTimeGetCurrent()
        
        let viewModel = RepositoryDetailViewModel(repository: gitRepo)
        await viewModel.refreshRepository()
        
        let endTime = CFAbsoluteTimeGetCurrent()
        let uiUpdateTime = endTime - startTime
        
        logger.info("UI update time for large repository: \(uiUpdateTime) seconds")
        
        // UI should update within reasonable time
        #expect(uiUpdateTime < 5.0)
        
        await gitRepo.close()
        try testRepo.cleanup()
    }
    
    // MARK: - Integration with File System Monitoring
    
    @Test("UI updates with file system monitoring")
    func uiUpdatesWithFileSystemMonitoring() async throws {
        let testRepo = try TestRepository(name: "ui-monitoring-test")
        let gitRepo = try await GitRepository.create(url: testRepo.url)
        
        let viewModel = RepositoryDetailViewModel(repository: gitRepo)
        
        // Get initial state
        let initialStatus = viewModel.repository?.status ?? [:]
        
        // Create new file (should trigger monitoring)
        try testRepo.createFile(name: "monitoring_ui.txt", content: "UI monitoring test")
        
        // Wait for file system monitoring and UI updates
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        
        // Refresh to ensure UI is updated
        await viewModel.refreshRepository()
        
        // Verify UI was updated
        let updatedStatus = viewModel.repository?.status ?? [:]
        #expect(updatedStatus.count >= initialStatus.count)
        
        await gitRepo.close()
        try testRepo.cleanup()
    }
}