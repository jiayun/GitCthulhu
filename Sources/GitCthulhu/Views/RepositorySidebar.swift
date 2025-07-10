import GitCore
import SwiftUI

struct RepositorySidebar: View {
    @EnvironmentObject private var repositoryManager: RepositoryManager

    var body: some View {
        List {
            // Current Repository Section
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

            // Recent Repositories Section
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

            // Actions Section
            Section("Actions") {
                Button(action: {
                    Task {
                        await repositoryManager.openRepositoryWithFileBrowser()
                    }
                }) {
                    Label("Open Repository", systemImage: "folder.badge.plus")
                }
                .disabled(repositoryManager.isLoading)

                Button(action: {
                    // Clone repository functionality will be implemented in future sprint
                }) {
                    Label("Clone Repository", systemImage: "square.and.arrow.down")
                }
                .disabled(repositoryManager.isLoading)

                if !repositoryManager.recentRepositories.isEmpty {
                    Button(action: {
                        repositoryManager.clearRecentRepositories()
                    }) {
                        Label("Clear Recent", systemImage: "trash")
                    }
                    .foregroundColor(.red)
                }
            }
        }
        .navigationTitle("GitCthulhu")
        .frame(minWidth: 200)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: {
                    Task {
                        await repositoryManager.openRepositoryWithFileBrowser()
                    }
                }) {
                    Image(systemName: "plus")
                }
                .disabled(repositoryManager.isLoading)
            }
        }
    }
}

struct SidebarRepositoryRow: View {
    let url: URL
    @EnvironmentObject private var repositoryManager: RepositoryManager
    @State private var repositoryInfo: (name: String, path: String, branch: String?)?

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
