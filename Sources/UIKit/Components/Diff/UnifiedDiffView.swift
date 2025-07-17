//
// UnifiedDiffView.swift
// GitCthulhu
//
// Created by GitCthulhu Team on 2025-07-17.
//

import GitCore
import SwiftUI

/// Unified diff view component
public struct UnifiedDiffView: View {
    let diff: GitDiff
    let showWhitespace: Bool
    let showLineNumbers: Bool

    @State private var selectedChunkId: UUID?

    public init(
        diff: GitDiff,
        showWhitespace: Bool = false,
        showLineNumbers: Bool = true
    ) {
        self.diff = diff
        self.showWhitespace = showWhitespace
        self.showLineNumbers = showLineNumbers
    }

    public var body: some View {
        ScrollView([.horizontal, .vertical]) {
            LazyVStack(spacing: 0) {
                // File header
                fileHeader

                // Diff chunks
                ForEach(diff.chunks) { chunk in
                    UnifiedDiffChunkView(
                        chunk: chunk,
                        showWhitespace: showWhitespace,
                        showLineNumbers: showLineNumbers,
                        isSelected: selectedChunkId == chunk.id,
                        onSelected: {
                            selectedChunkId = chunk.id
                        }
                    )
                }

                // Empty state if no chunks
                if diff.chunks.isEmpty, !diff.isBinary {
                    emptyDiffState
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .font(.custom("SF Mono", size: 12))
        .background(Color(NSColor.textBackgroundColor))
    }

    private var fileHeader: some View {
        VStack(spacing: 4) {
            // File path
            HStack {
                Image(systemName: diff.changeType.symbol)
                    .foregroundColor(changeTypeColor)

                Text(diff.displayPath)
                    .font(.headline)
                    .fontWeight(.medium)

                Spacer()

                // File stats
                if !diff.isBinary {
                    DiffStatsView(stats: diff.stats)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)

            // Change type info
            if diff.isRenamed || diff.isNew || diff.isDeleted {
                HStack {
                    Text(diff.changeType.displayName)
                        .font(.caption)
                        .foregroundColor(changeTypeColor)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(changeTypeColor.opacity(0.1))
                        .cornerRadius(4)

                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
            }

            Divider()
        }
        .background(Color(NSColor.controlBackgroundColor))
    }

    private var emptyDiffState: some View {
        VStack(spacing: 12) {
            Image(systemName: "doc.text")
                .font(.system(size: 32))
                .foregroundColor(.secondary)

            Text("No changes to display")
                .font(.body)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 200)
        .background(Color(NSColor.textBackgroundColor))
    }

    private var changeTypeColor: Color {
        switch diff.changeType {
        case .added:
            .green
        case .deleted:
            .red
        case .modified:
            .orange
        case .renamed:
            .blue
        case .copied:
            .purple
        case .unmerged:
            .red
        case .typeChanged:
            .yellow
        case .unknown:
            .gray
        }
    }
}

/// Individual chunk view in unified diff
struct UnifiedDiffChunkView: View {
    let chunk: GitDiffChunk
    let showWhitespace: Bool
    let showLineNumbers: Bool
    let isSelected: Bool
    let onSelected: () -> Void

    @State private var isCollapsed: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            // Chunk header
            chunkHeader

            // Chunk content
            if !isCollapsed {
                chunkContent
            }
        }
        .background(isSelected ? Color.accentColor.opacity(0.05) : Color.clear)
        .onTapGesture {
            onSelected()
        }
    }

    private var chunkHeader: some View {
        HStack {
            // Collapse/expand button
            Button(action: { isCollapsed.toggle() }) {
                Image(systemName: isCollapsed ? "chevron.right" : "chevron.down")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)

            // Header line
            Text(chunk.headerLine)
                .font(.custom("SF Mono", size: 11))
                .foregroundColor(.secondary)

            // Context info
            if let context = chunk.context {
                Text(context)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .italic()
            }

            Spacer()

            // Chunk stats
            HStack(spacing: 8) {
                if chunk.additionsCount > 0 {
                    Text("+\(chunk.additionsCount)")
                        .font(.caption2)
                        .foregroundColor(.green)
                }

                if chunk.deletionsCount > 0 {
                    Text("-\(chunk.deletionsCount)")
                        .font(.caption2)
                        .foregroundColor(.red)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
        .background(Color(NSColor.controlBackgroundColor))
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color(NSColor.separatorColor)),
            alignment: .bottom
        )
    }

    private var chunkContent: some View {
        LazyVStack(spacing: 0) {
            ForEach(Array(chunk.lines.enumerated()), id: \.offset) { _, line in
                UnifiedDiffLineView(
                    line: line,
                    showWhitespace: showWhitespace,
                    showLineNumbers: showLineNumbers
                )
            }
        }
    }
}

/// Individual line view in unified diff
struct UnifiedDiffLineView: View {
    let line: GitDiffLine
    let showWhitespace: Bool
    let showLineNumbers: Bool

    var body: some View {
        HStack(spacing: 0) {
            // Line numbers
            if showLineNumbers {
                lineNumbers
                    .layoutPriority(1)
            }

            // Line content
            lineContent

            Spacer(minLength: 0)
        }
        .frame(minHeight: 18)
        .background(lineBackgroundColor)
        .overlay(
            // Left border for line type
            Rectangle()
                .frame(width: 3)
                .foregroundColor(lineIndicatorColor),
            alignment: .leading
        )
    }

    private var lineNumbers: some View {
        HStack(spacing: 4) {
            // Old line number
            Text(line.oldLineNumber?.description ?? "")
                .frame(width: 35, alignment: .trailing)
                .foregroundColor(.secondary)
                .font(.custom("SF Mono", size: 10))

            // New line number
            Text(line.newLineNumber?.description ?? "")
                .frame(width: 35, alignment: .trailing)
                .foregroundColor(.secondary)
                .font(.custom("SF Mono", size: 10))

            // Separator
            Text(line.type.symbol)
                .frame(width: 12, alignment: .center)
                .foregroundColor(lineIndicatorColor)
                .font(.custom("SF Mono", size: 10))
        }
        .padding(.horizontal, 6)
        .background(Color(NSColor.controlBackgroundColor))
    }

    private var lineContent: some View {
        Text(displayContent)
            .font(.custom("SF Mono", size: 11))
            .foregroundColor(lineTextColor)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 8)
            .padding(.vertical, 1)
            .textSelection(.enabled)
            .fixedSize(horizontal: false, vertical: true)
    }

    private var displayContent: String {
        if showWhitespace {
            line.content
                .replacingOccurrences(of: " ", with: "·")
                .replacingOccurrences(of: "\t", with: "→")
        } else {
            line.content
        }
    }

    private var lineBackgroundColor: Color {
        switch line.type {
        case .addition:
            Color.green.opacity(0.15)
        case .deletion:
            Color.red.opacity(0.15)
        case .context:
            Color.clear
        case .noNewline, .header, .fileHeader, .meta:
            Color(NSColor.controlBackgroundColor)
        }
    }

    private var lineIndicatorColor: Color {
        switch line.type {
        case .addition:
            .green
        case .deletion:
            .red
        case .context:
            .clear
        case .noNewline, .header, .fileHeader, .meta:
            .secondary
        }
    }

    private var lineTextColor: Color {
        switch line.type {
        case .addition:
            .primary
        case .deletion:
            .primary
        case .context:
            .primary
        case .noNewline, .header, .fileHeader, .meta:
            .secondary
        }
    }
}

#Preview("Unified Diff") {
    let sampleDiff = GitDiff(
        filePath: "Sources/Example/TestFile.swift",
        changeType: .modified,
        chunks: [
            GitDiffChunk(
                oldStart: 1,
                oldCount: 5,
                newStart: 1,
                newCount: 6,
                context: "func example()",
                lines: [
                    .context(oldLineNumber: 1, newLineNumber: 1, content: "func example() {"),
                    .deletion(oldLineNumber: 2, content: "    let oldCode = true"),
                    .addition(newLineNumber: 2, content: "    let newCode = false"),
                    .addition(newLineNumber: 3, content: "    let additionalLine = true"),
                    .context(oldLineNumber: 3, newLineNumber: 4, content: "    return value"),
                    .context(oldLineNumber: 4, newLineNumber: 5, content: "}")
                ],
                headerLine: "@@ -1,5 +1,6 @@ func example()"
            )
        ]
    )

    UnifiedDiffView(
        diff: sampleDiff,
        showWhitespace: false,
        showLineNumbers: true
    )
    .frame(width: 600, height: 400)
}
