//
// RepositoryInfoPanel.swift
// GitCthulhu
//
// Created by GitCthulhu Team on 2025-07-11.
//

import GitCore
import SwiftUI

public struct RepositoryInfoPanel: View {
    let repository: GitRepository
    @State private var repositoryInfo: RepositoryInfo?
    @State private var isLoading = true

    public init(repository: GitRepository) {
        self.repository = repository
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            repositoryHeader
            Divider()
            repositoryInformation
            Spacer()
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
        .onAppear {
            loadRepositoryInfo()
        }
    }

    // MARK: - View Components

    private var repositoryHeader: some View {
        HStack {
            Image(systemName: "folder.fill")
                .font(.title2)
                .foregroundColor(.blue)

            VStack(alignment: .leading, spacing: 4) {
                Text(repository.name)
                    .font(.title2)
                    .fontWeight(.bold)

                Text(repository.url.path)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            if isLoading {
                ProgressView()
                    .scaleEffect(0.8)
            }
        }
    }

    private var repositoryInformation: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let info = repositoryInfo {
                repositoryInfoView(info)
            } else {
                fallbackRepositoryView
            }
        }
    }

    @ViewBuilder
    private func repositoryInfoView(_ info: RepositoryInfo) -> some View {
        // Current Branch
        InfoRow(
            title: "Current Branch",
            value: info.branch ?? "Unknown",
            icon: "arrow.triangle.branch"
        )

        // Latest Commit Information
        if let latestCommit = info.latestCommit {
            latestCommitView(latestCommit)
        }

        // Commit Count
        InfoRow(
            title: "Total Commits",
            value: "\(info.commitCount)",
            icon: "number.circle"
        )

        // Remote Information
        if !info.remoteInfo.isEmpty {
            remoteInfoView(info.remoteInfo)
        }

        // Working Directory Status
        workingDirectoryView(info.workingDirectoryStatus)

        // Repository Path
        InfoRow(
            title: "Repository Path",
            value: info.path,
            icon: "folder",
            allowsCopy: true
        )
    }

    @ViewBuilder
    private func latestCommitView(_ commit: GitCommandExecutor.CommitInfo) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "clock.arrow.circlepath")
                    .foregroundColor(.blue)
                    .frame(width: 20)
                Text("Latest Commit")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(commit.message)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                    .lineLimit(2)

                HStack {
                    Text("by \(commit.author)")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Spacer()

                    Text(formatDate(commit.timestamp))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.leading, 28)
        }
    }

    @ViewBuilder
    private func remoteInfoView(_ remotes: [GitCommandExecutor.RemoteInfo]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "network")
                    .foregroundColor(.blue)
                    .frame(width: 20)
                Text("Remote")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            ForEach(remotes.prefix(2), id: \.name) { remote in
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(remote.name)
                            .font(.subheadline)
                            .foregroundColor(.primary)
                        Text(remote.url)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }

                    Spacer()

                    if remote.isUpToDate {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.caption)
                    } else {
                        Image(systemName: "arrow.up.circle")
                            .foregroundColor(.orange)
                            .font(.caption)
                    }
                }
                .padding(.leading, 28)
            }
        }
    }

    @ViewBuilder
    private func workingDirectoryView(_ status: GitCommandExecutor.DetailedFileStatus) -> some View {
        if status.total > 0 {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "doc.text")
                        .foregroundColor(.blue)
                        .frame(width: 20)
                    Text("Working Directory")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                VStack(alignment: .leading, spacing: 4) {
                    if status.staged > 0 {
                        HStack {
                            Circle()
                                .fill(Color.green)
                                .frame(width: 8, height: 8)
                            Text("\(status.staged) staged")
                                .font(.caption)
                                .foregroundColor(.primary)
                        }
                    }

                    if status.unstaged > 0 {
                        HStack {
                            Circle()
                                .fill(Color.orange)
                                .frame(width: 8, height: 8)
                            Text("\(status.unstaged) modified")
                                .font(.caption)
                                .foregroundColor(.primary)
                        }
                    }

                    if status.untracked > 0 {
                        HStack {
                            Circle()
                                .fill(Color.gray)
                                .frame(width: 8, height: 8)
                            Text("\(status.untracked) untracked")
                                .font(.caption)
                                .foregroundColor(.primary)
                        }
                    }
                }
                .padding(.leading, 28)
            }
        } else {
            InfoRow(
                title: "Working Directory",
                value: "Clean",
                icon: "checkmark.circle"
            )
        }
    }

    private var fallbackRepositoryView: some View {
        Group {
            InfoRow(
                title: "Current Branch",
                value: repository.currentBranch?.shortName ?? "Unknown",
                icon: "arrow.triangle.branch"
            )

            InfoRow(
                title: "Repository Path",
                value: repository.url.path,
                icon: "folder",
                allowsCopy: true
            )
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }

    private func loadRepositoryInfo() {
        isLoading = true

        Task {
            let manager = RepositoryManager()
            let info = await manager.getRepositoryInfo(at: repository.url)

            await MainActor.run {
                repositoryInfo = info
                isLoading = false
            }
        }
    }
}

struct InfoRow: View {
    let title: String
    let value: String
    let icon: String
    let allowsCopy: Bool

    init(title: String, value: String, icon: String, allowsCopy: Bool = false) {
        self.title = title
        self.value = value
        self.icon = icon
        self.allowsCopy = allowsCopy
    }

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text(value)
                    .font(.subheadline)
                    .foregroundColor(.primary)
            }

            Spacer()

            if allowsCopy {
                Button(action: {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(value, forType: .string)
                }) {
                    Image(systemName: "doc.on.doc")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .help("Copy to clipboard")
            }
        }
    }
}

#Preview {
    VStack {
        Text("Repository Info Panel Preview")
            .font(.title)

        Text("This component requires a GitRepository instance")
            .font(.caption)
            .foregroundColor(.secondary)
    }
    .frame(width: 400, height: 300)
}
