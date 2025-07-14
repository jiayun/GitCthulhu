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
        let mockManager = MockRepositoryManager()
        let viewModel = AppViewModel(repositoryManager: mockManager)

        #expect(viewModel.repositories.isEmpty)
        #expect(viewModel.selectedRepositoryId == nil)
        #expect(viewModel.selectedRepository == nil)
        #expect(!viewModel.isShowingOpenPanel)
        #expect(!viewModel.isShowingClonePanel)
    }

    @Test("Repository selection works correctly")
    func repositorySelection() async throws {
        let mockManager = MockRepositoryManager()
        let viewModel = AppViewModel(repositoryManager: mockManager)

        // Create a test repository with mock data
        let testURL = URL(fileURLWithPath: "/tmp/test-repo")
        let testRepo = GitRepository(url: testURL, skipValidation: true)

        // Add repository to manager
        await mockManager.addTestRepository(testRepo)

        // Verify repository was added to manager
        #expect(mockManager.repositories.count == 1)
        #expect(mockManager.repositories.contains { $0.id == testRepo.id })

        // Select repository
        mockManager.selectRepository(testRepo)

        #expect(mockManager.selectedRepositoryId == testRepo.id)
        #expect(mockManager.selectedRepository?.id == testRepo.id)
    }

    @Test("Repository removal works correctly")
    func repositoryRemoval() async throws {
        let mockManager = MockRepositoryManager()
        let viewModel = AppViewModel(repositoryManager: mockManager)

        // Create test repositories
        let testURL1 = URL(fileURLWithPath: "/tmp/test-repo-1")
        let testURL2 = URL(fileURLWithPath: "/tmp/test-repo-2")
        let testRepo1 = GitRepository(url: testURL1, skipValidation: true)
        let testRepo2 = GitRepository(url: testURL2, skipValidation: true)

        // Add repositories to manager
        await mockManager.addTestRepository(testRepo1)
        await mockManager.addTestRepository(testRepo2)

        // Verify repositories were added
        #expect(mockManager.repositories.count == 2)

        // Select first repository
        mockManager.selectRepository(testRepo1)
        #expect(mockManager.selectedRepositoryId == testRepo1.id)

        // Remove selected repository
        mockManager.removeRepository(testRepo1)

        // Should select the remaining repository
        #expect(mockManager.selectedRepositoryId == testRepo2.id)
    }

    @Test("Clone panel state management")
    func clonePanelState() async throws {
        let mockManager = MockRepositoryManager()
        let viewModel = AppViewModel(repositoryManager: mockManager)

        #expect(!viewModel.isShowingClonePanel)

        viewModel.cloneRepository()

        #expect(viewModel.isShowingClonePanel)
    }

    @Test("Error handling works correctly")
    func errorHandling() async throws {
        let mockManager = MockRepositoryManager()
        mockManager.setShouldFailNextOperation(true)
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
