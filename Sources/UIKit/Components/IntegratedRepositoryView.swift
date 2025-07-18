//
// IntegratedRepositoryView.swift
// GitCthulhu
//
// Created by GitCthulhu Team on 2025-07-17.
//

import GitCore
import SwiftUI

/// Integrated view combining file status list and diff viewer
public struct IntegratedRepositoryView: View {
    let repositoryPath: String

    @StateObject private var statusManager: GitStatusViewModel
    @StateObject private var stagingViewModel: StagingViewModel
    @StateObject private var diffViewModel: DiffViewerViewModel
    @State private var repository: GitRepository?
    @State private var selectedFileForDiff: String?
    @State private var showDiffViewer: Bool = false
    @State private var selectedTab: RepositoryTab = .changes

    private let logger = Logger(category: "IntegratedRepositoryView")

    public init(repositoryPath: String) {
        self.repositoryPath = repositoryPath
        _statusManager = StateObject(wrappedValue: GitStatusViewModel(repositoryPath: repositoryPath))
        _stagingViewModel = StateObject(wrappedValue: StagingViewModel(repositoryPath: repositoryPath))
        _diffViewModel = StateObject(wrappedValue: DiffViewerViewModel(repositoryPath: repositoryPath))
    }

    public var body: some View {
        TabView(selection: $selectedTab) {
            // Changes tab with file status and staging
            IntegratedRepositoryChangesTab(
                statusManager: statusManager,
                stagingViewModel: stagingViewModel,
                diffViewModel: diffViewModel,
                repository: $repository,
                selectedFileForDiff: $selectedFileForDiff
            )
                .tabItem {
                    Label("Changes", systemImage: "square.and.pencil")
                }
                .tag(RepositoryTab.changes)

            // Diff viewer tab
            diffTab
                .tabItem {
                    Label("Diff", systemImage: "doc.text.magnifyingglass")
                }
                .tag(RepositoryTab.diff)
        }
        .navigationTitle("Repository")
        .toolbar {
            repositoryToolbar
        }
        .onAppear {
            Task {
                await loadRepositoryData()
            }
        }
        .onChange(of: selectedFileForDiff) { filePath in
            if let filePath {
                diffViewModel.selectFile(filePath)
                selectedTab = .diff
            }
        }
    }

    // MARK: - Tab Views

    private var changesTab: some View {
        HSplitView {
            // Left: File status list
            IntegratedRepositoryFileStatusTab(
                statusManager: statusManager,
                repository: $repository,
                selectedFileForDiff: $selectedFileForDiff
            )

            // Right: Staging area
            IntegratedRepositoryStagingAreaTab(
                repository: $repository,
                stagingViewModel: stagingViewModel
            )
        }
    }

    private var diffTab: some View {
        DiffViewerView(repositoryPath: repositoryPath)
    }

    // MARK: - Headers and Toolbars

    private var repositoryToolbar: some View {
        HStack {
            // Refresh button
            Button(action: {
                Task {
                    await refreshRepositoryData()
                }
            }) {
                Image(systemName: "arrow.clockwise")
            }
            .disabled(statusManager.isLoading || stagingViewModel.isLoading)
            .help("Refresh repository status")

            // Loading indicator
            if statusManager.isLoading || stagingViewModel.isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
                    .scaleEffect(0.8)
            }
        }
    }

    // MARK: - Data Loading

    private func loadRepositoryData() async {
        // Initialize repository if not already done
        if repository == nil {
            do {
                let url = URL(fileURLWithPath: repositoryPath)
                let repo = try GitRepository(url: url)

                // Update repository on main thread
                await MainActor.run {
                    repository = repo
                }
            } catch {
                logger.error("Failed to initialize repository: \(error)")
                return
            }
        }

        await withTaskGroup(of: Void.self) { group in
            group.addTask {
                await statusManager.checkStatus()
            }

            group.addTask {
                await stagingViewModel.refreshStatus()
            }

            group.addTask {
                await diffViewModel.loadDiffs()
            }

            // Refresh repository status
            group.addTask {
                await repository?.refreshStatus()
            }
        }
    }

    private func refreshRepositoryData() async {
        await loadRepositoryData()
    }

    // MARK: - Helper Methods
}

// MARK: - Repository Tab Enum

enum RepositoryTab: String, CaseIterable {
    case changes
    case diff

    var displayName: String {
        switch self {
        case .changes:
            "Changes"
        case .diff:
            "Diff"
        }
    }
}

#Preview("Integrated Repository View") {
    IntegratedRepositoryView(repositoryPath: "/tmp/test-repo")
        .frame(width: 1000, height: 700)
}
