//
// RepositoryDetailView.swift
// GitCthulhu
//
// Created by GitCthulhu Team on 2025-07-11.
//

import GitCore
import SwiftUI
import UIKit

struct RepositoryDetailView: View {
    @EnvironmentObject private var repositoryManager: RepositoryManager

    var body: some View {
        if let currentRepository = repositoryManager.currentRepository {
            VStack(alignment: .leading, spacing: 20) {
                // Repository Information Panel
                RepositoryInfoPanel(repository: currentRepository)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Divider()

                // Future features will be added here
                VStack {
                    Text("More repository features coming soon...")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Text("• File status and staging")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("• Commit history")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("• Branch management")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        } else {
            // This should not happen as ContentView handles this case
            EmptyState(
                title: "No Repository Selected",
                subtitle: "Select a repository from the sidebar",
                systemImage: "folder.badge.questionmark"
            )
        }
    }
}

#Preview {
    RepositoryDetailView()
}
