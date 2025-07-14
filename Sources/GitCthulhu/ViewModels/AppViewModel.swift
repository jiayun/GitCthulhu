//
// AppViewModel.swift
// GitCthulhu
//
// Created by GitCthulhu Team on 2025-07-14.
//

import AppKit
import Combine
import Foundation
import GitCore

@MainActor
final class AppViewModel: ViewModelBase {
    @Published var selectedRepositoryId: UUID?
    @Published var repositories: [GitRepository] = []
    @Published var isShowingOpenPanel = false
    @Published var isShowingClonePanel = false

    private let repositoryManager: RepositoryManager
    private let repositoryInfoService = RepositoryInfoService()

    var selectedRepository: GitRepository? {
        guard let selectedId = selectedRepositoryId else { return nil }
        return repositories.first { $0.id == selectedId }
    }

    init(repositoryManager: RepositoryManager? = nil) {
        self.repositoryManager = repositoryManager ?? RepositoryManager.shared
        super.init()
        setupBindings()

        // Load recent repositories on startup
        Task {
            await self.repositoryManager.refreshRepositoriesFromRecent()
        }
    }

    private func setupBindings() {
        repositoryManager.$repositories
            .assign(to: &$repositories)

        repositoryManager.$selectedRepositoryId
            .assign(to: &$selectedRepositoryId)
    }

    func openRepository() {
        Task {
            await openRepositoryWithFileBrowser()
        }
    }

    func cloneRepository() {
        isShowingClonePanel = true
    }

    private func openRepositoryWithFileBrowser() async {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.prompt = "Open Repository"
        panel.message = "Select a Git repository folder"

        let response = await panel.begin()

        if response == .OK, let url = panel.url {
            guard repositoryInfoService.validateRepositoryPath(url) else {
                handleError(GitError.invalidRepositoryPath)
                return
            }

            do {
                try await loadRepository(at: url.path)
            } catch {
                handleError(error)
            }
        }
    }

    func selectRepository(_ repository: GitRepository) {
        selectedRepositoryId = repository.id
        repositoryManager.selectRepository(repository)
    }

    func loadRepository(at path: String) async throws {
        try await runAsync {
            let repository = try await self.repositoryManager.loadRepository(at: path)
            self.selectRepository(repository)
        }
    }

    func removeRepository(_ repository: GitRepository) {
        repositoryManager.removeRepository(repository)
        if selectedRepositoryId == repository.id {
            selectedRepositoryId = repositories.first?.id
        }
    }

    // MARK: - Testing Support

    func addTestRepository(_ repository: GitRepository) {
        repositories.append(repository)
    }
}
