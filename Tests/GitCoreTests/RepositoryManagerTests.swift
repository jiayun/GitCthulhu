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
                #expect(manager.isLoading == false)
                #expect(manager.error == nil)
                continuation.resume()
            }
        }
    }
}
