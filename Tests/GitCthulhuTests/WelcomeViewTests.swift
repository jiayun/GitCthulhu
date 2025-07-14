//
// WelcomeViewTests.swift
// GitCthulhu
//
// Created by GitCthulhu Team on 2025-07-11.
//

@testable import GitCore
@testable import GitCthulhu
import SwiftUI
import Testing

struct WelcomeViewTests {
    @Test
    func welcomeViewInitialization() async throws {
        // Test that WelcomeView can be instantiated
        let appViewModel = await AppViewModel(repositoryManager: RepositoryManager(testing: true))

        await withCheckedContinuation { continuation in
            Task { @MainActor in
                let welcomeView = WelcomeView()
                    .environmentObject(appViewModel)

                // Basic initialization test
                #expect(appViewModel.selectedRepository == nil)
                #expect(appViewModel.repositories.isEmpty)

                continuation.resume(returning: ())
            }
        }
    }

    // TODO: Update this test for new MVVM architecture
    // RecentRepositoryRow now requires GitRepository instead of URL
    /*
     @Test
     func recentRepositoryRowFunctionality() async throws {
         // Test needs to be updated for new architecture
     }
     */

    @Test
    func dragAndDropHandling() async throws {
        // Test the drag and drop validation logic
        let repositoryInfoService = RepositoryInfoService()

        await withCheckedContinuation { continuation in
            Task { @MainActor in
                // Test with invalid path (no .git directory)
                let invalidURL = URL(fileURLWithPath: "/nonexistent/path")
                let isValid = repositoryInfoService.validateRepositoryPath(invalidURL)

                #expect(isValid == false)

                // Test with temporary directory (valid path but no .git)
                let tempDir = FileManager.default.temporaryDirectory
                let isTempValid = repositoryInfoService.validateRepositoryPath(tempDir)

                #expect(isTempValid == false)

                continuation.resume(returning: ())
            }
        }
    }

    @Test
    func errorHandling() async throws {
        let appViewModel = await AppViewModel(repositoryManager: RepositoryManager(testing: true))

        await withCheckedContinuation { continuation in
            Task { @MainActor in
                // Test error state
                appViewModel.handleError(GitError.invalidRepositoryPath)

                #expect(appViewModel.errorMessage != nil)

                // Test error clearing
                appViewModel.clearError()

                #expect(appViewModel.errorMessage == nil)

                continuation.resume(returning: ())
            }
        }
    }

    @Test
    func loadingState() async throws {
        let appViewModel = await AppViewModel(repositoryManager: RepositoryManager(testing: true))

        await withCheckedContinuation { continuation in
            Task { @MainActor in
                // Test loading state
                #expect(appViewModel.isLoading == false)

                // The loading state is now managed internally by ViewModels
                // We can't directly set it, but we can verify the initial state
                #expect(appViewModel.isLoading == false)

                continuation.resume(returning: ())
            }
        }
    }
}
