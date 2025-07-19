//
// FileStatusListHeaderView.swift
// GitCthulhu
//
// Created by GitCthulhu Team on 2025-07-18.
//

import GitCore
import SwiftUI

struct FileStatusListHeaderView: View {
    @ObservedObject var state: FileStatusListState
    @ObservedObject var stagingViewModel: StagingViewModel
    var fileStatuses: [GitStatusEntry]

    var body: some View {
        VStack(spacing: 12) {
            searchAndFilterControls
            groupingAndSelectionControls
            statusSummary
        }
        .padding()
        .background(Color(NSColor.windowBackgroundColor))
    }

    private var searchAndFilterControls: some View {
        HStack {
            // Search field
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("Search files...", text: $state.searchText)
                    .textFieldStyle(.plain)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(6)

            // Filter picker
            Picker("Filter", selection: $state.selectedFilter) {
                ForEach(FileStatusFilter.allCases) { filter in
                    Label(filter.rawValue, systemImage: filter.systemImage)
                        .tag(filter)
                }
            }
            .pickerStyle(.menu)
            .frame(width: 140)
        }
    }

    private var groupingAndSelectionControls: some View {
        HStack {
            // Grouping picker
            Picker("Group by", selection: $state.selectedGrouping) {
                ForEach(FileStatusGrouping.allCases) { grouping in
                    Text(grouping.rawValue)
                        .tag(grouping)
                }
            }
            .pickerStyle(.segmented)

            Spacer()

            // Selection controls
            if state.hasSelection {
                selectionControls
            }

            // Global staging actions
            if !state.hasSelection {
                globalStagingControls
            }
        }
    }

    private var selectionControls: some View {
        HStack(spacing: 8) {
            Text("\(state.selectionCount) selected")
                .font(.caption)
                .foregroundColor(.secondary)

            Button("Select All") { state.selectAll(from: fileStatuses) }.font(.caption)

            Button("Deselect All") { state.deselectAll() }.font(.caption)

            // Staging operations for selected files
            if state.hasSelection {
                Divider()
                    .frame(height: 16)

                stagingControlsForSelection
            }
        }
    }

    private var stagingControlsForSelection: some View {
        HStack(spacing: 6) {
            // Stage selected files
            Button(action: {
                Task {
                    await stagingViewModel.stageSelectedFiles(state.selectedFiles)
                    // onStagingChanged?() // This callback needs to be handled by parent
                }
            }) {
                Label("Stage", systemImage: "plus.circle.fill")
                    .font(.caption)
            }
            .disabled(stagingViewModel.isLoading)
            .controlSize(.small)

            // Unstage selected files
            Button(action: {
                Task {
                    await stagingViewModel.unstageSelectedFiles(state.selectedFiles)
                    // onStagingChanged?() // This callback needs to be handled by parent
                }
            }) {
                Label("Unstage", systemImage: "minus.circle.fill")
                    .font(.caption)
            }
            .disabled(stagingViewModel.isLoading)
            .controlSize(.small)

            // Toggle staging for selected files
            Button(action: {
                Task {
                    await stagingViewModel.toggleSelectedFilesStaging(state.selectedFiles)
                    // onStagingChanged?() // This callback needs to be handled by parent
                }
            }) {
                Label("Toggle", systemImage: "arrow.up.arrow.down.circle")
                    .font(.caption)
            }
            .disabled(stagingViewModel.isLoading)
            .controlSize(.small)
        }
    }

    private var globalStagingControls: some View {
        HStack(spacing: 8) {
            stagingButton("Stage All", icon: "plus.circle.fill", disabled: !stagingViewModel.hasChangesToStage) {
                await stagingViewModel.stageAllFiles()
                // onStagingChanged?() // This callback needs to be handled by parent
            }
            stagingButton("Unstage All", icon: "minus.circle.fill", disabled: !stagingViewModel.hasStagedChanges) {
                await stagingViewModel.unstageAllFiles()
                // onStagingChanged?() // This callback needs to be handled by parent
            }
            stagingButton("Stage Modified", icon: "pencil.circle.fill") {
                await stagingViewModel.stageModifiedFiles()
                // onStagingChanged?() // This callback needs to be handled by parent
            }
            stagingButton("Stage Untracked", icon: "plus.circle.fill") {
                await stagingViewModel.stageUntrackedFiles()
                // onStagingChanged?() // This callback needs to be handled by parent
            }
        }
    }

    private func stagingButton(
        _ title: String,
        icon: String,
        disabled: Bool = false,
        action: @escaping () async -> Void
    ) -> some View {
        Button(action: { Task { await action() } }) {
            Label(title, systemImage: icon).font(.caption)
        }
        .disabled(stagingViewModel.isLoading || disabled)
        .controlSize(.small)
    }

    private var statusSummary: some View {
        HStack {
            let filtered = state.filteredFileStatuses(from: fileStatuses)
            let counts = (
                total: filtered.count,
                staged: filtered.filter(\.isStaged).count,
                modified: filtered.filter { $0.hasWorkingDirectoryChanges && !$0.isUntracked }.count,
                untracked: filtered.filter(\.isUntracked).count,
                conflicted: filtered.filter(\.hasConflicts).count
            )

            summaryBadge(count: counts.total, label: "Total", color: .primary)
            if counts.staged > 0 { summaryBadge(count: counts.staged, label: "Staged", color: .green) }
            if counts.modified > 0 { summaryBadge(count: counts.modified, label: "Modified", color: .orange) }
            if counts.untracked > 0 { summaryBadge(count: counts.untracked, label: "Untracked", color: .gray) }
            if counts.conflicted > 0 { summaryBadge(count: counts.conflicted, label: "Conflicts", color: .red) }
            Spacer()
        }
    }

    private func summaryBadge(count: Int, label: String, color: Color) -> some View {
        HStack(spacing: 2) {
            Text("\(count)").fontWeight(.medium)
            Text(label)
        }
        .font(.caption).foregroundColor(color)
        .padding(.horizontal, 8).padding(.vertical, 2)
        .background(color.opacity(0.1)).cornerRadius(4)
    }
}
