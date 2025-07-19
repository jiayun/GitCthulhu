//
// FileStatusListContentView.swift
// GitCthulhu
//
// Created by GitCthulhu Team on 2025-07-18.
//

import GitCore
import SwiftUI

struct FileStatusListContentView: View {
    @ObservedObject var state: FileStatusListState
    var fileStatuses: [GitStatusEntry]
    var onViewDiff: ((String) -> Void)?
    var onStagingChanged: (() -> Void)?
    @ObservedObject var stagingViewModel: StagingViewModel

    var body: some View {
        Group {
            if state.filteredFileStatuses(from: fileStatuses).isEmpty {
                emptyStateView
            } else {
                fileListView
            }
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle").font(.largeTitle).foregroundColor(.green)
            Text("No Files Found").font(.headline)
            Text(emptyStateMessage).foregroundColor(.secondary).multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity).padding()
    }

    private var emptyStateMessage: String {
        if !state.searchText.isEmpty { return "No files match your search criteria." }
        switch state.selectedFilter {
        case .all: return "Working directory is clean. No changes detected."
        case .staged: return "No files are currently staged for commit."
        case .unstaged: return "No modified files in working directory."
        case .untracked: return "No untracked files found."
        case .conflicted: return "No conflicted files found."
        }
    }

    private var fileListView: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                ForEach(state.groupedFileStatuses(from: fileStatuses), content: groupView)
            }.padding()
        }
    }

    private func groupView(_ group: FileStatusGroup) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            if let title = group.title {
                HStack {
                    Text(title).font(.headline).foregroundColor(.primary)
                    Spacer()
                    Text("\(group.files.count) files").font(.caption).foregroundColor(.secondary)
                }.padding(.horizontal, 4)
            }
            ForEach(group.files) { fileStatus in
                FileStatusItemView(
                    fileStatus: fileStatus,
                    isSelected: state.selectedFiles.contains(fileStatus.filePath),
                    onSelectionToggle: { state.toggleFileSelection(fileStatus.filePath) },
                    onStageToggle: {
                        Task {
                            await stagingViewModel.toggleFileStaging(fileStatus.filePath)
                            onStagingChanged?()
                        }
                    },
                    onViewDiff: onViewDiff.map { callback in
                        { callback(fileStatus.filePath) }
                    }
                )
            }
        }
    }
}
