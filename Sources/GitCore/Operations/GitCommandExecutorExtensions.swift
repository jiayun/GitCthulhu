//
// GitCommandExecutorExtensions.swift
// GitCthulhu
//
// Created by GitCthulhu Team on 2025-07-12.
//

import Foundation

// MARK: - Data Structures

public extension GitCommandExecutor {
    struct CommitInfo {
        public let hash: String
        public let author: String
        public let message: String
        public let timestamp: Date

        public init(hash: String, author: String, message: String, timestamp: Date) {
            self.hash = hash
            self.author = author
            self.message = message
            self.timestamp = timestamp
        }
    }

    struct RemoteInfo {
        public let name: String
        public let url: String
        public let isUpToDate: Bool

        public init(name: String, url: String, isUpToDate: Bool = false) {
            self.name = name
            self.url = url
            self.isUpToDate = isUpToDate
        }
    }

    struct DetailedFileStatus {
        public let staged: Int
        public let unstaged: Int
        public let untracked: Int
        public let total: Int

        public init(staged: Int, unstaged: Int, untracked: Int) {
            self.staged = staged
            self.unstaged = unstaged
            self.untracked = untracked
            total = staged + unstaged + untracked
        }
    }
}

// MARK: - Repository Information

public extension GitCommandExecutor {
    func getLatestCommit() async throws -> CommitInfo? {
        do {
            let output = try await execute(["log", "-1", "--pretty=format:%H|%an|%s|%ct"])
            guard !output.isEmpty else { return nil }

            let components = output.components(separatedBy: "|")
            guard components.count >= 4 else { return nil }

            let hash = components[0]
            let author = components[1]
            let message = components[2]
            let timestampString = components[3]

            guard let timestamp = Double(timestampString) else { return nil }
            let date = Date(timeIntervalSince1970: timestamp)

            return CommitInfo(hash: hash, author: author, message: message, timestamp: date)
        } catch {
            logger.warning("Could not get latest commit: \(error.localizedDescription)")
            return nil
        }
    }

    func getCommitCount() async throws -> Int {
        do {
            let output = try await execute(["rev-list", "--count", "HEAD"])
            return Int(output) ?? 0
        } catch {
            logger.warning("Could not get commit count: \(error.localizedDescription)")
            return 0
        }
    }

    func getRemoteInfo() async throws -> [RemoteInfo] {
        do {
            let remotes = try await getRemotes()
            var remoteInfos: [RemoteInfo] = []

            for (name, url) in remotes {
                let isUpToDate = await checkRemoteUpToDate(name)
                remoteInfos.append(RemoteInfo(name: name, url: url, isUpToDate: isUpToDate))
            }

            return remoteInfos
        } catch {
            logger.warning("Could not get remote info: \(error.localizedDescription)")
            return []
        }
    }

    private func checkRemoteUpToDate(_ remoteName: String) async -> Bool {
        do {
            _ = try await execute(["fetch", remoteName, "--dry-run"])
            let localHash = try await execute(["rev-parse", "HEAD"])
            let remoteHash = try await execute(["rev-parse", "\(remoteName)/HEAD"])
            return localHash == remoteHash
        } catch {
            return false
        }
    }

    func getDetailedStatus() async throws -> DetailedFileStatus {
        do {
            let output = try await execute(["status", "--porcelain"])
            var staged = 0
            var unstaged = 0
            var untracked = 0

            for line in output.components(separatedBy: .newlines) {
                guard line.count >= 2 else { continue }
                let statusCode = String(line.prefix(2))

                if statusCode.hasPrefix("??") {
                    untracked += 1
                } else {
                    if statusCode.first != " ", statusCode.first != "?" {
                        staged += 1
                    }
                    if statusCode.last != " ", statusCode.last != "?" {
                        unstaged += 1
                    }
                }
            }

            return DetailedFileStatus(staged: staged, unstaged: unstaged, untracked: untracked)
        } catch {
            logger.warning("Could not get detailed status: \(error.localizedDescription)")
            return DetailedFileStatus(staged: 0, unstaged: 0, untracked: 0)
        }
    }
}
