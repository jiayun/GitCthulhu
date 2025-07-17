//
// DiffLineView.swift
// GitCthulhu
//
// Created by GitCthulhu Team on 2025-07-17.
//

import SwiftUI
import GitCore

/// Enhanced diff line view with syntax highlighting
public struct DiffLineView: View {
    let line: GitDiffLine
    let language: String
    let showWhitespace: Bool
    let showLineNumbers: Bool
    let showSyntaxHighlighting: Bool

    @State private var highlighter = SyntaxHighlighter()

    public init(
        line: GitDiffLine,
        language: String = "text",
        showWhitespace: Bool = false,
        showLineNumbers: Bool = true,
        showSyntaxHighlighting: Bool = true
    ) {
        self.line = line
        self.language = language
        self.showWhitespace = showWhitespace
        self.showLineNumbers = showLineNumbers
        self.showSyntaxHighlighting = showSyntaxHighlighting
    }

    public var body: some View {
        HStack(spacing: 0) {
            // Line numbers
            if showLineNumbers {
                lineNumbers
            }

            // Line content
            lineContent

            Spacer(minLength: 0)
        }
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
        HStack(spacing: 8) {
            // Old line number
            Text(line.oldLineNumber?.description ?? "")
                .frame(width: 40, alignment: .trailing)
                .foregroundColor(.secondary)
                .font(.custom("SF Mono", size: 11))

            // New line number
            Text(line.newLineNumber?.description ?? "")
                .frame(width: 40, alignment: .trailing)
                .foregroundColor(.secondary)
                .font(.custom("SF Mono", size: 11))

            // Separator
            Text(line.type.symbol)
                .frame(width: 16, alignment: .center)
                .foregroundColor(lineIndicatorColor)
                .font(.custom("SF Mono", size: 11))
        }
        .padding(.horizontal, 8)
        .background(Color(NSColor.controlBackgroundColor))
    }

    private var lineContent: some View {
        Group {
            if showSyntaxHighlighting && line.type.isContentLine && language != "text" {
                // Syntax highlighted content
                Text(highlightedContent)
                    .textSelection(.enabled)
            } else {
                // Plain text content
                Text(displayContent)
                    .font(.custom("SF Mono", size: 11))
                    .foregroundColor(lineTextColor)
                    .textSelection(.enabled)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 12)
        .padding(.vertical, 2)
    }

    private var displayContent: String {
        if showWhitespace {
            return line.content
                .replacingOccurrences(of: " ", with: "·")
                .replacingOccurrences(of: "\t", with: "→")
        } else {
            return line.content
        }
    }

    private var highlightedContent: AttributedString {
        let content = displayContent
        return highlighter.highlight(content, language: language)
    }

    private var lineBackgroundColor: Color {
        switch line.type {
        case .addition:
            return Color.green.opacity(0.15)
        case .deletion:
            return Color.red.opacity(0.15)
        case .context:
            return Color.clear
        case .noNewline, .header, .fileHeader, .meta:
            return Color(NSColor.controlBackgroundColor)
        }
    }

    private var lineIndicatorColor: Color {
        switch line.type {
        case .addition:
            return .green
        case .deletion:
            return .red
        case .context:
            return .clear
        case .noNewline, .header, .fileHeader, .meta:
            return .secondary
        }
    }

    private var lineTextColor: Color {
        switch line.type {
        case .addition:
            return .primary
        case .deletion:
            return .primary
        case .context:
            return .primary
        case .noNewline, .header, .fileHeader, .meta:
            return .secondary
        }
    }
}

/// Enhanced unified diff view with syntax highlighting
public struct EnhancedUnifiedDiffView: View {
    let diff: GitDiff
    let showWhitespace: Bool
    let showLineNumbers: Bool
    let showSyntaxHighlighting: Bool

    @State private var selectedChunkId: UUID?
    @State private var highlighter = SyntaxHighlighter()

    private var language: String {
        highlighter.detectLanguage(from: diff.filePath)
    }

    public init(
        diff: GitDiff,
        showWhitespace: Bool = false,
        showLineNumbers: Bool = true,
        showSyntaxHighlighting: Bool = true
    ) {
        self.diff = diff
        self.showWhitespace = showWhitespace
        self.showLineNumbers = showLineNumbers
        self.showSyntaxHighlighting = showSyntaxHighlighting
    }

    public var body: some View {
        ScrollView([.horizontal, .vertical]) {
            LazyVStack(spacing: 0) {
                // File header with language info
                fileHeader

                // Diff chunks
                ForEach(diff.chunks) { chunk in
                    EnhancedDiffChunkView(
                        chunk: chunk,
                        language: language,
                        showWhitespace: showWhitespace,
                        showLineNumbers: showLineNumbers,
                        showSyntaxHighlighting: showSyntaxHighlighting,
                        isSelected: selectedChunkId == chunk.id,
                        onSelected: {
                            selectedChunkId = chunk.id
                        }
                    )
                }

                // Empty state if no chunks
                if diff.chunks.isEmpty && !diff.isBinary {
                    emptyDiffState
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .font(.custom("SF Mono", size: 12))
        .background(Color(NSColor.textBackgroundColor))
    }

    private var fileHeader: some View {
        VStack(spacing: 4) {
            // File path with language indicator
            HStack {
                Image(systemName: diff.changeType.symbol)
                    .foregroundColor(changeTypeColor)

                Text(diff.displayPath)
                    .font(.headline)
                    .fontWeight(.medium)

                // Language indicator
                if language != "text" {
                    Text(language.uppercased())
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.secondary.opacity(0.1))
                        .cornerRadius(3)
                }

                Spacer()

                // File stats
                if !diff.isBinary {
                    DiffStatsView(stats: diff.stats)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)

            // Syntax highlighting toggle
            if showSyntaxHighlighting && language != "text" {
                HStack {
                    Image(systemName: "paintbrush.fill")
                        .foregroundColor(.blue)
                        .font(.caption)

                    Text("Syntax highlighting enabled for \(language)")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 4)
            }

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

/// Enhanced chunk view with syntax highlighting
struct EnhancedDiffChunkView: View {
    let chunk: GitDiffChunk
    let language: String
    let showWhitespace: Bool
    let showLineNumbers: Bool
    let showSyntaxHighlighting: Bool
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
            ForEach(Array(chunk.lines.enumerated()), id: \.offset) { index, line in
                DiffLineView(
                    line: line,
                    language: language,
                    showWhitespace: showWhitespace,
                    showLineNumbers: showLineNumbers,
                    showSyntaxHighlighting: showSyntaxHighlighting
                )
            }
        }
    }
}

#Preview("Enhanced Diff with Syntax Highlighting") {
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

    EnhancedUnifiedDiffView(
        diff: sampleDiff,
        showWhitespace: false,
        showLineNumbers: true,
        showSyntaxHighlighting: true
    )
    .frame(width: 600, height: 400)
}
