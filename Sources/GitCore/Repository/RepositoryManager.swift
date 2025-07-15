//
// RepositoryManager.swift
// GitCthulhu
//
// Created by GitCthulhu Team on 2025-07-11.
//

import Combine
import Foundation
import Utilities

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

// Protocol for repository manager interface (for testing)
@MainActor
public protocol RepositoryManagerProtocol: ObservableObject {
    var repositories: [GitRepository] { get }
    var selectedRepositoryId: UUID? { get set }
    var recentRepositories: [URL] { get }
    var selectedRepository: GitRepository? { get }

    // Publishers for binding
    var repositoriesPublisher: Published<[GitRepository]>.Publisher { get }
    var selectedRepositoryIdPublisher: Published<UUID?>.Publisher { get }

    func loadRepository(at path: String) async throws -> GitRepository
    func selectRepository(_ repository: GitRepository)
    func removeRepository(_ repository: GitRepository)
    func removeFromRecentRepositories(_ url: URL)
    func clearRecentRepositories()
    func refreshRepositoriesFromRecent() async
    func addTestRepository(_ repository: GitRepository) async
}

@MainActor
public class RepositoryManager: ObservableObject, RepositoryManagerProtocol {
    @Published public var repositories: [GitRepository] = []
    @Published public var selectedRepositoryId: UUID?
    @Published public var recentRepositories: [URL] = []

    private let userDefaults = UserDefaults.standard
    private let maxRecentRepositories = 10
    private let recentRepositoriesKey = "RecentRepositories"
    private let logger = Logger(category: "RepositoryManager")

    // Combine subscriptions for observing repository changes
    private var repositorySubscriptions: [UUID: Set<AnyCancellable>] = [:]

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

    // Publishers for protocol conformance
    public var repositoriesPublisher: Published<[GitRepository]>.Publisher {
        $repositories
    }

    public var selectedRepositoryIdPublisher: Published<UUID?>.Publisher {
        $selectedRepositoryId
    }

    // MARK: - Repository Change Observation

    /// Subscribe to changes in a repository to trigger UI updates
    @MainActor
    private func observeRepositoryChanges(_ repository: GitRepository) {
        logger.info("Starting to observe changes for repository: \(repository.name)")

        var subscriptions = Set<AnyCancellable>()

        // Observe all @Published properties of the repository
        repository.objectWillChange
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.logger.info("Repository '\(repository.name)' changed, triggering RepositoryManager update")
                self?.objectWillChange.send()
            }
            .store(in: &subscriptions)

        // Also observe specific property changes for debugging
        repository.$currentBranch
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newBranch in
                self?.logger.info("Repository '\(repository.name)' branch changed to: \(newBranch?.name ?? "nil")")
                self?.objectWillChange.send()
            }
            .store(in: &subscriptions)

        repository.$status
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newStatus in
                self?.logger.info("Repository '\(repository.name)' status changed (\(newStatus.count) files)")
                self?.objectWillChange.send()
            }
            .store(in: &subscriptions)

        repository.$branches
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newBranches in
                self?.logger.info("Repository '\(repository.name)' branches changed (\(newBranches.count) branches)")
                self?.objectWillChange.send()
            }
            .store(in: &subscriptions)

        // Store subscriptions for this repository
        repositorySubscriptions[repository.id] = subscriptions
    }

    /// Stop observing changes for a repository
    @MainActor
    private func stopObservingRepositoryChanges(_ repository: GitRepository) {
        logger.info("Stopping observation for repository: \(repository.name)")
        repositorySubscriptions.removeValue(forKey: repository.id)
    }

    // MARK: - Repository Management

    @MainActor
    public func loadRepository(at path: String) async throws -> GitRepository {
        let url = URL(fileURLWithPath: path)
        let repository = try await GitRepository.create(url: url)

        // Add to repositories list if not already present
        if !repositories.contains(where: { $0.url == url }) {
            repositories.append(repository)
            observeRepositoryChanges(repository)
        }

        // Add to recent repositories
        addToRecentRepositories(url)

        return repository
    }

    @MainActor
    public func selectRepository(_ repository: GitRepository) {
        selectedRepositoryId = repository.id
    }

    @MainActor
    public func removeRepository(_ repository: GitRepository) {
        // Stop observing changes before removing
        stopObservingRepositoryChanges(repository)

        // Stop file system monitoring before removing
        repository.stopFileSystemMonitoring()

        // Remove from recent repositories if present
        removeFromRecentRepositories(repository.url)

        repositories.removeAll { $0.id == repository.id }
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

    @MainActor
    private func loadRecentRepositoriesAsGitRepositories() async {
        // Clear existing subscriptions first
        for repository in repositories {
            stopObservingRepositoryChanges(repository)
            repository.stopFileSystemMonitoring()
        }

        var loadedRepositories: [GitRepository] = []

        for url in recentRepositories {
            do {
                let repository = try await GitRepository.create(url: url)
                loadedRepositories.append(repository)
                observeRepositoryChanges(repository)
                logger.info("Successfully loaded and observing repository: \(repository.name)")
            } catch {
                logger.error("Failed to load repository at \(url.path): \(error.localizedDescription)")
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

    @MainActor
    public func clearRecentRepositories() {
        // Stop observing and monitoring for all repositories before clearing
        for repository in repositories {
            stopObservingRepositoryChanges(repository)
            repository.stopFileSystemMonitoring()
        }

        recentRepositories.removeAll()
        repositories.removeAll()
        saveRecentRepositories()
    }

    @MainActor
    public func refreshRepositoriesFromRecent() async {
        await loadRecentRepositoriesAsGitRepositories()
    }

    // MARK: - Testing Support

    @MainActor
    public func addTestRepository(_ repository: GitRepository) async {
        repositories.append(repository)
        observeRepositoryChanges(repository)
    }
}
