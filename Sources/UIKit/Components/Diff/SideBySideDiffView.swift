//
// SideBySideDiffView.swift
// GitCthulhu
//
// Created by GitCthulhu Team on 2025-07-17.
//

import GitCore
import SwiftUI

/// Side-by-side diff view component
public struct SideBySideDiffView: View {
    let diff: GitDiff
    let showWhitespace: Bool
    let showLineNumbers: Bool

    @State private var selectedChunkId: UUID?
    @State private var scrollPosition: CGPoint = .zero

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
        VStack(spacing: 0) {
            // File header
            SideBySideDiffHeaderView(diff: diff)

            // Diff content
            ScrollView([.horizontal, .vertical]) {
                LazyVStack(spacing: 0) {
                    ForEach(diff.chunks) { chunk in
                        SideBySideDiffChunkView(
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
        }
        .font(.custom("SF Mono", size: 12))
        .background(Color(NSColor.textBackgroundColor))
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

/// Individual chunk view in side-by-side diff
struct SideBySideDiffChunkView: View {
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
        let sideBySideLines = buildSideBySideLines(from: chunk.lines)

        return LazyVStack(spacing: 0) {
            ForEach(Array(sideBySideLines.enumerated()), id: \.offset) { _, linePair in
                SideBySideLineView(
                    leftLine: linePair.left,
                    rightLine: linePair.right,
                    showWhitespace: showWhitespace,
                    showLineNumbers: showLineNumbers
                )
            }
        }
    }

    private func buildSideBySideLines(from lines: [GitDiffLine]) -> [SideBySideLinePair] {
        var result: [SideBySideLinePair] = []
        var leftLines: [GitDiffLine] = []
        var rightLines: [GitDiffLine] = []

        for line in lines {
            switch line.type {
            case .context:
                // Flush any pending changes
                flushPendingLines(leftLines: &leftLines, rightLines: &rightLines, result: &result)

                // Add context line to both sides
                result.append(SideBySideLinePair(left: line, right: line))

            case .deletion:
                leftLines.append(line)

            case .addition:
                rightLines.append(line)

            case .noNewline, .header, .fileHeader, .meta:
                // Flush any pending changes
                flushPendingLines(leftLines: &leftLines, rightLines: &rightLines, result: &result)

                // Add meta line to both sides
                result.append(SideBySideLinePair(left: line, right: line))
            }
        }

        // Flush any remaining changes
        flushPendingLines(leftLines: &leftLines, rightLines: &rightLines, result: &result)

        return result
    }

    private func flushPendingLines(
        leftLines: inout [GitDiffLine],
        rightLines: inout [GitDiffLine],
        result: inout [SideBySideLinePair]
    ) {
        let maxCount = max(leftLines.count, rightLines.count)

        for index in 0 ..< maxCount {
            let left = index < leftLines.count ? leftLines[index] : nil
            let right = index < rightLines.count ? rightLines[index] : nil

            result.append(SideBySideLinePair(left: left, right: right))
        }

        leftLines.removeAll()
        rightLines.removeAll()
    }
}

#Preview("Side by Side Diff") {
    let sampleDiff = GitDiff(
        filePath: "Sources/Example/TestFile.swift",
        changeType: .modified,
        chunks: [
            GitDiffChunk(
                oldStart: 1,
                oldCount: 5,
                newStart: 1,
                newCount: 6,
                headerLine: "@@ -1,5 +1,6 @@ func example()",
                context: "func example()",
                lines: [
                    .context(oldLineNumber: 1, newLineNumber: 1, content: "func example() {"),
                    .deletion(oldLineNumber: 2, content: "    let oldCode = true"),
                    .addition(newLineNumber: 2, content: "    let newCode = false"),
                    .addition(newLineNumber: 3, content: "    let additionalLine = true"),
                    .context(oldLineNumber: 3, newLineNumber: 4, content: "    return value"),
                    .context(oldLineNumber: 4, newLineNumber: 5, content: "}")
                ]
            )
        ]
    )

    SideBySideDiffView(
        diff: sampleDiff,
        showWhitespace: false,
        showLineNumbers: true
    )
    .frame(width: 800, height: 600)
}
