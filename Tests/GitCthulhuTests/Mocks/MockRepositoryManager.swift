//
// MockRepositoryManager.swift
// GitCthulhu
//
// Created by GitCthulhu Team on 2025-07-14.
//

import Combine
import Foundation
import GitCore
@testable import GitCthulhu

@MainActor
public class MockRepositoryManager: ObservableObject, RepositoryManagerProtocol {
    @Published public var repositories: [GitRepository] = []
    @Published public var selectedRepositoryId: UUID?
    @Published public var recentRepositories: [URL] = []

    public var selectedRepository: GitRepository? {
        guard let selectedId = selectedRepositoryId else { return nil }
        return repositories.first { $0.id == selectedId }
    }

    // Publishers for protocol conformance
    public var repositoriesPublisher: Published<[GitRepository]>.Publisher {
        $repositories
    }

    public var selectedRepositoryIdPublisher: Published<UUID?>.Publisher {
        $selectedRepositoryId
    }

    // MARK: - Mock Control

    private var shouldFailNextOperation = false
    private var loadRepositoryDelay: TimeInterval = 0

    public func setShouldFailNextOperation(_ shouldFail: Bool) {
        shouldFailNextOperation = shouldFail
    }

    public func setLoadRepositoryDelay(_ delay: TimeInterval) {
        loadRepositoryDelay = delay
    }

    // MARK: - Repository Management

    public func loadRepository(at path: String) async throws -> GitRepository {
        if shouldFailNextOperation {
            shouldFailNextOperation = false
            throw GitError.failedToOpenRepository("Mock error: Repository not found")
        }

        if loadRepositoryDelay > 0 {
            try await Task.sleep(nanoseconds: UInt64(loadRepositoryDelay * 1_000_000_000))
        }

        let url = URL(fileURLWithPath: path)
        let repository = GitRepository(url: url, skipValidation: true)

        // Add to repositories list if not already present
        if !repositories.contains(where: { $0.url == url }) {
            repositories.append(repository)
        }

        addToRecentRepositories(url)

        return repository
    }

    public func selectRepository(_ repository: GitRepository) {
        selectedRepositoryId = repository.id
    }

    public func removeRepository(_ repository: GitRepository) {
        repositories.removeAll { $0.id == repository.id }

        // If the removed repository was selected, select another one or clear selection
        if selectedRepositoryId == repository.id {
            selectedRepositoryId = repositories.first?.id
        }

        removeFromRecentRepositories(repository.url)
    }

    // MARK: - Recent Repositories Management

    private func addToRecentRepositories(_ url: URL) {
        // Remove if already exists
        recentRepositories.removeAll { $0 == url }

        // Add to beginning
        recentRepositories.insert(url, at: 0)

        // Keep only 10 recent repositories
        if recentRepositories.count > 10 {
            recentRepositories = Array(recentRepositories.prefix(10))
        }
    }

    public func removeFromRecentRepositories(_ url: URL) {
        recentRepositories.removeAll { $0 == url }
    }

    public func clearRecentRepositories() {
        recentRepositories.removeAll()
        repositories.removeAll()
        selectedRepositoryId = nil
    }

    public func refreshRepositoriesFromRecent() async {
        // In mock, this is a no-op since we don't persist data
    }

    // MARK: - Test Helpers

    public func addTestRepository(_ repository: GitRepository) async {
        repositories.append(repository)
        // Force publisher update
        repositories = repositories
    }

    public func reset() {
        repositories.removeAll()
        recentRepositories.removeAll()
        selectedRepositoryId = nil
        shouldFailNextOperation = false
        loadRepositoryDelay = 0
    }
}
