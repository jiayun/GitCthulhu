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

    public init(repositoryPath: String) {
        self.repositoryPath = repositoryPath
        _statusManager = StateObject(wrappedValue: GitStatusViewModel(repositoryPath: repositoryPath))
        _stagingViewModel = StateObject(wrappedValue: StagingViewModel(repositoryPath: repositoryPath))
        _diffViewModel = StateObject(wrappedValue: DiffViewerViewModel(repositoryPath: repositoryPath))
    }

    public var body: some View {
        TabView(selection: $selectedTab) {
            // Changes tab with file status and staging
            changesTab
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
            VStack(spacing: 0) {
                // Header
                fileStatusHeader

                // File list
                if let repository {
                    FileStatusListView(
                        repository: repository,
                        onViewDiff: { filePath in
                            selectedFileForDiff = filePath
                        },
                        onStagingChanged: {
                            Task {
                                await repository.refreshStatus()
                            }
                        }
                    )
                    .id(repository.id) // Force refresh when repository changes
                } else {
                    Text("Loading repository...")
                        .foregroundColor(.secondary)
                }
            }
            .frame(minWidth: 300, idealWidth: 400)

            // Right: Staging area
            if let repository {
                StagingAreaView(
                    repository: repository,
                    selectedFiles: .constant(Set<String>()),
                    onStageFiles: { filePaths in
                        Task {
                            await stagingViewModel.stageSelectedFiles(Set(filePaths))
                            // Refresh repository status after staging
                            await repository.refreshStatus()
                        }
                    },
                    onUnstageFiles: { filePaths in
                        Task {
                            await stagingViewModel.unstageSelectedFiles(Set(filePaths))
                            // Refresh repository status after unstaging
                            await repository.refreshStatus()
                        }
                    },
                    onStageAll: {
                        Task {
                            await stagingViewModel.stageAllFiles()
                            // Refresh repository status after staging all
                            await repository.refreshStatus()
                        }
                    },
                    onUnstageAll: {
                        Task {
                            await stagingViewModel.unstageAllFiles()
                            // Refresh repository status after unstaging all
                            await repository.refreshStatus()
                        }
                    }
                )
                .frame(minWidth: 300, idealWidth: 400)
                .id(repository.id) // Force refresh when repository changes
            } else {
                VStack {
                    Text("Staging Area")
                        .font(.headline)
                        .padding()

                    Text("Loading...")
                        .foregroundColor(.secondary)
                        .padding()

                    Spacer()
                }
                .frame(minWidth: 300, idealWidth: 400)
            }
        }
    }

    private var diffTab: some View {
        DiffViewerView(repositoryPath: repositoryPath)
    }

    // MARK: - Headers and Toolbars

    private var fileStatusHeader: some View {
        HStack {
            Text("Changed Files")
                .font(.headline)
                .fontWeight(.medium)

            Spacer()

            // Status summary
            if !statusManager.statusEntries.isEmpty {
                Text("\(statusManager.statusEntries.count) files changed")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color(NSColor.controlBackgroundColor))
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color(NSColor.separatorColor)),
            alignment: .bottom
        )
    }

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
                print("Failed to initialize repository: \(error)")
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
