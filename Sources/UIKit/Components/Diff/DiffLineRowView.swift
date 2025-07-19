//
// DiffLineRowView.swift
// GitCthulhu
//
// Created by GitCthulhu Team on 2025-07-18.
//

import GitCore
import SwiftUI

struct DiffLineRowView: View {
    let line: GitDiffLine
    let language: String
    let showWhitespace: Bool
    let showLineNumbers: Bool
    let showSyntaxHighlighting: Bool

    var body: some View {
        DiffLineView(
            line: line,
            language: language,
            showWhitespace: showWhitespace,
            showLineNumbers: showLineNumbers,
            showSyntaxHighlighting: showSyntaxHighlighting
        )
    }
}
