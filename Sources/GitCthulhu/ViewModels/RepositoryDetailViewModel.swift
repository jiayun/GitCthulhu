//
// RepositoryDetailViewModel.swift
// GitCthulhu
//
// Created by GitCthulhu Team on 2025-07-14.
//

import Combine
import Foundation
import GitCore

@MainActor
final class RepositoryDetailViewModel: ViewModelBase {
    @Published var selectedRepository: GitRepository?
    @Published var repositoryInfo: RepositoryInfo?
    @Published var isInfoLoading = false

    private let appViewModel: AppViewModel
    private let repositoryInfoService: RepositoryInfoService

    init(appViewModel: AppViewModel, repositoryInfoService: RepositoryInfoService = RepositoryInfoService()) {
        self.appViewModel = appViewModel
        self.repositoryInfoService = repositoryInfoService
        super.init()
        setupBindings()
    }

    private func setupBindings() {
        appViewModel.$selectedRepositoryId
            .sink { [weak self] _ in
                let repository = self?.appViewModel.selectedRepository
                self?.selectedRepository = repository
                self?.setupRepositoryObservation(repository)
                if let repository {
                    Task {
                        await self?.loadRepositoryInfo(for: repository)
                    }
                } else {
                    self?.repositoryInfo = nil
                }
            }
            .store(in: &cancellables)
    }

    private func setupRepositoryObservation(_ repository: GitRepository?) {
        // Clear previous repository observation
        cancellables = Set<AnyCancellable>()

        // Re-establish AppViewModel binding
        appViewModel.$selectedRepositoryId
            .sink { [weak self] _ in
                let repository = self?.appViewModel.selectedRepository
                self?.selectedRepository = repository
                // Repository observation is already set up in setupBindings
                if let repository {
                    Task {
                        await self?.loadRepositoryInfo(for: repository)
                    }
                } else {
                    self?.repositoryInfo = nil
                }
            }
            .store(in: &cancellables)

        // Observe repository changes if we have a selected repository
        guard let repository else { return }

        // Observe repository's objectWillChange to refresh info when repository state changes
        repository.objectWillChange
            .debounce(for: .milliseconds(500), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self, let currentRepo = self.selectedRepository else { return }
                Task {
                    await self.loadRepositoryInfo(for: currentRepo)
                }
            }
            .store(in: &cancellables)

        // Also observe specific properties for immediate updates
        repository.$currentBranch
            .debounce(for: .milliseconds(100), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self, let currentRepo = self.selectedRepository else { return }
                Task {
                    await self.loadRepositoryInfo(for: currentRepo)
                }
            }
            .store(in: &cancellables)
    }

    func loadRepositoryInfo(for repository: GitRepository) async {
        do {
            try await runAsync { [weak self] in
                guard let self else { return }
                isInfoLoading = true

                do {
                    let info = try await repositoryInfoService.getRepositoryInfo(for: repository)
                    repositoryInfo = info
                } catch {
                    handleError(error)
                }

                isInfoLoading = false
            }
        } catch {
            handleError(error)
        }
    }

    func refreshRepositoryInfo() async {
        guard let repository = selectedRepository else { return }
        await loadRepositoryInfo(for: repository)
    }
}
