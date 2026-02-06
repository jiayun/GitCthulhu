//
// FileStatusListView.swift
// GitCthulhu
//
// Created by GitCthulhu Team on 2025-07-16.
//

import GitCore
import SwiftUI

// MARK: - FileStatusListView Internal State

@MainActor
public class FileStatusListState: ObservableObject {
    @Published public var selectedFilter: FileStatusFilter = .all
    @Published public var selectedGrouping: FileStatusGrouping = .status
    @Published public var searchText = ""
    @Published public var selectedFiles: Set<String> = []

    public init() {}
    public func clearSelection() { selectedFiles.removeAll() }
}

public extension FileStatusListState {
    // MARK: - Filtering and Grouping

    func filteredFileStatuses(from entries: [GitStatusEntry]) -> [GitStatusEntry] {
        let filtered = entries.filter { entry in
            // Apply filter
            let matchesFilter = switch selectedFilter {
            case .all:
                true
            case .staged:
                entry.isStaged
            case .unstaged:
                entry.hasWorkingDirectoryChanges && !entry.isUntracked
            case .untracked:
                entry.isUntracked
            case .conflicted:
                entry.hasConflicts
            }

            // Apply search
            let matchesSearch = searchText.isEmpty ||
                entry.filePath.localizedCaseInsensitiveContains(searchText) ||
                entry.displayStatus.displayName.localizedCaseInsensitiveContains(searchText)

            return matchesFilter && matchesSearch
        }

        return filtered
    }

    func groupedFileStatuses(from entries: [GitStatusEntry]) -> [FileStatusGroup] {
        let filtered = filteredFileStatuses(from: entries)

        switch selectedGrouping {
        case .none:
            return [FileStatusGroup(title: nil, files: filtered)]

        case .status:
            return groupByStatus(filtered)

        case .directory:
            return groupByDirectory(filtered)
        }
    }

    func groupByStatus(_ files: [GitStatusEntry]) -> [FileStatusGroup] {
        let grouped = Dictionary(grouping: files) { $0.displayStatus }

        let statusOrder: [GitFileStatus] = [.unmerged, .added, .modified, .deleted, .renamed, .copied, .untracked]

        return statusOrder.compactMap { status in
            guard let files = grouped[status], !files.isEmpty else { return nil }
            let title = "\(status.displayName) (\(files.count))"
            return FileStatusGroup(title: title, files: files)
        }
    }

    func groupByDirectory(_ files: [GitStatusEntry]) -> [FileStatusGroup] {
        let grouped = Dictionary(grouping: files) { entry in
            let url = URL(fileURLWithPath: entry.filePath)
            return url.deletingLastPathComponent().path
        }

        return grouped.map { directory, files in
            let title = directory.isEmpty ? "Root" : directory
            return FileStatusGroup(title: title, files: files)
        }.sorted { $0.title ?? "" < $1.title ?? "" }
    }

    // MARK: - Selection Management

    func toggleFileSelection(_ filePath: String) {
        if selectedFiles.contains(filePath) {
            selectedFiles.remove(filePath)
        } else {
            selectedFiles.insert(filePath)
        }
    }

    func selectAll(from entries: [GitStatusEntry]) {
        selectedFiles = Set(filteredFileStatuses(from: entries).map(\.filePath))
    }

    func deselectAll() {
        selectedFiles.removeAll()
    }

    var hasSelection: Bool { !selectedFiles.isEmpty }
    var selectionCount: Int { selectedFiles.count }
}

public struct FileStatusListView: View {
    @ObservedObject var repository: GitRepository
    @StateObject private var state = FileStatusListState()
    @StateObject var stagingViewModel: StagingViewModel

    private let onViewDiff: ((String) -> Void)?
    private let onStagingChanged: (() -> Void)?

    public init(
        repository: GitRepository,
        onViewDiff: ((String) -> Void)? = nil,
        onStagingChanged: (() -> Void)? = nil
    ) {
        self.repository = repository
        self.onViewDiff = onViewDiff
        self.onStagingChanged = onStagingChanged
        _stagingViewModel = StateObject(wrappedValue: StagingViewModel(repository: repository))
    }

    // Direct access to repository's status entries
    private var fileStatuses: [GitStatusEntry] {
        repository.statusEntries
    }

    private var repositoryId: String {
        let statusEntries = repository.statusEntries
        let statusString = statusEntries.map {
            "\($0.filePath):\($0.indexStatus.rawValue)\($0.workingDirectoryStatus.rawValue)"
        }.joined(separator: ",")
        return "\(repository.id)-\(statusEntries.count)-\(statusString)"
    }

    public var body: some View {
        mainView
            .onChange(of: repository.id) { _ in
                // Clear selection when repository changes
                state.clearSelection()
            }
            .id(repositoryId)
            .navigationTitle("File Status")
            .focusable()
    }

    private var mainView: some View {
        VStack(spacing: 0) {
            // Header with controls
            FileStatusListHeaderView(
                state: state,
                stagingViewModel: stagingViewModel,
                fileStatuses: fileStatuses
            )

            Divider()

            // Content area
            FileStatusListContentView(
                state: state,
                fileStatuses: fileStatuses,
                onViewDiff: onViewDiff,
                onStagingChanged: onStagingChanged,
                stagingViewModel: stagingViewModel
            )

            // Message displays
            FileStatusListMessageView(stagingViewModel: stagingViewModel)
        }
    }
}
