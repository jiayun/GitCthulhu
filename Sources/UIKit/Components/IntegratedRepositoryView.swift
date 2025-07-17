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
                FileStatusListView(
                    statusEntries: statusManager.statusEntries,
                    selectedFiles: .constant(Set<String>()),
                    stagingViewModel: stagingViewModel,
                    onFileSelected: { filePath in
                        selectedFileForDiff = filePath
                    },
                    onViewDiff: { filePath in
                        selectedFileForDiff = filePath
                    }
                )
            }
            .frame(minWidth: 300, idealWidth: 400)

            // Right: Staging area
            VStack {
                Text("Staging Area")
                    .font(.headline)
                    .padding()

                // Placeholder for staging area - would need proper implementation
                Text("Staging area functionality coming soon")
                    .foregroundColor(.secondary)
                    .padding()

                Spacer()
            }
            .frame(minWidth: 300, idealWidth: 400)
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
        }
    }

    private func refreshRepositoryData() async {
        await loadRepositoryData()
    }
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

// MARK: - Enhanced File Status List View

extension FileStatusListView {
    init(
        statusEntries: [GitStatusEntry],
        selectedFiles: Binding<Set<String>>,
        stagingViewModel: StagingViewModel,
        onFileSelected: @escaping (String) -> Void = { _ in },
        onViewDiff: @escaping (String) -> Void = { _ in }
    ) {
        self.statusEntries = statusEntries
        self._selectedFiles = selectedFiles
        self.stagingViewModel = stagingViewModel

        // Note: These closures are currently not used in FileStatusListView
        // but are available for future implementation
        _ = onFileSelected
        _ = onViewDiff
    }
}

#Preview("Integrated Repository View") {
    IntegratedRepositoryView(repositoryPath: "/tmp/test-repo")
        .frame(width: 1000, height: 700)
}
