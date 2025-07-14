//
// RepositoryDetailViewModelTests.swift
// GitCthulhu
//
// Created by GitCthulhu Team on 2025-07-14.
//

import Foundation
import GitCore
@testable import GitCthulhu
import Testing

@MainActor
struct RepositoryDetailViewModelTests {
    @Test("ViewModel initializes correctly")
    func viewModelInitialization() async throws {
        let mockManager = RepositoryManager(testing: true)
        let appViewModel = AppViewModel(repositoryManager: mockManager)
        let repositoryInfoService = RepositoryInfoService()
        let detailViewModel = RepositoryDetailViewModel(
            appViewModel: appViewModel,
            repositoryInfoService: repositoryInfoService
        )

        #expect(detailViewModel.selectedRepository == nil)
        #expect(detailViewModel.repositoryInfo == nil)
        #expect(!detailViewModel.isInfoLoading)
        #expect(!detailViewModel.isLoading)
        #expect(detailViewModel.errorMessage == nil)
    }

    @Test("Repository selection binding works")
    func repositorySelectionBinding() async throws {
        let mockManager = RepositoryManager(testing: true)
        let appViewModel = AppViewModel(repositoryManager: mockManager)
        let repositoryInfoService = RepositoryInfoService()
        let detailViewModel = RepositoryDetailViewModel(
            appViewModel: appViewModel,
            repositoryInfoService: repositoryInfoService
        )

        // Create a test repository
        let testURL = URL(fileURLWithPath: "/tmp/test-repo")
        let testRepo = GitRepository(url: testURL, skipValidation: true)

        // Add to manager and directly to AppViewModel for testing
        await mockManager.addTestRepository(testRepo)
        appViewModel.addTestRepository(testRepo)

        // Select repository through app view model
        appViewModel.selectRepository(testRepo)

        // Wait for RepositoryDetailViewModel binding to update
        try await Task.sleep(nanoseconds: 50_000_000)

        #expect(detailViewModel.selectedRepository?.id == testRepo.id)
    }

    @Test("Repository info loading handling")
    func repositoryInfoLoading() async throws {
        let mockManager = RepositoryManager(testing: true)
        let appViewModel = AppViewModel(repositoryManager: mockManager)
        let repositoryInfoService = RepositoryInfoService()
        let detailViewModel = RepositoryDetailViewModel(
            appViewModel: appViewModel,
            repositoryInfoService: repositoryInfoService
        )

        // Create a test repository
        let testURL = URL(fileURLWithPath: "/tmp/test-repo")
        let testRepo = GitRepository(url: testURL, skipValidation: true)

        // Add to manager and directly to AppViewModel for testing
        await mockManager.addTestRepository(testRepo)
        appViewModel.addTestRepository(testRepo)

        // Select repository
        appViewModel.selectRepository(testRepo)

        // Wait for repository info loading to start and potentially complete
        try await Task.sleep(nanoseconds: 100_000_000)

        // The repository info loading should have been attempted
        // (we can't easily test the actual info since it requires a real git repo)
        #expect(detailViewModel.selectedRepository?.id == testRepo.id)
    }

    @Test("Repository deselection clears info")
    func repositoryDeselection() async throws {
        let mockManager = RepositoryManager(testing: true)
        let appViewModel = AppViewModel(repositoryManager: mockManager)
        let repositoryInfoService = RepositoryInfoService()
        let detailViewModel = RepositoryDetailViewModel(
            appViewModel: appViewModel,
            repositoryInfoService: repositoryInfoService
        )

        // Create and select a repository first
        let testURL = URL(fileURLWithPath: "/tmp/test-repo")
        let testRepo = GitRepository(url: testURL, skipValidation: true)

        // Add to manager and directly to AppViewModel for testing
        await mockManager.addTestRepository(testRepo)
        appViewModel.addTestRepository(testRepo)

        appViewModel.selectRepository(testRepo)

        // Wait for selection to propagate
        try await Task.sleep(nanoseconds: 50_000_000)

        #expect(detailViewModel.selectedRepository?.id == testRepo.id)

        // Deselect repository
        appViewModel.selectedRepositoryId = nil

        // Wait for binding to update
        try await Task.sleep(nanoseconds: 200_000_000)

        #expect(detailViewModel.selectedRepository == nil)
        #expect(detailViewModel.repositoryInfo == nil)
    }

    @Test("Refresh repository info works")
    func refreshRepositoryInfo() async throws {
        let mockManager = RepositoryManager(testing: true)
        let appViewModel = AppViewModel(repositoryManager: mockManager)
        let repositoryInfoService = RepositoryInfoService()
        let detailViewModel = RepositoryDetailViewModel(
            appViewModel: appViewModel,
            repositoryInfoService: repositoryInfoService
        )

        // Create and select a repository
        let testURL = URL(fileURLWithPath: "/tmp/test-repo")
        let testRepo = GitRepository(url: testURL, skipValidation: true)

        // Add to manager and directly to AppViewModel for testing
        await mockManager.addTestRepository(testRepo)
        appViewModel.addTestRepository(testRepo)

        appViewModel.selectRepository(testRepo)

        // Wait for selection to propagate
        try await Task.sleep(nanoseconds: 50_000_000)

        // Test refresh (should not crash even if repo info loading fails)
        await detailViewModel.refreshRepositoryInfo()

        #expect(detailViewModel.selectedRepository?.id == testRepo.id)
    }

    @Test("Error handling during repository info loading")
    func errorHandlingDuringInfoLoading() async throws {
        let mockManager = RepositoryManager(testing: true)
        let appViewModel = AppViewModel(repositoryManager: mockManager)
        let repositoryInfoService = RepositoryInfoService()
        let detailViewModel = RepositoryDetailViewModel(
            appViewModel: appViewModel,
            repositoryInfoService: repositoryInfoService
        )

        // Create an invalid repository (non-existent path)
        let invalidURL = URL(fileURLWithPath: "/invalid/path/repo")
        let invalidRepo = GitRepository(url: invalidURL, skipValidation: true)

        // Add to manager and directly to AppViewModel for testing
        await mockManager.addTestRepository(invalidRepo)
        appViewModel.addTestRepository(invalidRepo)

        // Select invalid repository
        appViewModel.selectRepository(invalidRepo)

        // Wait for error handling
        try await Task.sleep(nanoseconds: 100_000_000)

        // Should handle error gracefully without crashing
        #expect(detailViewModel.selectedRepository?.id == invalidRepo.id)
        // Error handling should have occurred, but we can't easily verify
        // the exact error state without mocking the service
    }
}
