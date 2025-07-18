//
// IntegratedRepositoryFileStatusTab.swift
// GitCthulhu
//
// Created by GitCthulhu Team on 2025-07-18.
//

import GitCore
import SwiftUI

struct IntegratedRepositoryFileStatusTab: View {
    @ObservedObject var statusManager: GitStatusViewModel
    @Binding var repository: GitRepository?
    @Binding var selectedFileForDiff: String?

    var body: some View {
        VStack(spacing: 0) {
            header
            fileList
        }
        .frame(minWidth: 300, idealWidth: 400)
    }

    private var header: some View {
        HStack {
            Text("Changed Files")
                .font(.headline)
                .fontWeight(.medium)

            Spacer()

            // Status summary
            if !statusManager.statusEntries.isEmpty {
                Text("\(statusManager.statusEntries.count) files changed")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color(NSColor.controlBackgroundColor))
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color(NSColor.separatorColor)),
            alignment: .bottom
        )
    }

    @ViewBuilder
    private var fileList: some View {
        if let repository {
            FileStatusListView(
                repository: repository,
                onViewDiff: { filePath in
                    selectedFileForDiff = filePath
                },
                onStagingChanged: {
                    Task {
                        await repository.refreshStatus()
                    }
                }
            )
            .id(repository.id) // Force refresh when repository changes
        } else {
            Text("Loading repository...")
                .foregroundColor(.secondary)
        }
    }
}
