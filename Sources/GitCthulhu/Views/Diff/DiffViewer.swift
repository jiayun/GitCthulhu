//
// DiffViewer.swift
// GitCthulhu
//
// Created by GitCthulhu Team on 2025-07-15.
//

import GitCore
import SwiftUI
import UIKit

public enum DiffViewMode {
    case unified
    case sideBySide
}

public struct DiffViewer: View {
    let diffContent: DiffContent
    @State private var viewMode: DiffViewMode = .unified
    @State private var showLineNumbers = true
    @State private var showStatistics = true
    @State private var expandedHunks: Set<Int> = []
    
    public init(diffContent: DiffContent) {
        self.diffContent = diffContent
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // Header with controls
            diffHeader
            
            Divider()
            
            // Statistics (if enabled)
            if showStatistics && !diffContent.statistics.isEmpty {
                diffStatistics
                Divider()
            }
            
            // Main diff content
            ScrollView {
                VStack(spacing: 0) {
                    if diffContent.isBinary {
                        binaryFileView
                    } else {
                        switch viewMode {
                        case .unified:
                            UnifiedDiffView(
                                diffContent: diffContent,
                                showLineNumbers: showLineNumbers,
                                expandedHunks: $expandedHunks
                            )
                        case .sideBySide:
                            SideBySideDiffView(
                                diffContent: diffContent,
                                showLineNumbers: showLineNumbers,
                                expandedHunks: $expandedHunks
                            )
                        }
                    }
                }
            }
            .background(Color(NSColor.textBackgroundColor))
        }
        .onAppear {
            // Initially expand all hunks
            expandedHunks = Set(diffContent.hunks.indices)
        }
    }
    
    // MARK: - Header
    
    private var diffHeader: some View {
        HStack {
            // File path
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: fileIcon)
                        .foregroundColor(fileIconColor)
                    Text(diffContent.filePath)
                        .font(.headline)
                        .foregroundColor(.primary)
                }
                
                if diffContent.isNewFile {
                    Text("New file")
                        .font(.caption)
                        .foregroundColor(.green)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(4)
                } else if diffContent.isDeletedFile {
                    Text("Deleted file")
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(4)
                }
            }
            
            Spacer()
            
            // Controls
            HStack(spacing: 16) {
                // Statistics toggle
                Button(action: {
                    showStatistics.toggle()
                }) {
                    Image(systemName: "chart.bar")
                        .foregroundColor(showStatistics ? .blue : .secondary)
                }
                .buttonStyle(.plain)
                .help("Toggle statistics")
                
                // Line numbers toggle
                Button(action: {
                    showLineNumbers.toggle()
                }) {
                    Image(systemName: "number")
                        .foregroundColor(showLineNumbers ? .blue : .secondary)
                }
                .buttonStyle(.plain)
                .help("Toggle line numbers")
                
                // View mode picker
                Picker("View Mode", selection: $viewMode) {
                    Text("Unified").tag(DiffViewMode.unified)
                    Text("Side by Side").tag(DiffViewMode.sideBySide)
                }
                .pickerStyle(.segmented)
                .frame(width: 150)
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
    }
    
    // MARK: - Statistics
    
    private var diffStatistics: some View {
        HStack {
            // Additions
            if diffContent.statistics.additions > 0 {
                Label("\(diffContent.statistics.additions)", systemImage: "plus")
                    .foregroundColor(.green)
                    .font(.caption)
            }
            
            // Deletions
            if diffContent.statistics.deletions > 0 {
                Label("\(diffContent.statistics.deletions)", systemImage: "minus")
                    .foregroundColor(.red)
                    .font(.caption)
            }
            
            // Total changes
            if diffContent.statistics.totalLines > 0 {
                Text("• \(diffContent.statistics.totalLines) changes")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Expand/Collapse all
            Button(action: toggleAllHunks) {
                Text(expandedHunks.count == diffContent.hunks.count ? "Collapse All" : "Expand All")
                    .font(.caption)
                    .foregroundColor(.blue)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
    }
    
    // MARK: - Binary File View
    
    private var binaryFileView: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.binary")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text("Binary file")
                .font(.title2)
                .foregroundColor(.secondary)
            
            Text("Cannot display binary file contents")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(40)
    }
    
    // MARK: - Helpers
    
    private var fileIcon: String {
        if diffContent.isBinary {
            return "doc.binary"
        } else if diffContent.isNewFile {
            return "doc.badge.plus"
        } else if diffContent.isDeletedFile {
            return "doc.badge.minus"
        } else {
            return "doc.text"
        }
    }
    
    private var fileIconColor: Color {
        if diffContent.isNewFile {
            return .green
        } else if diffContent.isDeletedFile {
            return .red
        } else {
            return .blue
        }
    }
    
    private func toggleAllHunks() {
        if expandedHunks.count == diffContent.hunks.count {
            expandedHunks.removeAll()
        } else {
            expandedHunks = Set(diffContent.hunks.indices)
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
    
    return DiffViewer(diffContent: sampleDiff)
        .frame(width: 800, height: 600)
}