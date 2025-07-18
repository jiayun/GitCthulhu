//
// RepositoryInfoService.swift
// GitCthulhu
//
// Created by GitCthulhu Team on 2025-07-14.
//

import Foundation

public class RepositoryInfoService {
    public init() {}

    public func getRepositoryInfo(for repository: GitRepository) async throws -> RepositoryInfo {
        let executor = GitCommandExecutor(repositoryURL: repository.url)

        async let branch = try? await executor.getCurrentBranch()
        async let latestCommit = try? await executor.getLatestCommit()
        async let remoteInfo = try? await executor.getRemoteInfo()
        async let commitCount = try? await executor.getCommitCount()

        // Use GitRepository's status summary instead of creating new executor
        async let statusSummary = try? await repository.getStatusSummary()
        let workingDirectoryStatus = await statusSummary.map { summary in
            GitCommandExecutor.DetailedFileStatus(
                staged: summary.stagedCount,
                unstaged: summary.unstagedCount,
                untracked: summary.untrackedCount
            )
        }

        let branchResult = await branch
        let latestCommitResult = await latestCommit
        let remoteInfoResult = await remoteInfo ?? []
        let commitCountResult = await commitCount ?? 0
        let workingDirectoryStatusResult = workingDirectoryStatus ?? GitCommandExecutor.DetailedFileStatus(
            staged: 0,
            unstaged: 0,
            untracked: 0
        )

        return RepositoryInfo(
            name: repository.url.lastPathComponent,
            path: repository.url.path,
            branch: branchResult,
            latestCommit: latestCommitResult,
            remoteInfo: remoteInfoResult,
            commitCount: commitCountResult,
            workingDirectoryStatus: workingDirectoryStatusResult
        )
    }

    public func validateRepositoryPath(_ url: URL) -> Bool {
        let gitDir = url.appendingPathComponent(".git")
        return FileManager.default.fileExists(atPath: gitDir.path)
    }
}
