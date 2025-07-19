//
// IntegratedRepositoryChangesTab.swift
// GitCthulhu
//
// Created by GitCthulhu Team on 2025-07-18.
//

import GitCore
import SwiftUI

struct IntegratedRepositoryChangesTab: View {
    @ObservedObject var statusManager: GitStatusViewModel
    @ObservedObject var stagingViewModel: StagingViewModel
    @ObservedObject var diffViewModel: DiffViewerViewModel
    @Binding var repository: GitRepository?
    @Binding var selectedFileForDiff: String?

    var body: some View {
        HSplitView {
            fileStatusSection
            stagingAreaSection
        }
    }

    private var fileStatusSection: some View {
        VStack(spacing: 0) {
            // Header
            fileStatusHeader

            // File list
            if let repository {
                FileStatusListView(
                    repository: repository,
                    onViewDiff: handleViewDiff,
                    onStagingChanged: handleStagingChanged
                )
                .id(repository.id) // Force refresh when repository changes
            } else {
                Text("Loading repository...")
                    .foregroundColor(.secondary)
            }
        }
        .frame(minWidth: 300, idealWidth: 400)
    }

    private var stagingAreaSection: some View {
        Group {
            if let repository {
                StagingAreaView(
                    repository: repository,
                    selectedFiles: .constant(Set<String>()),
                    onStageFiles: performStageFiles,
                    onUnstageFiles: performUnstageFiles,
                    onStageAll: performStageAll,
                    onUnstageAll: performUnstageAll
                )
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
                .id("loading-state")
            }
        }
        .frame(minWidth: 300, idealWidth: 400)
    }

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

    private func performStageFiles(filePaths: [String]) {
        Task {
            await stagingViewModel.stageSelectedFiles(Set(filePaths))
            await repository?.refreshStatus()
        }
    }

    private func performUnstageFiles(filePaths: [String]) {
        Task {
            await stagingViewModel.unstageSelectedFiles(Set(filePaths))
            await repository?.refreshStatus()
        }
    }

    private func performStageAll() {
        Task {
            await stagingViewModel.stageAllFiles()
            await repository?.refreshStatus()
        }
    }

    private func performUnstageAll() {
        Task {
            await stagingViewModel.unstageAllFiles()
            await repository?.refreshStatus()
        }
    }

    private func handleViewDiff(filePath: String) {
        selectedFileForDiff = filePath
    }

    private func handleStagingChanged() {
        Task {
            await repository?.refreshStatus()
        }
    }
}
