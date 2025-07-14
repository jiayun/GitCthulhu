//
// RepositorySidebarViewModel.swift
// GitCthulhu
//
// Created by GitCthulhu Team on 2025-07-14.
//

import Combine
import Foundation
import GitCore

@MainActor
final class RepositorySidebarViewModel: ViewModelBase {
    @Published var repositories: [GitRepository] = []
    @Published var selectedRepositoryId: UUID?

    private let appViewModel: AppViewModel

    init(appViewModel: AppViewModel) {
        self.appViewModel = appViewModel
        super.init()
        setupBindings()
    }

    private func setupBindings() {
        appViewModel.$repositories
            .assign(to: &$repositories)

        appViewModel.$selectedRepositoryId
            .assign(to: &$selectedRepositoryId)
    }

    func selectRepository(_ repository: GitRepository) {
        appViewModel.selectRepository(repository)
    }

    func removeRepository(_ repository: GitRepository) {
        appViewModel.removeRepository(repository)
    }

    func openRepository() {
        appViewModel.openRepository()
    }

    func cloneRepository() {
        appViewModel.cloneRepository()
    }

    func isSelected(_ repository: GitRepository) -> Bool {
        repository.id == selectedRepositoryId
    }
}
