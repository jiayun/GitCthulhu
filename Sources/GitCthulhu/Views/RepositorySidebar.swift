//
// RepositorySidebar.swift
// GitCthulhu
//
// Created by GitCthulhu Team on 2025-07-11.
//

import GitCore
import SwiftUI

struct RepositorySidebar: View {
    @EnvironmentObject private var repositoryManager: RepositoryManager

    var body: some View {
        List {
            currentRepositorySection
            recentRepositoriesSection
            actionsSection
        }
        .navigationTitle("GitCthulhu")
        .frame(minWidth: 200)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: openRepositoryAction) {
                    Image(systemName: "plus")
                }
                .disabled(repositoryManager.isLoading)
            }
        }
    }

    // MARK: - View Components

    private var currentRepositorySection: some View {
        if let currentRepo = repositoryManager.currentRepository {
            Section("Current Repository") {
                VStack(alignment: .leading, spacing: 4) {
                    Text(currentRepo.name)
                        .font(.headline)
                        .foregroundColor(.primary)

                    if let branch = currentRepo.currentBranch {
                        HStack {
                            Image(systemName: "arrow.triangle.branch")
                                .foregroundColor(.blue)
                            Text(branch.shortName)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }

                    Text(currentRepo.url.path)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                .padding(.vertical, 4)
            }
        }
    }

    private var recentRepositoriesSection: some View {
        Section("Recent Repositories") {
            if repositoryManager.recentRepositories.isEmpty {
                Text("No recent repositories")
                    .foregroundColor(.secondary)
                    .font(.subheadline)
            } else {
                ForEach(repositoryManager.recentRepositories, id: \.self) { url in
                    SidebarRepositoryRow(url: url)
                }
            }
        }
    }

    private var actionsSection: some View {
        Section("Actions") {
            Button(action: openRepositoryAction) {
                Label("Open Repository", systemImage: "folder.badge.plus")
            }
            .disabled(repositoryManager.isLoading)

            Button(action: cloneRepositoryAction) {
                Label("Clone Repository", systemImage: "square.and.arrow.down")
            }
            .disabled(repositoryManager.isLoading)

            if !repositoryManager.recentRepositories.isEmpty {
                Button(action: clearRecentAction) {
                    Label("Clear Recent", systemImage: "trash")
                }
                .foregroundColor(.red)
            }
        }
    }

    // MARK: - Actions

    private func openRepositoryAction() {
        Task {
            await repositoryManager.openRepositoryWithFileBrowser()
        }
    }

    private func cloneRepositoryAction() {
        // Clone repository functionality will be implemented in future sprint
    }

    private func clearRecentAction() {
        repositoryManager.clearRecentRepositories()
    }
}

struct SidebarRepositoryRow: View {
    let url: URL
    @EnvironmentObject private var repositoryManager: RepositoryManager
    @State private var repositoryInfo: RepositoryInfo?

    var body: some View {
        Button(action: {
            Task {
                await repositoryManager.openRepository(at: url)
            }
        }) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(repositoryInfo?.name ?? url.lastPathComponent)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)

                    if let branch = repositoryInfo?.branch {
                        HStack {
                            Image(systemName: "arrow.triangle.branch")
                                .font(.caption)
                                .foregroundColor(.blue)
                            Text(branch)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                Spacer()

                // Show indicator if this is the current repository
                if repositoryManager.currentRepository?.url == url {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.caption)
                }
            }
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button("Remove from Recent") {
                repositoryManager.removeFromRecentRepositories(url)
            }

            Button("Show in Finder") {
                NSWorkspace.shared.open(url)
            }
        }
        .onAppear {
            Task {
                repositoryInfo = await repositoryManager.getRepositoryInfo(at: url)
            }
        }
    }
}

#Preview {
    RepositorySidebar()
        .environmentObject(RepositoryManager())
}
