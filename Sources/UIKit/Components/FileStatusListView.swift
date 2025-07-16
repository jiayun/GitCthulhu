//
// FileStatusListView.swift
// GitCthulhu
//
// Created by GitCthulhu Team on 2025-07-16.
//

import GitCore
import SwiftUI

// MARK: - Supporting Types

public enum FileStatusFilter: String, CaseIterable, Identifiable {
    case all = "All Files"
    case staged = "Staged Only"
    case unstaged = "Modified Only"
    case untracked = "Untracked Only"
    case conflicted = "Conflicted Only"

    public var id: String { rawValue }

    public var systemImage: String {
        switch self {
        case .all: "doc.on.doc"
        case .staged: "checkmark.circle"
        case .unstaged: "pencil.circle"
        case .untracked: "plus.circle"
        case .conflicted: "exclamationmark.triangle"
        }
    }
}

public enum FileStatusGrouping: String, CaseIterable, Identifiable {
    case none = "No Grouping"
    case status = "Group by Status"
    case directory = "Group by Directory"

    public var id: String { rawValue }
}

public struct FileStatusGroup: Identifiable {
    public let id = UUID()
    public let title: String?
    public let files: [GitStatusEntry]

    public init(title: String?, files: [GitStatusEntry]) {
        self.title = title
        self.files = files
    }
}

// MARK: - FileStatusListView Internal State

@MainActor
public class FileStatusListState: ObservableObject {
    @Published public var selectedFilter: FileStatusFilter = .all
    @Published public var selectedGrouping: FileStatusGrouping = .status
    @Published public var searchText = ""
    @Published public var selectedFiles: Set<String> = []

    public init() {}

    public func clearSelection() {
        selectedFiles.removeAll()
    }
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

    var hasSelection: Bool {
        !selectedFiles.isEmpty
    }

    var selectionCount: Int {
        selectedFiles.count
    }
}

public struct FileStatusListView: View {
    @ObservedObject private var repository: GitRepository
    @StateObject private var state = FileStatusListState()

    public init(repository: GitRepository) {
        self.repository = repository
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
        VStack(spacing: 0) {
            // Header with controls
            headerView

            Divider()

            // Content area
            contentView
        }
        .onChange(of: repository.id) { _ in
            // Clear selection when repository changes
            state.clearSelection()
        }
        .id(repositoryId)
        .navigationTitle("File Status")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                refreshButton
            }
        }
    }

    // MARK: - Header View

    private var headerView: some View {
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
        }
    }

    private var selectionControls: some View {
        HStack(spacing: 8) {
            Text("\(state.selectionCount) selected")
                .font(.caption)
                .foregroundColor(.secondary)

            Button("Select All") {
                state.selectAll(from: fileStatuses)
            }
            .font(.caption)

            Button("Deselect All") {
                state.deselectAll()
            }
            .font(.caption)
        }
    }

    private var statusSummary: some View {
        HStack {
            let filtered = state.filteredFileStatuses(from: fileStatuses)
            let totalCount = filtered.count
            let stagedCount = filtered.filter(\.isStaged).count
            let modifiedCount = filtered.filter { $0.hasWorkingDirectoryChanges && !$0.isUntracked }.count
            let untrackedCount = filtered.filter(\.isUntracked).count
            let conflictedCount = filtered.filter(\.hasConflicts).count

            summaryBadge(count: totalCount, label: "Total", color: .primary)

            if stagedCount > 0 {
                summaryBadge(count: stagedCount, label: "Staged", color: .green)
            }

            if modifiedCount > 0 {
                summaryBadge(count: modifiedCount, label: "Modified", color: .orange)
            }

            if untrackedCount > 0 {
                summaryBadge(count: untrackedCount, label: "Untracked", color: .gray)
            }

            if conflictedCount > 0 {
                summaryBadge(count: conflictedCount, label: "Conflicts", color: .red)
            }

            Spacer()
        }
    }

    private func summaryBadge(count: Int, label: String, color: Color) -> some View {
        HStack(spacing: 2) {
            Text("\(count)")
                .fontWeight(.medium)
            Text(label)
        }
        .font(.caption)
        .foregroundColor(color)
        .padding(.horizontal, 8)
        .padding(.vertical, 2)
        .background(color.opacity(0.1))
        .cornerRadius(4)
    }

    // MARK: - Content View

    private var contentView: some View {
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
            Image(systemName: "checkmark.circle")
                .font(.largeTitle)
                .foregroundColor(.green)

            Text("No Files Found")
                .font(.headline)

            Text(emptyStateMessage)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    private var emptyStateMessage: String {
        if !state.searchText.isEmpty {
            "No files match your search criteria."
        } else {
            switch state.selectedFilter {
            case .all:
                "Working directory is clean. No changes detected."
            case .staged:
                "No files are currently staged for commit."
            case .unstaged:
                "No modified files in working directory."
            case .untracked:
                "No untracked files found."
            case .conflicted:
                "No conflicted files found."
            }
        }
    }

    private var fileListView: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                ForEach(state.groupedFileStatuses(from: fileStatuses)) { group in
                    groupView(group)
                }
            }
            .padding()
        }
    }

    private func groupView(_ group: FileStatusGroup) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            // Group header (if grouping is enabled)
            if let title = group.title {
                HStack {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.primary)

                    Spacer()

                    Text("\(group.files.count) files")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 4)
            }

            // File items
            ForEach(group.files) { fileStatus in
                FileStatusItemView(
                    fileStatus: fileStatus,
                    isSelected: state.selectedFiles.contains(fileStatus.filePath),
                    onSelectionToggle: {
                        state.toggleFileSelection(fileStatus.filePath)
                    }
                )
            }
        }
    }

    private var refreshButton: some View {
        Button(action: {
            Task {
                await repository.refreshStatus()
            }
        }) {
            Image(systemName: "arrow.clockwise")
        }
        .help("Refresh file status")
    }
}

#Preview("File Status List") {
    // Note: This preview requires a GitRepository instance
    // In real usage, this would be provided by the parent view
    VStack {
        Text("File Status List Preview")
            .font(.title)

        Text("This component requires a GitRepository instance")
            .font(.caption)
            .foregroundColor(.secondary)

        Text("It will display:")
            .font(.subheadline)
            .padding(.top)

        VStack(alignment: .leading, spacing: 4) {
            Text("• Search and filter controls")
            Text("• File grouping options")
            Text("• Status indicators with colors")
            Text("• File selection capabilities")
            Text("• Real-time status updates")
        }
        .font(.caption)
        .foregroundColor(.secondary)
    }
    .frame(width: 500, height: 400)
    .padding()
}
