//
// SideBySideDiffHeaderView.swift
// GitCthulhu
//
// Created by GitCthulhu Team on 2025-07-18.
//

import GitCore
import SwiftUI

struct SideBySideDiffHeaderView: View {
    let diff: GitDiff

    var body: some View {
        VStack(spacing: 0) {
            fileHeader
            columnHeaders
        }
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
            leftColumnHeader

            // Divider
            Rectangle()
                .frame(width: 1)
                .foregroundColor(Color(NSColor.separatorColor))

            rightColumnHeader
        }
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color(NSColor.separatorColor)),
            alignment: .bottom
        )
    }

    private var leftColumnHeader: some View {
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
    }

    private var rightColumnHeader: some View {
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
