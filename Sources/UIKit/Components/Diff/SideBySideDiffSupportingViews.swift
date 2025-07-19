//
// SideBySideDiffSupportingViews.swift
// GitCthulhu
//
// Created by GitCthulhu Team on 2025-07-18.
//

import GitCore
import SwiftUI

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
