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
    @StateObject private var stagingViewModel: StagingViewModel

    public init(repository: GitRepository) {
        self.repository = repository
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
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    refreshButton
                }
            }
            .focusable()
    }

    private var mainView: some View {
        VStack(spacing: 0) {
            // Header with controls
            headerView

            Divider()

            // Content area
            contentView

            // Message displays
            messageDisplays
        }
    }

    private var messageDisplays: some View {
        VStack(spacing: 0) {
            // Error message display
            if let errorMessage = stagingViewModel.errorMessage {
                errorBanner(message: errorMessage)
            }

            // Success message display
            if let successMessage = stagingViewModel.lastOperationSuccessMessage {
                successBanner(message: successMessage)
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

            Button("Select All") {
                state.selectAll(from: fileStatuses)
            }
            .font(.caption)

            Button("Deselect All") {
                state.deselectAll()
            }
            .font(.caption)

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
            }
            stagingButton("Unstage All", icon: "minus.circle.fill", disabled: !stagingViewModel.hasStagedChanges) {
                await stagingViewModel.unstageAllFiles()
            }
            stagingButton("Stage Modified", icon: "pencil.circle.fill") {
                await stagingViewModel.stageModifiedFiles()
            }
            stagingButton("Stage Untracked", icon: "plus.circle.fill") {
                await stagingViewModel.stageUntrackedFiles()
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
                    onStageToggle: { Task { await stagingViewModel.toggleFileStaging(fileStatus.filePath) } }
                )
            }
        }
    }

    private var refreshButton: some View {
        Button(action: {
            Task {
                await repository.refreshStatus()
                await stagingViewModel.refreshStagingStatus()
            }
        }) {
            Image(systemName: "arrow.clockwise")
        }.help("Refresh file status")
    }

    private func errorBanner(message: String) -> some View {
        banner(message: message, color: .red, icon: "exclamationmark.triangle.fill") { stagingViewModel.clearError() }
    }

    private func successBanner(message: String) -> some View {
        banner(message: message, color: .green, icon: "checkmark.circle.fill") { stagingViewModel.clearLastResult() }
    }

    private func banner(message: String, color: Color, icon: String, onDismiss: @escaping () -> Void) -> some View {
        HStack {
            Image(systemName: icon).foregroundColor(color)
            Text(message).font(.caption).foregroundColor(color)
            Spacer()
            Button("Dismiss", action: onDismiss).font(.caption).foregroundColor(color)
        }
        .padding(.horizontal, 16).padding(.vertical, 8)
        .background(color.opacity(0.1)).cornerRadius(6)
        .padding(.horizontal, 16).padding(.bottom, 8)
    }
}
