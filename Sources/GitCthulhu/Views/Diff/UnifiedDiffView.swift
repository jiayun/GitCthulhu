//
// UnifiedDiffView.swift
// GitCthulhu
//
// Created by GitCthulhu Team on 2025-07-15.
//

import GitCore
import SwiftUI

struct UnifiedDiffView: View {
    let diffContent: DiffContent
    let showLineNumbers: Bool
    @Binding var expandedHunks: Set<Int>
    
    var body: some View {
        LazyVStack(spacing: 0) {
            ForEach(diffContent.hunks.indices, id: \.self) { hunkIndex in
                VStack(spacing: 0) {
                    // Hunk header
                    hunkHeader(for: diffContent.hunks[hunkIndex], index: hunkIndex)
                    
                    // Hunk content (if expanded)
                    if expandedHunks.contains(hunkIndex) {
                        hunkContent(for: diffContent.hunks[hunkIndex])
                    }
                }
            }
        }
        .font(.system(.body, design: .monospaced))
    }
    
    // MARK: - Hunk Header
    
    private func hunkHeader(for hunk: DiffHunk, index: Int) -> some View {
        Button(action: {
            if expandedHunks.contains(index) {
                expandedHunks.remove(index)
            } else {
                expandedHunks.insert(index)
            }
        }) {
            HStack {
                Image(systemName: expandedHunks.contains(index) ? "chevron.down" : "chevron.right")
                    .foregroundColor(.blue)
                    .font(.caption)
                
                Text("@@ -\(hunk.oldStartLine),\(hunk.oldLineCount) +\(hunk.newStartLine),\(hunk.newLineCount) @@")
                    .foregroundColor(.secondary)
                    .font(.system(.caption, design: .monospaced))
                
                if !hunk.context.isEmpty {
                    Text(hunk.context)
                        .foregroundColor(.secondary)
                        .font(.system(.caption, design: .monospaced))
                }
                
                Spacer()
                
                // Line count summary
                Text("\(hunk.lines.count) lines")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(4)
        }
        .buttonStyle(.plain)
        .padding(.horizontal)
        .padding(.vertical, 4)
    }
    
    // MARK: - Hunk Content
    
    private func hunkContent(for hunk: DiffHunk) -> some View {
        VStack(spacing: 0) {
            ForEach(hunk.lines.indices, id: \.self) { lineIndex in
                let line = hunk.lines[lineIndex]
                diffLineView(for: line)
            }
        }
    }
    
    // MARK: - Diff Line View
    
    private func diffLineView(for line: DiffLine) -> some View {
        HStack(spacing: 0) {
            // Line type indicator
            lineTypeIndicator(for: line.type)
            
            // Line numbers
            if showLineNumbers {
                lineNumbers(for: line)
            }
            
            // Content with syntax highlighting
            lineContent(for: line)
            
            Spacer()
        }
        .background(lineBackgroundColor(for: line.type))
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    // MARK: - Line Type Indicator
    
    private func lineTypeIndicator(for type: DiffLineType) -> some View {
        let (symbol, color) = lineTypeSymbolAndColor(for: type)
        
        return Text(symbol)
            .font(.system(.body, design: .monospaced))
            .foregroundColor(color)
            .frame(width: 20, alignment: .center)
            .background(lineBackgroundColor(for: type))
    }
    
    // MARK: - Line Numbers
    
    private func lineNumbers(for line: DiffLine) -> some View {
        HStack(spacing: 4) {
            // Old line number
            Text(line.oldLineNumber?.description ?? "")
                .font(.system(.caption, design: .monospaced))
                .foregroundColor(.secondary)
                .frame(width: 40, alignment: .trailing)
            
            // New line number
            Text(line.newLineNumber?.description ?? "")
                .font(.system(.caption, design: .monospaced))
                .foregroundColor(.secondary)
                .frame(width: 40, alignment: .trailing)
        }
        .padding(.horizontal, 8)
        .background(Color(NSColor.controlBackgroundColor).opacity(0.3))
    }
    
    // MARK: - Line Content
    
    private func lineContent(for line: DiffLine) -> some View {
        SyntaxHighlightedText(
            content: line.content,
            language: detectLanguage(from: diffContent.filePath),
            lineType: line.type
        )
        .font(.system(.body, design: .monospaced))
        .padding(.horizontal, 8)
        .padding(.vertical, 2)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    // MARK: - Helper Functions
    
    private func lineTypeSymbolAndColor(for type: DiffLineType) -> (String, Color) {
        switch type {
        case .added:
            return ("+", .green)
        case .removed:
            return ("-", .red)
        case .context:
            return (" ", .secondary)
        case .noNewlineAtEnd:
            return ("\\", .orange)
        }
    }
    
    private func lineBackgroundColor(for type: DiffLineType) -> Color {
        switch type {
        case .added:
            return Color.green.opacity(0.1)
        case .removed:
            return Color.red.opacity(0.1)
        case .context:
            return Color.clear
        case .noNewlineAtEnd:
            return Color.orange.opacity(0.1)
        }
    }
    
    private func detectLanguage(from filePath: String) -> String {
        let fileExtension = (filePath as NSString).pathExtension.lowercased()
        switch fileExtension {
        case "swift":
            return "swift"
        case "js", "jsx":
            return "javascript"
        case "ts", "tsx":
            return "typescript"
        case "py":
            return "python"
        case "java":
            return "java"
        case "cpp", "cc", "cxx":
            return "cpp"
        case "c":
            return "c"
        case "h", "hpp":
            return "c"
        case "go":
            return "go"
        case "rs":
            return "rust"
        case "rb":
            return "ruby"
        case "php":
            return "php"
        case "html", "htm":
            return "html"
        case "css":
            return "css"
        case "xml":
            return "xml"
        case "json":
            return "json"
        case "yaml", "yml":
            return "yaml"
        case "md":
            return "markdown"
        case "sh", "bash":
            return "bash"
        default:
            return "plaintext"
        }
    }
}

#Preview {
    let sampleDiff = DiffContent(
        filePath: "Sources/GitCore/Example.swift",
        hunks: [
            DiffHunk(
                oldStartLine: 1,
                oldLineCount: 5,
                newStartLine: 1,
                newLineCount: 6,
                context: "function example()",
                lines: [
                    DiffLine(type: .context, content: "import Foundation", oldLineNumber: 1, newLineNumber: 1),
                    DiffLine(type: .context, content: "", oldLineNumber: 2, newLineNumber: 2),
                    DiffLine(type: .removed, content: "func oldFunction() {", oldLineNumber: 3, newLineNumber: nil),
                    DiffLine(type: .added, content: "func newFunction() {", oldLineNumber: nil, newLineNumber: 3),
                    DiffLine(type: .added, content: "    print(\"Hello, World!\")", oldLineNumber: nil, newLineNumber: 4),
                    DiffLine(type: .context, content: "}", oldLineNumber: 4, newLineNumber: 5)
                ]
            )
        ],
        statistics: DiffStatistics(additions: 2, deletions: 1)
    )
    
    @State var expandedHunks: Set<Int> = [0]
    
    return ScrollView {
        UnifiedDiffView(
            diffContent: sampleDiff,
            showLineNumbers: true,
            expandedHunks: $expandedHunks
        )
    }
    .frame(width: 800, height: 400)
}