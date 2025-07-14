//
// DependencyContainer.swift
// GitCthulhu
//
// Created by GitCthulhu Team on 2025-07-14.
//

import Foundation
import GitCore
import SwiftUI

@MainActor
final class DependencyContainer: ObservableObject {
    static let shared = DependencyContainer()

    // MARK: - Services

    let repositoryManager: RepositoryManager
    let repositoryInfoService: RepositoryInfoService

    // MARK: - ViewModels

    @Published private(set) var appViewModel: AppViewModel

    private init() {
        // Initialize services
        repositoryManager = RepositoryManager.shared
        repositoryInfoService = RepositoryInfoService()

        // Initialize ViewModels with dependencies
        appViewModel = AppViewModel(repositoryManager: repositoryManager)
    }

    // MARK: - ViewModel Factory Methods

    func makeContentViewModel() -> ContentViewModel {
        ContentViewModel(appViewModel: appViewModel)
    }

    func makeRepositorySidebarViewModel() -> RepositorySidebarViewModel {
        RepositorySidebarViewModel(appViewModel: appViewModel)
    }

    func makeRepositoryDetailViewModel() -> RepositoryDetailViewModel {
        RepositoryDetailViewModel(
            appViewModel: appViewModel,
            repositoryInfoService: repositoryInfoService
        )
    }
}

// MARK: - Environment Key

struct DependencyContainerKey: EnvironmentKey {
    static let defaultValue = DependencyContainer.shared
}

extension EnvironmentValues {
    var dependencyContainer: DependencyContainer {
        get { self[DependencyContainerKey.self] }
        set { self[DependencyContainerKey.self] = newValue }
    }
}
