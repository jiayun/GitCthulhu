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
            fileHeader

            // Column headers
            columnHeaders

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

    private var columnHeaders: some View {
        HStack(spacing: 0) {
            // Left column header (old version)
            VStack(spacing: 4) {
                HStack {
                    Image(systemName: "minus.circle")
                        .foregroundColor(.red)

                    Text(diff.oldPath ?? diff.filePath)
                        .font(.caption)
                        .fontWeight(.medium)
                        .lineLimit(1)

                    Spacer()
                }

                if diff.deletionsCount > 0 {
                    Text("\(diff.deletionsCount) deletions")
                        .font(.caption2)
                        .foregroundColor(.red)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.red.opacity(0.05))

            // Divider
            Rectangle()
                .frame(width: 1)
                .foregroundColor(Color(NSColor.separatorColor))

            // Right column header (new version)
            VStack(spacing: 4) {
                HStack {
                    Image(systemName: "plus.circle")
                        .foregroundColor(.green)

                    Text(diff.filePath)
                        .font(.caption)
                        .fontWeight(.medium)
                        .lineLimit(1)

                    Spacer()
                }

                if diff.additionsCount > 0 {
                    Text("\(diff.additionsCount) additions")
                        .font(.caption2)
                        .foregroundColor(.green)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.green.opacity(0.05))
        }
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color(NSColor.separatorColor)),
            alignment: .bottom
        )
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

        for i in 0 ..< maxCount {
            let left = i < leftLines.count ? leftLines[i] : nil
            let right = i < rightLines.count ? rightLines[i] : nil

            result.append(SideBySideLinePair(left: left, right: right))
        }

        leftLines.removeAll()
        rightLines.removeAll()
    }
}

/// Represents a pair of lines for side-by-side display
struct SideBySideLinePair {
    let left: GitDiffLine?
    let right: GitDiffLine?
}

/// Individual line view in side-by-side diff
struct SideBySideLineView: View {
    let leftLine: GitDiffLine?
    let rightLine: GitDiffLine?
    let showWhitespace: Bool
    let showLineNumbers: Bool

    var body: some View {
        HStack(spacing: 0) {
            // Left side (old version)
            SideBySideLineContentView(
                line: leftLine,
                side: .left,
                showWhitespace: showWhitespace,
                showLineNumbers: showLineNumbers
            )
            .frame(maxWidth: .infinity, alignment: .leading)

            // Divider
            Rectangle()
                .frame(width: 1)
                .foregroundColor(Color(NSColor.separatorColor))

            // Right side (new version)
            SideBySideLineContentView(
                line: rightLine,
                side: .right,
                showWhitespace: showWhitespace,
                showLineNumbers: showLineNumbers
            )
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(minHeight: 20)
        .fixedSize(horizontal: false, vertical: true)
    }
}

/// Content view for one side of the side-by-side diff
struct SideBySideLineContentView: View {
    let line: GitDiffLine?
    let side: DiffSide
    let showWhitespace: Bool
    let showLineNumbers: Bool

    var body: some View {
        HStack(spacing: 0) {
            // Line number
            if showLineNumbers {
                lineNumber
            }

            // Line content
            lineContent
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(lineBackgroundColor)
        .overlay(
            // Left border for line type
            Rectangle()
                .frame(width: 2)
                .foregroundColor(lineIndicatorColor),
            alignment: .leading
        )
    }

    private var lineNumber: some View {
        Text(displayLineNumber)
            .frame(width: 50, alignment: .trailing)
            .foregroundColor(.secondary)
            .font(.custom("SF Mono", size: 11))
            .padding(.horizontal, 8)
            .background(Color(NSColor.controlBackgroundColor))
    }

    private var lineContent: some View {
        Text(displayContent)
            .font(.custom("SF Mono", size: 11))
            .foregroundColor(lineTextColor)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 12)
            .padding(.vertical, 2)
            .textSelection(.enabled)
    }

    private var displayLineNumber: String {
        guard let line else { return "" }

        switch side {
        case .left:
            return line.oldLineNumber?.description ?? ""
        case .right:
            return line.newLineNumber?.description ?? ""
        }
    }

    private var displayContent: String {
        guard let line else { return "" }

        let content = showWhitespace ?
            line.content
            .replacingOccurrences(of: " ", with: "·")
            .replacingOccurrences(of: "\t", with: "→") :
            line.content

        return content
    }

    private var lineBackgroundColor: Color {
        guard let line else { return Color.clear }

        switch line.type {
        case .addition:
            return side == .right ? Color.green.opacity(0.15) : Color.clear
        case .deletion:
            return side == .left ? Color.red.opacity(0.15) : Color.clear
        case .context:
            return Color.clear
        case .noNewline, .header, .fileHeader, .meta:
            return Color(NSColor.controlBackgroundColor)
        }
    }

    private var lineIndicatorColor: Color {
        guard let line else { return Color.clear }

        switch line.type {
        case .addition:
            return side == .right ? .green : .clear
        case .deletion:
            return side == .left ? .red : .clear
        case .context:
            return .clear
        case .noNewline, .header, .fileHeader, .meta:
            return .secondary
        }
    }

    private var lineTextColor: Color {
        guard let line else { return Color.secondary }

        switch line.type {
        case .addition, .deletion, .context:
            return .primary
        case .noNewline, .header, .fileHeader, .meta:
            return .secondary
        }
    }
}

/// Represents which side of the diff we're displaying
enum DiffSide {
    case left
    case right
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

    SideBySideDiffView(
        diff: sampleDiff,
        showWhitespace: false,
        showLineNumbers: true
    )
    .frame(width: 800, height: 600)
}
