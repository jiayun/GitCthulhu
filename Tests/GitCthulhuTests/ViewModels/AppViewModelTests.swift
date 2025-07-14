//
// AppViewModelTests.swift
// GitCthulhu
//
// Created by GitCthulhu Team on 2025-07-14.
//

import Foundation
import GitCore
@testable import GitCthulhu
import Testing

@MainActor
struct AppViewModelTests {
    @Test("ViewModel initializes correctly")
    func viewModelInitialization() async throws {
        let mockManager = RepositoryManager(testing: true)
        let viewModel = AppViewModel(repositoryManager: mockManager)

        #expect(viewModel.repositories.isEmpty)
        #expect(viewModel.selectedRepositoryId == nil)
        #expect(viewModel.selectedRepository == nil)
        #expect(!viewModel.isShowingOpenPanel)
        #expect(!viewModel.isShowingClonePanel)
    }

    @Test("Repository selection works correctly")
    func repositorySelection() async throws {
        let mockManager = RepositoryManager(testing: true)
        let viewModel = AppViewModel(repositoryManager: mockManager)

        // Create a test repository with mock data
        let testURL = URL(fileURLWithPath: "/tmp/test-repo")
        let testRepo = GitRepository(url: testURL, skipValidation: true)

        // Add repository to manager
        await mockManager.addTestRepository(testRepo)

        // For testing, directly add to view model to avoid binding delays
        viewModel.addTestRepository(testRepo)

        // Verify repository was added to ViewModel
        #expect(viewModel.repositories.count == 1)
        #expect(viewModel.repositories.contains { $0.id == testRepo.id })

        // Select repository
        viewModel.selectRepository(testRepo)

        #expect(viewModel.selectedRepositoryId == testRepo.id)
        #expect(viewModel.selectedRepository?.id == testRepo.id)
    }

    @Test("Repository removal works correctly")
    func repositoryRemoval() async throws {
        let mockManager = RepositoryManager(testing: true)
        let viewModel = AppViewModel(repositoryManager: mockManager)

        // Create test repositories
        let testURL1 = URL(fileURLWithPath: "/tmp/test-repo-1")
        let testURL2 = URL(fileURLWithPath: "/tmp/test-repo-2")
        let testRepo1 = GitRepository(url: testURL1, skipValidation: true)
        let testRepo2 = GitRepository(url: testURL2, skipValidation: true)

        // Add repositories to manager
        await mockManager.addTestRepository(testRepo1)
        await mockManager.addTestRepository(testRepo2)

        // For testing, directly add to view model to avoid binding delays
        viewModel.addTestRepository(testRepo1)
        viewModel.addTestRepository(testRepo2)

        // Verify repositories were added
        #expect(viewModel.repositories.count == 2)

        // Select first repository
        viewModel.selectRepository(testRepo1)
        #expect(viewModel.selectedRepositoryId == testRepo1.id)

        // Remove selected repository
        viewModel.removeRepository(testRepo1)

        // Should select the remaining repository
        #expect(viewModel.selectedRepositoryId == testRepo2.id)
    }

    @Test("Clone panel state management")
    func clonePanelState() async throws {
        let mockManager = RepositoryManager(testing: true)
        let viewModel = AppViewModel(repositoryManager: mockManager)

        #expect(!viewModel.isShowingClonePanel)

        viewModel.cloneRepository()

        #expect(viewModel.isShowingClonePanel)
    }

    @Test("Error handling works correctly")
    func errorHandling() async throws {
        let mockManager = RepositoryManager(testing: true)
        let viewModel = AppViewModel(repositoryManager: mockManager)

        #expect(viewModel.errorMessage == nil)
        #expect(!viewModel.isLoading)

        // Test error handling by trying to load invalid path
        do {
            try await viewModel.loadRepository(at: "/invalid/path")
        } catch {
            // Expected to fail
        }

        #expect(!viewModel.isLoading)
    }
}
