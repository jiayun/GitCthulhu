//
// DiffLineContentView.swift
// GitCthulhu
//
// Created by GitCthulhu Team on 2025-07-18.
//

import GitCore
import SwiftUI

struct DiffLineContentView: View {
    let line: GitDiffLine
    let language: String
    let showWhitespace: Bool
    let showSyntaxHighlighting: Bool

    @State private var highlighter = SyntaxHighlighter()

    var body: some View {
        Group {
            if showSyntaxHighlighting, line.type.isContentLine, language != "text" {
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
            line.content
                .replacingOccurrences(of: " ", with: "·")
                .replacingOccurrences(of: "\t", with: "→")
        } else {
            line.content
        }
    }

    private var highlightedContent: AttributedString {
        let content = displayContent
        return highlighter.highlight(content, language: language)
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
