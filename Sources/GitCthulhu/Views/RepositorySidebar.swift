//
// RepositorySidebar.swift
// GitCthulhu
//
// Created by GitCthulhu Team on 2025-07-11.
//

import GitCore
import SwiftUI

struct RepositorySidebar: View {
    @EnvironmentObject private var viewModel: RepositorySidebarViewModel

    var body: some View {
        List {
            currentRepositorySection
            repositoriesSection
            actionsSection
        }
        .navigationTitle("GitCthulhu")
        .frame(minWidth: 200)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: openRepositoryAction) {
                    Image(systemName: "plus")
                }
                .disabled(viewModel.isLoading)
            }
        }
    }

    // MARK: - View Components

    private var currentRepositorySection: some View {
        Group {
            if let selectedRepository = viewModel.repositories
                .first(where: { $0.id == viewModel.selectedRepositoryId }) {
                Section("Current Repository") {
                    CurrentRepositoryRow(repository: selectedRepository)
                }
            }
        }
    }

    private var repositoriesSection: some View {
        Section("Repositories") {
            if viewModel.repositories.isEmpty {
                Text("No repositories")
                    .foregroundColor(.secondary)
                    .font(.subheadline)
            } else {
                ForEach(viewModel.repositories) { repository in
                    SidebarRepositoryRow(repository: repository)
                }
            }
        }
    }

    private var actionsSection: some View {
        Section("Actions") {
            Button(action: openRepositoryAction) {
                Label("Open Repository", systemImage: "folder.badge.plus")
            }
            .disabled(viewModel.isLoading)

            Button(action: cloneRepositoryAction) {
                Label("Clone Repository", systemImage: "square.and.arrow.down")
            }
            .disabled(viewModel.isLoading)
        }
    }

    // MARK: - Actions

    private func openRepositoryAction() {
        viewModel.openRepository()
    }

    private func cloneRepositoryAction() {
        viewModel.cloneRepository()
    }
}

struct SidebarRepositoryRow: View {
    @ObservedObject var repository: GitRepository
    @EnvironmentObject private var viewModel: RepositorySidebarViewModel

    var body: some View {
        Button(action: {
            viewModel.selectRepository(repository)
        }) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(repository.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)

                    if let branch = repository.currentBranch {
                        HStack {
                            Image(systemName: "arrow.triangle.branch")
                                .font(.caption)
                                .foregroundColor(.blue)
                            Text(branch.shortName)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                Spacer()

                // Show indicator if this is the selected repository
                if viewModel.isSelected(repository) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.caption)
                }
            }
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button("Remove Repository") {
                viewModel.removeRepository(repository)
            }

            Button("Show in Finder") {
                NSWorkspace.shared.open(repository.url)
            }
        }
    }
}

struct CurrentRepositoryRow: View {
    @ObservedObject var repository: GitRepository

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(repository.name)
                .font(.headline)
                .foregroundColor(.primary)

            if let branch = repository.currentBranch {
                HStack {
                    Image(systemName: "arrow.triangle.branch")
                        .foregroundColor(.blue)
                    Text(branch.shortName)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }

            Text(repository.url.path)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(2)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    let appViewModel = AppViewModel()
    return RepositorySidebar()
        .environmentObject(RepositorySidebarViewModel(appViewModel: appViewModel))
}
