//
// RepositoryManager.swift
// GitCthulhu
//
// Created by GitCthulhu Team on 2025-07-11.
//

import Combine
import Foundation

public struct RepositoryInfo {
    public let name: String
    public let path: String
    public let branch: String?
    public let latestCommit: GitCommandExecutor.CommitInfo?
    public let remoteInfo: [GitCommandExecutor.RemoteInfo]
    public let commitCount: Int
    public let workingDirectoryStatus: GitCommandExecutor.DetailedFileStatus

    public init(
        name: String,
        path: String,
        branch: String? = nil,
        latestCommit: GitCommandExecutor.CommitInfo? = nil,
        remoteInfo: [GitCommandExecutor.RemoteInfo] = [],
        commitCount: Int = 0,
        workingDirectoryStatus: GitCommandExecutor.DetailedFileStatus = GitCommandExecutor.DetailedFileStatus(
            staged: 0,
            unstaged: 0,
            untracked: 0
        )
    ) {
        self.name = name
        self.path = path
        self.branch = branch
        self.latestCommit = latestCommit
        self.remoteInfo = remoteInfo
        self.commitCount = commitCount
        self.workingDirectoryStatus = workingDirectoryStatus
    }
}

@MainActor
public class RepositoryManager: ObservableObject {
    @Published public var repositories: [GitRepository] = []
    @Published public var selectedRepositoryId: UUID?
    @Published public var recentRepositories: [URL] = []

    private let userDefaults = UserDefaults.standard
    private let maxRecentRepositories = 10
    private let recentRepositoriesKey = "RecentRepositories"

    public static let shared = RepositoryManager()

    private init() {
        loadRecentRepositories()
    }

    // MARK: - Testing Support

    public init(testing: Bool) {
        // For testing purposes only
        if !testing {
            loadRecentRepositories()
        }
    }

    public var selectedRepository: GitRepository? {
        guard let selectedId = selectedRepositoryId else { return nil }
        return repositories.first { $0.id == selectedId }
    }

    // MARK: - Repository Management

    public func loadRepository(at path: String) async throws -> GitRepository {
        let url = URL(fileURLWithPath: path)
        let repository = try await GitRepository.create(url: url)

        // Add to repositories list if not already present
        if !repositories.contains(where: { $0.url == url }) {
            repositories.append(repository)
        }

        // Add to recent repositories
        addToRecentRepositories(url)

        return repository
    }

    public func selectRepository(_ repository: GitRepository) {
        selectedRepositoryId = repository.id
    }

    public func removeRepository(_ repository: GitRepository) {
        repositories.removeAll { $0.id == repository.id }

        // Remove from recent repositories if present
        if let url = repositories.first(where: { $0.id == repository.id })?.url {
            removeFromRecentRepositories(url)
        }
    }

    // MARK: - Recent Repositories Management

    private func loadRecentRepositories() {
        if let data = userDefaults.data(forKey: recentRepositoriesKey),
           let urls = try? JSONDecoder().decode([URL].self, from: data) {
            // Filter out repositories that no longer exist
            recentRepositories = urls.filter { url in
                FileManager.default.fileExists(atPath: url.path)
            }

            // Update UserDefaults if we filtered out any repositories
            if recentRepositories.count != urls.count {
                saveRecentRepositories()
            }

            // Load recent repositories as GitRepository objects
            Task { @MainActor in
                await loadRecentRepositoriesAsGitRepositories()
            }
        }
    }

    private func loadRecentRepositoriesAsGitRepositories() async {
        var loadedRepositories: [GitRepository] = []

        for url in recentRepositories {
            do {
                let repository = try await GitRepository.create(url: url)
                loadedRepositories.append(repository)
            } catch {
                // Remove invalid repositories from recent list
                removeFromRecentRepositories(url)
            }
        }

        repositories = loadedRepositories
    }

    private func saveRecentRepositories() {
        if let data = try? JSONEncoder().encode(recentRepositories) {
            userDefaults.set(data, forKey: recentRepositoriesKey)
        }
    }

    private func addToRecentRepositories(_ url: URL) {
        // Remove if already exists
        recentRepositories.removeAll { $0 == url }

        // Add to beginning
        recentRepositories.insert(url, at: 0)

        // Keep only maxRecentRepositories
        if recentRepositories.count > maxRecentRepositories {
            recentRepositories = Array(recentRepositories.prefix(maxRecentRepositories))
        }

        saveRecentRepositories()
    }

    public func removeFromRecentRepositories(_ url: URL) {
        recentRepositories.removeAll { $0 == url }
        saveRecentRepositories()
    }

    public func clearRecentRepositories() {
        recentRepositories.removeAll()
        repositories.removeAll()
        saveRecentRepositories()
    }

    public func refreshRepositoriesFromRecent() async {
        await loadRecentRepositoriesAsGitRepositories()
    }
}
