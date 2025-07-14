//
// DependencyContainerTests.swift
// GitCthulhu
//
// Created by GitCthulhu Team on 2025-07-14.
//

import Foundation
import GitCore
@testable import GitCthulhu
import Testing

@MainActor
struct DependencyContainerTests {
    @Test("Singleton instance works correctly")
    func singletonInstance() async throws {
        let container1 = DependencyContainer.shared
        let container2 = DependencyContainer.shared

        #expect(container1 === container2)
    }

    @Test("Container initializes services correctly")
    func serviceInitialization() async throws {
        let container = DependencyContainer.shared

        #expect(container.repositoryManager != nil)
        #expect(container.repositoryInfoService != nil)
        #expect(container.appViewModel != nil)
    }

    @Test("ViewModel factory methods work correctly")
    func viewModelFactoryMethods() async throws {
        let container = DependencyContainer.shared

        // Test ContentViewModel creation
        let contentViewModel = container.makeContentViewModel()
        #expect(contentViewModel != nil)
        #expect(contentViewModel.sidebarWidth == 250)

        // Test RepositorySidebarViewModel creation
        let sidebarViewModel = container.makeRepositorySidebarViewModel()
        #expect(sidebarViewModel != nil)
        #expect(sidebarViewModel.repositories.isEmpty)

        // Test RepositoryDetailViewModel creation
        let detailViewModel = container.makeRepositoryDetailViewModel()
        #expect(detailViewModel != nil)
        #expect(detailViewModel.selectedRepository == nil)
    }

    @Test("ViewModels share same AppViewModel instance")
    func viewModelsShareAppViewModel() async throws {
        let container = DependencyContainer.shared

        let contentViewModel = container.makeContentViewModel()
        let sidebarViewModel = container.makeRepositorySidebarViewModel()
        let detailViewModel = container.makeRepositoryDetailViewModel()

        // All ViewModels should reference the same AppViewModel instance
        // We can't directly access the internal appViewModel references,
        // but we can test that changes in one affect others through the shared state

        let testURL = URL(fileURLWithPath: "/tmp/test-repo")
        let testRepo = GitRepository(url: testURL, skipValidation: true)
        await container.repositoryManager.addTestRepository(testRepo)

        // Wait for updates
        try await Task.sleep(nanoseconds: 100_000_000)

        // Select through the container's app view model
        container.appViewModel.selectRepository(testRepo)

        // Wait for binding updates
        try await Task.sleep(nanoseconds: 200_000_000)

        // All view models should reflect the same state
        #expect(!contentViewModel.isShowingWelcomeView)
        #expect(sidebarViewModel.selectedRepositoryId == testRepo.id)
        #expect(detailViewModel.selectedRepository?.id == testRepo.id)
    }

    @Test("Services are properly injected")
    func serviceInjection() async throws {
        let container = DependencyContainer.shared

        // Test that the same repository manager instance is used
        let detailViewModel = container.makeRepositoryDetailViewModel()

        // Add a repository through the container's manager
        let testURL = URL(fileURLWithPath: "/tmp/test-repo")
        let testRepo = GitRepository(url: testURL, skipValidation: true)
        await container.repositoryManager.addTestRepository(testRepo)

        // Wait for updates
        try await Task.sleep(nanoseconds: 100_000_000)

        // The AppViewModel should see the repository
        #expect(container.appViewModel.repositories.count == 1)
        #expect(container.appViewModel.repositories.first?.id == testRepo.id)
    }

    @Test("Multiple ViewModel instances are independent")
    func multipleViewModelInstances() async throws {
        let container = DependencyContainer.shared

        // Create multiple instances of the same ViewModel type
        let contentViewModel1 = container.makeContentViewModel()
        let contentViewModel2 = container.makeContentViewModel()

        // They should be different instances
        #expect(contentViewModel1 !== contentViewModel2)

        // But should have the same initial state
        #expect(contentViewModel1.sidebarWidth == contentViewModel2.sidebarWidth)
        #expect(contentViewModel1.isShowingWelcomeView == contentViewModel2.isShowingWelcomeView)

        // Independent modifications
        contentViewModel1.adjustSidebarWidth(300)
        contentViewModel2.adjustSidebarWidth(350)

        #expect(contentViewModel1.sidebarWidth == 300)
        #expect(contentViewModel2.sidebarWidth == 350)
    }
}
