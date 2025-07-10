//
// RepositoryManager.swift
// GitCthulhu
//
// Created by GitCthulhu Team on 2025-07-11.
//

import AppKit
import Combine
import Foundation

public struct RepositoryInfo {
    public let name: String
    public let path: String
    public let branch: String?

    public init(name: String, path: String, branch: String? = nil) {
        self.name = name
        self.path = path
        self.branch = branch
    }
}

@MainActor
public class RepositoryManager: ObservableObject {
    @Published public var currentRepository: GitRepository?
    @Published public var repositories: [GitRepository] = []
    @Published public var recentRepositories: [URL] = []
    @Published public var isLoading = false
    @Published public var error: GitError?

    private let userDefaults = UserDefaults.standard
    private let maxRecentRepositories = 10
    private let recentRepositoriesKey = "RecentRepositories"

    public init() {
        loadRecentRepositories()
    }

    // MARK: - Repository Opening

    public func openRepository(at url: URL) async {
        isLoading = true
        error = nil

        do {
            let repository = try GitRepository(url: url)
            currentRepository = repository

            // Add to repositories list if not already present
            if !repositories.contains(where: { $0.url == url }) {
                repositories.append(repository)
            }

            // Add to recent repositories
            addToRecentRepositories(url)
        } catch {
            self.error = GitError.failedToOpenRepository(error.localizedDescription)
        }

        isLoading = false
    }

    public func openRepositoryWithFileBrowser() async {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.prompt = "Open Repository"
        panel.message = "Select a Git repository folder"

        let response = await panel.begin()

        if response == .OK, let url = panel.url {
            await openRepository(at: url)
        }
    }

    public func closeRepository() {
        currentRepository = nil
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
        }
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
        saveRecentRepositories()
    }

    // MARK: - Repository Validation

    public func validateRepositoryPath(_ url: URL) -> Bool {
        let gitDir = url.appendingPathComponent(".git")
        return FileManager.default.fileExists(atPath: gitDir.path)
    }

    public func getRepositoryInfo(at url: URL) async -> RepositoryInfo? {
        guard validateRepositoryPath(url) else { return nil }

        do {
            let executor = GitCommandExecutor(repositoryURL: url)
            let branch = try? await executor.getCurrentBranch()
            return RepositoryInfo(
                name: url.lastPathComponent,
                path: url.path,
                branch: branch
            )
        } catch {
            return nil
        }
    }
}
