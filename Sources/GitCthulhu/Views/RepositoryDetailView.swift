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
    @EnvironmentObject private var viewModel: RepositoryDetailViewModel

    var body: some View {
        if let selectedRepository = viewModel.selectedRepository {
            VStack(alignment: .leading, spacing: 20) {
                // Repository Information Panel
                if let repositoryInfo = viewModel.repositoryInfo {
                    RepositoryInfoPanel(repository: selectedRepository, repositoryInfo: repositoryInfo)
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else if viewModel.isInfoLoading {
                    ProgressView("Loading repository information...")
                        .frame(maxWidth: .infinity, alignment: .center)
                } else {
                    Text("Failed to load repository information")
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity, alignment: .center)
                }

                Divider()

                // File Status List
                FileStatusListView(repository: selectedRepository)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Refresh") {
                        Task {
                            await viewModel.refreshRepositoryInfo()
                        }
                    }
                }
            }
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
