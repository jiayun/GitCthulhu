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

    public init(
        fileStatus: GitStatusEntry,
        isSelected: Bool = false,
        onSelectionToggle: @escaping () -> Void = {}
    ) {
        self.fileStatus = fileStatus
        self.isSelected = isSelected
        self.onSelectionToggle = onSelectionToggle
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
}

#Preview("Single File Status") {
    VStack(spacing: 8) {
        // Different status examples
        FileStatusItemView(
            fileStatus: GitStatusEntry(
                filePath: "Sources/GitCore/Models/GitRepository.swift",
                indexStatus: .modified,
                workingDirectoryStatus: .unmodified,
                originalFilePath: nil
            ),
            isSelected: false
        ) {}

        FileStatusItemView(
            fileStatus: GitStatusEntry(
                filePath: "README.md",
                indexStatus: .unmodified,
                workingDirectoryStatus: .modified,
                originalFilePath: nil
            ),
            isSelected: true
        ) {}

        FileStatusItemView(
            fileStatus: GitStatusEntry(
                filePath: "NewFile.swift",
                indexStatus: .unmodified,
                workingDirectoryStatus: .untracked,
                originalFilePath: nil
            ),
            isSelected: false
        ) {}

        FileStatusItemView(
            fileStatus: GitStatusEntry(
                filePath: "RenamedFile.swift",
                indexStatus: .renamed,
                workingDirectoryStatus: .unmodified,
                originalFilePath: "OldFile.swift"
            ),
            isSelected: false
        ) {}
    }
    .padding()
    .frame(width: 400)
}
