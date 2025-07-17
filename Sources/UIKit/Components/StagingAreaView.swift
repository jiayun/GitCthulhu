//
// StagingAreaView.swift
// GitCthulhu
//
// Created by GitCthulhu Team on 2025-07-16.
//

import GitCore
import SwiftUI

/// A dedicated view for the staging area with drag-and-drop support
public struct StagingAreaView: View {
    @ObservedObject private var repository: GitRepository
    @Binding private var selectedFiles: Set<String>

    let onStageFiles: ([String]) -> Void
    let onUnstageFiles: ([String]) -> Void
    let onStageAll: () -> Void
    let onUnstageAll: () -> Void

    @State private var isDropTargeted = false
    @State private var draggedFiles: [String] = []

    public init(
        repository: GitRepository,
        selectedFiles: Binding<Set<String>>,
        onStageFiles: @escaping ([String]) -> Void,
        onUnstageFiles: @escaping ([String]) -> Void,
        onStageAll: @escaping () -> Void,
        onUnstageAll: @escaping () -> Void
    ) {
        self.repository = repository
        _selectedFiles = selectedFiles
        self.onStageFiles = onStageFiles
        self.onUnstageFiles = onUnstageFiles
        self.onStageAll = onStageAll
        self.onUnstageAll = onUnstageAll
    }

    // Get staged files from repository
    private var stagedFiles: [GitStatusEntry] {
        repository.statusEntries.filter(\.isStaged)
    }

    // Get unstaged files from repository
    private var unstagedFiles: [GitStatusEntry] {
        repository.statusEntries.filter { $0.hasWorkingDirectoryChanges || $0.isUntracked }
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Header
            headerView

            Divider()

            // Main content
            HStack(spacing: 0) {
                // Unstaged files section
                unstagedSection

                Divider()

                // Staged files section
                stagedSection
            }
        }
        .navigationTitle("Staging Area")
    }

    // MARK: - Header View

    private var headerView: some View {
        HStack {
            // Title
            Text("Staging Area")
                .font(.headline)
                .fontWeight(.semibold)

            Spacer()

            // Action buttons
            HStack(spacing: 8) {
                // Stage all button
                Button(action: onStageAll) {
                    Label("Stage All", systemImage: "plus.circle.fill")
                        .font(.caption)
                }
                .disabled(unstagedFiles.isEmpty)
                .buttonStyle(.bordered)
                .controlSize(.small)

                // Unstage all button
                Button(action: onUnstageAll) {
                    Label("Unstage All", systemImage: "minus.circle.fill")
                        .font(.caption)
                }
                .disabled(stagedFiles.isEmpty)
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
        }
        .padding()
        .background(Color(NSColor.windowBackgroundColor))
    }

    // MARK: - Unstaged Section

    private var unstagedSection: some View {
        VStack(spacing: 0) {
            // Section header
            sectionHeader(
                title: "Changes",
                count: unstagedFiles.count,
                color: .orange
            )

            // Files list
            if unstagedFiles.isEmpty {
                emptyState(
                    icon: "checkmark.circle",
                    title: "No Changes",
                    subtitle: "All changes are staged"
                )
            } else {
                filesList(files: unstagedFiles, isStaged: false)
            }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Staged Section

    private var stagedSection: some View {
        VStack(spacing: 0) {
            // Section header
            sectionHeader(
                title: "Staged",
                count: stagedFiles.count,
                color: .green
            )

            // Files list with drop target
            if stagedFiles.isEmpty {
                emptyDropTarget
            } else {
                filesList(files: stagedFiles, isStaged: true)
            }
        }
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isDropTargeted ? Color.accentColor.opacity(0.1) : Color.clear)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isDropTargeted ? Color.accentColor : Color.clear, lineWidth: 2)
        )
        .onDrop(of: ["public.file-url"], isTargeted: $isDropTargeted) { providers in
            handleDrop(providers: providers)
        }
    }

    // MARK: - Helper Views

    private func sectionHeader(title: String, count: Int, color: Color) -> some View {
        HStack {
            HStack(spacing: 6) {
                Circle()
                    .fill(color)
                    .frame(width: 8, height: 8)

                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text("(\(count))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color(NSColor.controlBackgroundColor))
    }

    private func filesList(files: [GitStatusEntry], isStaged: Bool) -> some View {
        ScrollView {
            LazyVStack(spacing: 4) {
                ForEach(files) { file in
                    FileStatusItemView(
                        fileStatus: file,
                        isSelected: selectedFiles.contains(file.filePath),
                        onSelectionToggle: {
                            toggleSelection(file.filePath)
                        },
                        onStageToggle: {
                            if isStaged {
                                onUnstageFiles([file.filePath])
                            } else {
                                onStageFiles([file.filePath])
                            }
                        }
                    )
                    .conditionalDraggable(file.filePath) {
                        dragPreview(for: file)
                    }
                }
            }
            .padding()
        }
    }

    private func emptyState(icon: String, title: String, subtitle: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.secondary)

            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)

            Text(subtitle)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    private var emptyDropTarget: some View {
        VStack(spacing: 16) {
            Image(systemName: "arrow.down.circle.dotted")
                .font(.title)
                .foregroundColor(.secondary)

            Text("Drop files here to stage")
                .font(.subheadline)
                .foregroundColor(.secondary)

            Text("Drag files from the changes section or file explorer")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(NSColor.controlBackgroundColor).opacity(0.3))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.secondary.opacity(0.3), style: StrokeStyle(lineWidth: 1, dash: [5]))
                )
        )
        .padding()
    }

    private func dragPreview(for file: GitStatusEntry) -> some View {
        HStack {
            Image(systemName: "doc.text")
                .foregroundColor(.secondary)

            Text(URL(fileURLWithPath: file.filePath).lastPathComponent)
                .font(.caption)
        }
        .padding(8)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(6)
    }

    // MARK: - Helper Methods

    private func toggleSelection(_ filePath: String) {
        if selectedFiles.contains(filePath) {
            selectedFiles.remove(filePath)
        } else {
            selectedFiles.insert(filePath)
        }
    }

    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        // Handle file drops to staging area
        // This is a simplified implementation
        for provider in providers {
            provider.loadItem(forTypeIdentifier: "public.file-url") { item, _ in
                if let data = item as? Data,
                   let url = URL(dataRepresentation: data, relativeTo: nil) {
                    let filePath = url.path

                    // Check if file is in repository and not already staged
                    if unstagedFiles.contains(where: { $0.filePath == filePath }) {
                        DispatchQueue.main.async {
                            onStageFiles([filePath])
                        }
                    }
                }
            }
        }
        return true
    }
}

// MARK: - Preview

#Preview("Staging Area") {
    StagingAreaPreview()
}

private struct StagingAreaPreview: View {
    @State private var selectedFiles: Set<String> = []
    @State private var mockRepository = createMockRepository()

    var body: some View {
        StagingAreaView(
            repository: mockRepository,
            selectedFiles: $selectedFiles,
            onStageFiles: { _ in
                // Preview placeholder - no operation
            },
            onUnstageFiles: { _ in
                // Preview placeholder - no operation
            },
            onStageAll: {
                // Preview placeholder - no operation
            },
            onUnstageAll: {
                // Preview placeholder - no operation
            }
        )
        .frame(width: 800, height: 600)
    }

    private static func createMockRepository() -> GitRepository {
        // This is a placeholder for preview
        // In real implementation, this would be a proper GitRepository instance
        let url = URL(fileURLWithPath: "/tmp/mock-repo")
        // swiftlint:disable:next force_try
        return try! GitRepository(url: url)
    }
}
