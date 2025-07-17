//
// DiffViewerView.swift
// GitCthulhu
//
// Created by GitCthulhu Team on 2025-07-17.
//

import SwiftUI
import GitCore

/// Main diff viewer component
public struct DiffViewerView: View {
    @ObservedObject private var viewModel: DiffViewerViewModel
    @State private var selectedFileId: String?

    public init(repositoryPath: String) {
        self.viewModel = DiffViewerViewModel(repositoryPath: repositoryPath)
    }

    public var body: some View {
        HSplitView {
            // Left panel: File navigator
            DiffFileNavigator(
                diffs: viewModel.filteredDiffs,
                selectedFilePath: $viewModel.selectedFilePath,
                searchQuery: $viewModel.searchQuery,
                onFileSelected: { filePath in
                    viewModel.selectFile(filePath)
                }
            )
            .frame(minWidth: 250, idealWidth: 300, maxWidth: 400)

            // Right panel: Diff content
            DiffContentView(
                diff: viewModel.selectedDiff,
                viewMode: viewModel.viewMode,
                showWhitespace: viewModel.showWhitespace,
                showLineNumbers: viewModel.showLineNumbers
            )
            .frame(minWidth: 400)
        }
        .toolbar {
            DiffViewerToolbar(
                viewModel: viewModel
            )
        }
        .navigationTitle("Diff Viewer")
        .onAppear {
            Task {
                await viewModel.loadDiffs()
            }
        }
        .alert("Error", isPresented: .constant(viewModel.error != nil)) {
            Button("OK") {
                viewModel.clearError()
            }
        } message: {
            if let error = viewModel.error {
                Text(error.localizedDescription)
            }
        }
    }
}

/// File navigator component
struct DiffFileNavigator: View {
    let diffs: [GitDiff]
    @Binding var selectedFilePath: String?
    @Binding var searchQuery: String
    let onFileSelected: (String) -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Search bar
            searchBar

            // File list
            fileList
        }
        .background(Color(NSColor.controlBackgroundColor))
    }

    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)

            TextField("Search files...", text: $searchQuery)
                .textFieldStyle(.plain)

            if !searchQuery.isEmpty {
                Button(action: { searchQuery = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(NSColor.textBackgroundColor))
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color(NSColor.separatorColor)),
            alignment: .bottom
        )
    }

    private var fileList: some View {
        ScrollView {
            LazyVStack(spacing: 1) {
                ForEach(diffs) { diff in
                    DiffFileItem(
                        diff: diff,
                        isSelected: selectedFilePath == diff.filePath,
                        onSelected: {
                            onFileSelected(diff.filePath)
                        }
                    )
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

/// Individual file item in the navigator
struct DiffFileItem: View {
    let diff: GitDiff
    let isSelected: Bool
    let onSelected: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            // Change type icon
            Image(systemName: diff.changeType.symbol)
                .foregroundColor(changeTypeColor)
                .frame(width: 16)

            // File info
            VStack(alignment: .leading, spacing: 2) {
                // File name
                Text(diff.fileName)
                    .font(.callout)
                    .fontWeight(isSelected ? .medium : .regular)
                    .foregroundColor(.primary)
                    .lineLimit(1)

                // Directory path
                if let directoryPath = diff.directoryPath {
                    Text(directoryPath)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }

                // Change type and stats
                HStack(spacing: 8) {
                    Text(diff.changeType.displayName)
                        .font(.caption2)
                        .foregroundColor(changeTypeColor)

                    if !diff.isBinary && diff.hasChanges {
                        DiffStatsView(stats: diff.stats)
                    } else if diff.isBinary {
                        Text("Binary")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }

            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            Rectangle()
                .fill(isSelected ? Color.accentColor.opacity(0.15) : Color.clear)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            onSelected()
        }
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color(NSColor.separatorColor)),
            alignment: .bottom
        )
    }

    private var changeTypeColor: Color {
        switch diff.changeType {
        case .added:
            return .green
        case .deleted:
            return .red
        case .modified:
            return .orange
        case .renamed:
            return .blue
        case .copied:
            return .purple
        case .unmerged:
            return .red
        case .typeChanged:
            return .yellow
        case .unknown:
            return .gray
        }
    }
}

/// Diff statistics display component
struct DiffStatsView: View {
    let stats: GitDiffStats

    var body: some View {
        HStack(spacing: 4) {
            if stats.additions > 0 {
                HStack(spacing: 2) {
                    Text("+\(stats.additions)")
                        .font(.caption2)
                        .foregroundColor(.green)
                }
            }

            if stats.deletions > 0 {
                HStack(spacing: 2) {
                    Text("-\(stats.deletions)")
                        .font(.caption2)
                        .foregroundColor(.red)
                }
            }
        }
    }
}

/// Main diff content display
struct DiffContentView: View {
    let diff: GitDiff?
    let viewMode: DiffViewMode
    let showWhitespace: Bool
    let showLineNumbers: Bool

    var body: some View {
        Group {
            if let diff = diff {
                if diff.isBinary {
                    BinaryFileView(diff: diff)
                } else {
                    switch viewMode {
                    case .unified:
                        UnifiedDiffView(
                            diff: diff,
                            showWhitespace: showWhitespace,
                            showLineNumbers: showLineNumbers
                        )
                    case .sideBySide:
                        SideBySideDiffView(
                            diff: diff,
                            showWhitespace: showWhitespace,
                            showLineNumbers: showLineNumbers
                        )
                    }
                }
            } else {
                DiffEmptyState()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(NSColor.textBackgroundColor))
    }
}

/// Empty state when no file is selected
struct DiffEmptyState: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 48))
                .foregroundColor(.secondary)

            Text("No File Selected")
                .font(.title2)
                .fontWeight(.medium)
                .foregroundColor(.primary)

            Text("Select a file from the navigator to view its diff")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

/// Binary file display
struct BinaryFileView: View {
    let diff: GitDiff

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.fill")
                .font(.system(size: 48))
                .foregroundColor(.secondary)

            Text("Binary File")
                .font(.title2)
                .fontWeight(.medium)
                .foregroundColor(.primary)

            Text(diff.displayPath)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Text("Binary files cannot be displayed as text diff")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

/// Toolbar for diff viewer
struct DiffViewerToolbar: View {
    @ObservedObject var viewModel: DiffViewerViewModel

    var body: some View {
        HStack {
            // View mode selector
            Picker("View Mode", selection: $viewModel.viewMode) {
                ForEach(DiffViewMode.allCases) { mode in
                    Label(mode.displayName, systemImage: mode.icon)
                        .tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .frame(width: 200)

            Spacer()

            // Options
            Toggle("Line Numbers", isOn: $viewModel.showLineNumbers)
                .toggleStyle(.checkbox)

            Toggle("Whitespace", isOn: $viewModel.showWhitespace)
                .toggleStyle(.checkbox)

            // Staged/Unstaged toggle
            Toggle(viewModel.showStaged ? "Staged" : "Unstaged", isOn: $viewModel.showStaged)
                .toggleStyle(.switch)
                .onChange(of: viewModel.showStaged) { _ in
                    viewModel.toggleStaged()
                }

            // Navigation buttons
            Button(action: viewModel.selectPreviousFile) {
                Image(systemName: "chevron.up")
            }
            .disabled(!viewModel.canNavigatePrevious)

            Button(action: viewModel.selectNextFile) {
                Image(systemName: "chevron.down")
            }
            .disabled(!viewModel.canNavigateNext)

            // Refresh button
            Button(action: viewModel.refresh) {
                Image(systemName: "arrow.clockwise")
            }
            .disabled(viewModel.isLoading)
        }
    }
}

#Preview("Diff Viewer") {
    DiffViewerView(repositoryPath: "/tmp/test-repo")
        .frame(width: 800, height: 600)
}
