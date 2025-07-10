import Testing
import Foundation
@testable import GitCore

struct RepositoryManagerTests {

    @Test func repositoryManagerInitialization() async throws {
        let manager = await RepositoryManager()

        await withCheckedContinuation { continuation in
            Task { @MainActor in
                #expect(manager.currentRepository == nil)
                #expect(manager.repositories.isEmpty)
                #expect(manager.recentRepositories.isEmpty)
                #expect(manager.isLoading == false)
                #expect(manager.error == nil)
                continuation.resume()
            }
        }
    }
    
    @Test func repositoryValidation() async throws {
        let manager = await RepositoryManager()
        
        await withCheckedContinuation { continuation in
            Task { @MainActor in
                // Test with invalid path
                let invalidURL = URL(fileURLWithPath: "/nonexistent/path")
                #expect(manager.validateRepositoryPath(invalidURL) == false)
                
                // Test with valid directory but no .git folder
                let tempDir = FileManager.default.temporaryDirectory
                #expect(manager.validateRepositoryPath(tempDir) == false)
                
                continuation.resume()
            }
        }
    }
    
    @Test func recentRepositoriesManagement() async throws {
        let manager = await RepositoryManager()
        
        await withCheckedContinuation { continuation in
            Task { @MainActor in
                let url1 = URL(fileURLWithPath: "/test/repo1")
                let url2 = URL(fileURLWithPath: "/test/repo2")
                
                // Initially empty
                #expect(manager.recentRepositories.isEmpty)
                
                // Add to recent (manually for testing)
                manager.recentRepositories.append(url1)
                manager.recentRepositories.append(url2)
                
                #expect(manager.recentRepositories.count == 2)
                #expect(manager.recentRepositories.contains(url1))
                #expect(manager.recentRepositories.contains(url2))
                
                // Remove from recent
                manager.removeFromRecentRepositories(url1)
                #expect(manager.recentRepositories.count == 1)
                #expect(!manager.recentRepositories.contains(url1))
                #expect(manager.recentRepositories.contains(url2))
                
                // Clear all
                manager.clearRecentRepositories()
                #expect(manager.recentRepositories.isEmpty)
                
                continuation.resume()
            }
        }
    }
}
