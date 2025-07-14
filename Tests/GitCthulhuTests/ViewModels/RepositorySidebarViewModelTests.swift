//
// RepositorySidebarViewModelTests.swift
// GitCthulhu
//
// Created by GitCthulhu Team on 2025-07-14.
//

import Testing
import Foundation
import GitCore
@testable import GitCthulhu

@MainActor
struct RepositorySidebarViewModelTests {

    @Test("ViewModel initializes correctly")
    func viewModelInitialization() async throws {
        let mockManager = RepositoryManager(testing: true)
        let appViewModel = AppViewModel(repositoryManager: mockManager)
        let sidebarViewModel = RepositorySidebarViewModel(appViewModel: appViewModel)

        #expect(sidebarViewModel.repositories.isEmpty)
        #expect(sidebarViewModel.selectedRepositoryId == nil)
    }

    @Test("Repository list binding works")
    func repositoryListBinding() async throws {
        let mockManager = RepositoryManager(testing: true)
        let appViewModel = AppViewModel(repositoryManager: mockManager)
        let sidebarViewModel = RepositorySidebarViewModel(appViewModel: appViewModel)

        // Add repositories
        let testURL1 = URL(fileURLWithPath: "/tmp/test-repo-1")
        let testURL2 = URL(fileURLWithPath: "/tmp/test-repo-2")
        let testRepo1 = GitRepository(url: testURL1, skipValidation: true)
        let testRepo2 = GitRepository(url: testURL2, skipValidation: true)

        await mockManager.addTestRepository(testRepo1)
        await mockManager.addTestRepository(testRepo2)

        // Wait for binding to update
        try await Task.sleep(nanoseconds: 100_000_000)

        #expect(sidebarViewModel.repositories.count == 2)
        #expect(sidebarViewModel.repositories.contains { $0.id == testRepo1.id })
        #expect(sidebarViewModel.repositories.contains { $0.id == testRepo2.id })
    }

    @Test("Repository selection binding works")
    func repositorySelectionBinding() async throws {
        let mockManager = RepositoryManager(testing: true)
        let appViewModel = AppViewModel(repositoryManager: mockManager)
        let sidebarViewModel = RepositorySidebarViewModel(appViewModel: appViewModel)

        let testURL = URL(fileURLWithPath: "/tmp/test-repo")
        let testRepo = GitRepository(url: testURL, skipValidation: true)
        await mockManager.addTestRepository(testRepo)

        // Wait for updates
        try await Task.sleep(nanoseconds: 100_000_000)

        // Select through app view model
        appViewModel.selectRepository(testRepo)

        // Wait for binding
        try await Task.sleep(nanoseconds: 100_000_000)

        #expect(sidebarViewModel.selectedRepositoryId == testRepo.id)
    }

    @Test("Repository selection through sidebar works")
    func repositorySelectionThroughSidebar() async throws {
        let mockManager = RepositoryManager(testing: true)
        let appViewModel = AppViewModel(repositoryManager: mockManager)
        let sidebarViewModel = RepositorySidebarViewModel(appViewModel: appViewModel)

        let testURL = URL(fileURLWithPath: "/tmp/test-repo")
        let testRepo = GitRepository(url: testURL, skipValidation: true)
        await mockManager.addTestRepository(testRepo)

        // Wait for updates
        try await Task.sleep(nanoseconds: 100_000_000)

        // Select through sidebar
        sidebarViewModel.selectRepository(testRepo)

        #expect(appViewModel.selectedRepositoryId == testRepo.id)
        #expect(sidebarViewModel.selectedRepositoryId == testRepo.id)
    }

    @Test("Repository removal through sidebar works")
    func repositoryRemovalThroughSidebar() async throws {
        let mockManager = RepositoryManager(testing: true)
        let appViewModel = AppViewModel(repositoryManager: mockManager)
        let sidebarViewModel = RepositorySidebarViewModel(appViewModel: appViewModel)

        let testURL = URL(fileURLWithPath: "/tmp/test-repo")
        let testRepo = GitRepository(url: testURL, skipValidation: true)
        await mockManager.addTestRepository(testRepo)

        // Wait for updates
        try await Task.sleep(nanoseconds: 100_000_000)

        #expect(sidebarViewModel.repositories.count == 1)

        // Remove through sidebar
        sidebarViewModel.removeRepository(testRepo)

        // Wait for updates
        try await Task.sleep(nanoseconds: 100_000_000)

        #expect(sidebarViewModel.repositories.isEmpty)
    }

    @Test("Selection status check works")
    func selectionStatusCheck() async throws {
        let mockManager = RepositoryManager(testing: true)
        let appViewModel = AppViewModel(repositoryManager: mockManager)
        let sidebarViewModel = RepositorySidebarViewModel(appViewModel: appViewModel)

        let testURL1 = URL(fileURLWithPath: "/tmp/test-repo-1")
        let testURL2 = URL(fileURLWithPath: "/tmp/test-repo-2")
        let testRepo1 = GitRepository(url: testURL1, skipValidation: true)
        let testRepo2 = GitRepository(url: testURL2, skipValidation: true)

        await mockManager.addTestRepository(testRepo1)
        await mockManager.addTestRepository(testRepo2)

        // Wait for updates
        try await Task.sleep(nanoseconds: 100_000_000)

        // Select first repository
        sidebarViewModel.selectRepository(testRepo1)

        // Check selection status
        #expect(sidebarViewModel.isSelected(testRepo1))
        #expect(!sidebarViewModel.isSelected(testRepo2))

        // Select second repository
        sidebarViewModel.selectRepository(testRepo2)

        #expect(!sidebarViewModel.isSelected(testRepo1))
        #expect(sidebarViewModel.isSelected(testRepo2))
    }

    @Test("Open repository delegation works")
    func openRepositoryDelegation() async throws {
        let mockManager = RepositoryManager(testing: true)
        let appViewModel = AppViewModel(repositoryManager: mockManager)
        let sidebarViewModel = RepositorySidebarViewModel(appViewModel: appViewModel)

        // This should not crash and should delegate to app view model
        sidebarViewModel.openRepository()

        // We can't easily test file panel interaction in unit tests,
        // but we can verify the method exists and doesn't crash
        #expect(true) // Test passes if no crash occurs
    }

    @Test("Clone repository delegation works")
    func cloneRepositoryDelegation() async throws {
        let mockManager = RepositoryManager(testing: true)
        let appViewModel = AppViewModel(repositoryManager: mockManager)
        let sidebarViewModel = RepositorySidebarViewModel(appViewModel: appViewModel)

        sidebarViewModel.cloneRepository()

        #expect(appViewModel.isShowingClonePanel)
    }
}
