//
// ContentViewModelTests.swift
// GitCthulhu
//
// Created by GitCthulhu Team on 2025-07-14.
//

import Testing
import Foundation
import GitCore
@testable import GitCthulhu

@MainActor
struct ContentViewModelTests {

    @Test("ViewModel initializes correctly")
    func viewModelInitialization() async throws {
        let mockManager = RepositoryManager(testing: true)
        let appViewModel = AppViewModel(repositoryManager: mockManager)
        let contentViewModel = ContentViewModel(appViewModel: appViewModel)

        #expect(contentViewModel.sidebarWidth == 250)
        #expect(contentViewModel.isShowingWelcomeView)
    }

    @Test("Welcome view visibility based on repository selection")
    func welcomeViewVisibility() async throws {
        let mockManager = RepositoryManager(testing: true)
        let appViewModel = AppViewModel(repositoryManager: mockManager)
        let contentViewModel = ContentViewModel(appViewModel: appViewModel)

        // Initially should show welcome view
        #expect(contentViewModel.isShowingWelcomeView)

        // Create and select a repository
        let testURL = URL(fileURLWithPath: "/tmp/test-repo")
        let testRepo = GitRepository(url: testURL, skipValidation: true)
        await mockManager.addTestRepository(testRepo)

        // Wait for updates
        try await Task.sleep(nanoseconds: 100_000_000)

        // Select repository
        appViewModel.selectRepository(testRepo)

        // Wait for binding to update
        try await Task.sleep(nanoseconds: 100_000_000)

        // Should not show welcome view when repository is selected
        #expect(!contentViewModel.isShowingWelcomeView)

        // Deselect repository
        appViewModel.selectedRepositoryId = nil

        // Wait for binding to update
        try await Task.sleep(nanoseconds: 100_000_000)

        // Should show welcome view again
        #expect(contentViewModel.isShowingWelcomeView)
    }

    @Test("Sidebar width adjustment")
    func sidebarWidthAdjustment() async throws {
        let mockManager = RepositoryManager(testing: true)
        let appViewModel = AppViewModel(repositoryManager: mockManager)
        let contentViewModel = ContentViewModel(appViewModel: appViewModel)

        // Test within bounds
        contentViewModel.adjustSidebarWidth(300)
        #expect(contentViewModel.sidebarWidth == 300)

        // Test minimum constraint
        contentViewModel.adjustSidebarWidth(100)
        #expect(contentViewModel.sidebarWidth == 200) // minimum is 200

        // Test maximum constraint
        contentViewModel.adjustSidebarWidth(500)
        #expect(contentViewModel.sidebarWidth == 400) // maximum is 400

        // Test exact bounds
        contentViewModel.adjustSidebarWidth(200)
        #expect(contentViewModel.sidebarWidth == 200)

        contentViewModel.adjustSidebarWidth(400)
        #expect(contentViewModel.sidebarWidth == 400)
    }
}
