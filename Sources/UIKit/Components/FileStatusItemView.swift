//
// FileStatusItemView.swift
// GitCthulhu
//
// Created by GitCthulhu Team on 2025-07-16.
//

import GitCore
import SwiftUI

public struct FileStatusItemView: View {
    let fileStatus: GitStatusEntry
    let isSelected: Bool
    let onSelectionToggle: () -> Void
    let onStageToggle: (() -> Void)?
    let onViewDiff: (() -> Void)?

    public init(
        fileStatus: GitStatusEntry,
        isSelected: Bool = false,
        onSelectionToggle: @escaping () -> Void = {},
        onStageToggle: (() -> Void)? = nil,
        onViewDiff: (() -> Void)? = nil
    ) {
        self.fileStatus = fileStatus
        self.isSelected = isSelected
        self.onSelectionToggle = onSelectionToggle
        self.onStageToggle = onStageToggle
        self.onViewDiff = onViewDiff
    }

    public var body: some View {
        HStack(spacing: 12) {
            // Selection checkbox
            Button(action: onSelectionToggle) {
                Image(systemName: isSelected ? "checkmark.square.fill" : "square")
                    .foregroundColor(isSelected ? .accentColor : .secondary)
                    .font(.system(size: 16))
            }
            .buttonStyle(.plain)
            .help("Toggle selection")

            // Status icon and indicator
            statusIndicator

            // File information
            VStack(alignment: .leading, spacing: 2) {
                // File name and path
                filePathView

                // Additional status information
                if let originalPath = fileStatus.originalFilePath {
                    Text("renamed from: \(originalPath)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .italic()
                }
            }

            Spacer()

            // View Diff button
            if let onViewDiff {
                viewDiffButton(onViewDiff: onViewDiff)
            }

            // Stage/Unstage button
            if let onStageToggle {
                stageButton(onStageToggle: onStageToggle)
            }

            // Status badges
            statusBadges
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .background(backgroundColor)
        .cornerRadius(6)
        .contentShape(Rectangle())
        .onTapGesture {
            onSelectionToggle()
        }
        .conditionalDraggable(fileStatus.filePath) {
            dragPreview
        }
    }

    // MARK: - View Components

    private var statusIndicator: some View {
        HStack(spacing: 4) {
            // Main status icon
            Image(systemName: fileStatus.displayStatus.symbolName)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(statusColor)
                .frame(width: 16)

            // Status circle indicator
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)
        }
    }

    private var filePathView: some View {
        HStack(spacing: 4) {
            // File icon
            Image(systemName: fileIcon)
                .font(.caption)
                .foregroundColor(.secondary)

            // Simplified file path display - avoid Text concatenation
            HStack(spacing: 2) {
                if let directoryPath, !directoryPath.isEmpty {
                    Text(directoryPath)
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text("/")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Text(fileName)
                    .font(.callout)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
            }
        }
    }

    private var statusBadges: some View {
        HStack(spacing: 4) {
            // Priority order: Conflict > Staged/Modified > Untracked
            // Show primary status badge with proper precedence
            if fileStatus.hasConflicts {
                statusBadge(text: "Conflict", color: .red)
            } else if fileStatus.isStaged, fileStatus.hasWorkingDirectoryChanges {
                // File is both staged AND has working directory changes
                statusBadge(text: "Staged", color: .green)
                statusBadge(text: "Modified", color: .orange)
            } else if fileStatus.isStaged {
                statusBadge(text: "Staged", color: .green)
            } else if fileStatus.hasWorkingDirectoryChanges, !fileStatus.isUntracked {
                statusBadge(text: "Modified", color: .orange)
            } else if fileStatus.isUntracked {
                statusBadge(text: "Untracked", color: .gray)
            }
        }
    }

    private func statusBadge(text: String, color: Color) -> some View {
        Text(text)
            .font(.caption2)
            .fontWeight(.medium)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color.opacity(0.15))
            .foregroundColor(color)
            .cornerRadius(4)
    }

    private func viewDiffButton(onViewDiff: @escaping () -> Void) -> some View {
        Button(action: onViewDiff) {
            HStack(spacing: 4) {
                Image(systemName: "doc.text.magnifyingglass")
                    .font(.system(size: 12, weight: .medium))

                Text("Diff")
                    .font(.caption2)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.blue.opacity(0.15))
            .foregroundColor(.blue)
            .cornerRadius(4)
        }
        .buttonStyle(.plain)
        .help("View file diff")
    }

    private func stageButton(onStageToggle: @escaping () -> Void) -> some View {
        Button(action: onStageToggle) {
            HStack(spacing: 4) {
                Image(systemName: stageButtonIcon)
                    .font(.system(size: 12, weight: .medium))

                Text(stageButtonText)
                    .font(.caption2)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(stageButtonColor.opacity(0.15))
            .foregroundColor(stageButtonColor)
            .cornerRadius(4)
        }
        .buttonStyle(.plain)
        .help(stageButtonHelpText)
    }

    // MARK: - Computed Properties

    private var statusColor: Color {
        switch fileStatus.displayStatus {
        case .untracked:
            .gray
        case .modified:
            .orange
        case .added:
            .green
        case .deleted:
            .red
        case .renamed:
            .blue
        case .copied:
            .purple
        case .unmerged:
            .red
        case .ignored:
            .secondary
        }
    }

    private var backgroundColor: Color {
        if isSelected {
            Color.accentColor.opacity(0.1)
        } else {
            Color.clear
        }
    }

    private var fileName: String {
        URL(fileURLWithPath: fileStatus.filePath).lastPathComponent
    }

    private var directoryPath: String? {
        let url = URL(fileURLWithPath: fileStatus.filePath)
        let directory = url.deletingLastPathComponent().path
        return directory.isEmpty || directory == "." ? nil : directory
    }

    private var fileIcon: String {
        let fileExtension = URL(fileURLWithPath: fileStatus.filePath).pathExtension.lowercased()

        switch fileExtension {
        case "swift":
            return "swift"
        case "js", "ts", "jsx", "tsx":
            return "doc.text.fill"
        case "py":
            return "doc.text"
        case "java", "kt":
            return "doc.text.fill"
        case "cpp", "c", "h", "hpp":
            return "doc.text"
        case "md", "markdown":
            return "doc.richtext"
        case "json", "xml", "yaml", "yml":
            return "doc.text.below.ecg"
        case "txt":
            return "doc.plaintext"
        case "png", "jpg", "jpeg", "gif", "svg":
            return "photo"
        case "pdf":
            return "doc.pdf"
        default:
            return "doc"
        }
    }

    // MARK: - Stage Button Properties

    private var stageButtonIcon: String {
        if fileStatus.isStaged {
            "minus.circle"
        } else {
            "plus.circle"
        }
    }

    private var stageButtonText: String {
        if fileStatus.isStaged {
            "Unstage"
        } else {
            "Stage"
        }
    }

    private var stageButtonColor: Color {
        if fileStatus.isStaged {
            .orange
        } else {
            .green
        }
    }

    private var stageButtonHelpText: String {
        if fileStatus.isStaged {
            "Unstage this file from the commit"
        } else {
            "Stage this file for commit"
        }
    }

    // MARK: - Drag Preview

    private var dragPreview: some View {
        HStack(spacing: 8) {
            // Status indicator
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)

            // File icon
            Image(systemName: fileIcon)
                .font(.caption)
                .foregroundColor(.secondary)

            // File name
            Text(fileName)
                .font(.callout)
                .fontWeight(.medium)
                .lineLimit(1)

            // Stage indicator
            Image(systemName: fileStatus.isStaged ? "checkmark.circle.fill" : "plus.circle")
                .font(.caption)
                .foregroundColor(fileStatus.isStaged ? .green : .orange)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
        .shadow(radius: 2)
    }
}

#Preview("Single File Status") {
    FileStatusItemPreview()
}

private struct FileStatusItemPreview: View {
    var body: some View {
        VStack(spacing: 8) {
            stagedFileExample
            modifiedFileExample
            untrackedFileExample
            renamedFileExample
        }
        .padding()
        .frame(width: 400)
    }

    private var stagedFileExample: some View {
        FileStatusItemView(
            fileStatus: GitStatusEntry(
                filePath: "Sources/GitCore/Models/GitRepository.swift",
                indexStatus: .modified,
                workingDirectoryStatus: .unmodified,
                originalFilePath: nil
            ),
            isSelected: false,
            onStageToggle: {},
            onViewDiff: {}
        )
    }

    private var modifiedFileExample: some View {
        FileStatusItemView(
            fileStatus: GitStatusEntry(
                filePath: "README.md",
                indexStatus: .unmodified,
                workingDirectoryStatus: .modified,
                originalFilePath: nil
            ),
            isSelected: true,
            onStageToggle: {},
            onViewDiff: {}
        )
    }

    private var untrackedFileExample: some View {
        FileStatusItemView(
            fileStatus: GitStatusEntry(
                filePath: "NewFile.swift",
                indexStatus: .unmodified,
                workingDirectoryStatus: .untracked,
                originalFilePath: nil
            ),
            isSelected: false,
            onStageToggle: {},
            onViewDiff: {}
        )
    }

    private var renamedFileExample: some View {
        FileStatusItemView(
            fileStatus: GitStatusEntry(
                filePath: "RenamedFile.swift",
                indexStatus: .renamed,
                workingDirectoryStatus: .unmodified,
                originalFilePath: "OldFile.swift"
            ),
            isSelected: false,
            onStageToggle: {},
            onViewDiff: {}
        )
    }
}
