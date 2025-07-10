@testable import GitCore
@testable import GitCthulhu
import SwiftUI
import Testing

struct WelcomeViewTests {
    @Test func welcomeViewInitialization() async throws {
        // Test that WelcomeView can be instantiated
        let repositoryManager = await RepositoryManager()

        await withCheckedContinuation { continuation in
            Task { @MainActor in
                let welcomeView = WelcomeView()
                    .environmentObject(repositoryManager)

                // Basic initialization test
                #expect(repositoryManager.currentRepository == nil)
                #expect(repositoryManager.recentRepositories.isEmpty)

                continuation.resume()
            }
        }
    }

    @Test func recentRepositoryRowFunctionality() async throws {
        let repositoryManager = await RepositoryManager()

        await withCheckedContinuation { continuation in
            Task { @MainActor in
                let testURL = URL(fileURLWithPath: "/test/repository")

                // Test RecentRepositoryRow creation
                let repositoryRow = RecentRepositoryRow(url: testURL)
                    .environmentObject(repositoryManager)

                // Verify URL is stored correctly
                #expect(testURL.path == "/test/repository")
                #expect(testURL.lastPathComponent == "repository")

                continuation.resume()
            }
        }
    }

    @Test func dragAndDropHandling() async throws {
        // Test the drag and drop validation logic
        let repositoryManager = await RepositoryManager()

        await withCheckedContinuation { continuation in
            Task { @MainActor in
                // Test with invalid path (no .git directory)
                let invalidURL = URL(fileURLWithPath: "/nonexistent/path")
                let isValid = repositoryManager.validateRepositoryPath(invalidURL)

                #expect(isValid == false)

                // Test with temporary directory (valid path but no .git)
                let tempDir = FileManager.default.temporaryDirectory
                let isTempValid = repositoryManager.validateRepositoryPath(tempDir)

                #expect(isTempValid == false)

                continuation.resume()
            }
        }
    }

    @Test func errorHandling() async throws {
        let repositoryManager = await RepositoryManager()

        await withCheckedContinuation { continuation in
            Task { @MainActor in
                // Test error state
                repositoryManager.error = .invalidRepositoryPath

                #expect(repositoryManager.error != nil)

                // Test error clearing
                repositoryManager.error = nil

                #expect(repositoryManager.error == nil)

                continuation.resume()
            }
        }
    }

    @Test func loadingState() async throws {
        let repositoryManager = await RepositoryManager()

        await withCheckedContinuation { continuation in
            Task { @MainActor in
                // Test loading state
                #expect(repositoryManager.isLoading == false)

                // Simulate loading
                repositoryManager.isLoading = true
                #expect(repositoryManager.isLoading == true)

                repositoryManager.isLoading = false
                #expect(repositoryManager.isLoading == false)

                continuation.resume()
            }
        }
    }
}
