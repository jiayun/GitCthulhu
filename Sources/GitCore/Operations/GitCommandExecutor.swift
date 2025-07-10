import Foundation
import Utilities

public class GitCommandExecutor {
    private let repositoryURL: URL
    private let logger = Logger(category: "GitCommandExecutor")

    public init(repositoryURL: URL) {
        self.repositoryURL = repositoryURL
    }

    @discardableResult
    public func execute(_ arguments: [String]) async throws -> String {
        return try await withCheckedThrowingContinuation { continuation in
            let process = Process()
            let pipe = Pipe()
            let errorPipe = Pipe()

            process.executableURL = URL(fileURLWithPath: "/usr/bin/git")
            process.arguments = arguments
            process.currentDirectoryURL = repositoryURL
            process.standardOutput = pipe
            process.standardError = errorPipe

            logger.debug("Executing git command: git \(arguments.joined(separator: " "))")

            do {
                try process.run()

                process.terminationHandler = { process in
                    let data = pipe.fileHandleForReading.readDataToEndOfFile()
                    let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()

                    let output = String(data: data, encoding: .utf8) ?? ""
                    let errorOutput = String(data: errorData, encoding: .utf8) ?? ""

                    if process.terminationStatus == 0 {
                        self.logger.debug("Git command succeeded: \(output.trimmingCharacters(in: .whitespacesAndNewlines))")
                        continuation.resume(returning: output.trimmingCharacters(in: .whitespacesAndNewlines))
                    } else {
                        let fullError = errorOutput.isEmpty ? output : errorOutput
                        let error = GitError.libgit2Error("Git command failed with status \(process.terminationStatus): \(fullError)")
                        self.logger.error("Git command failed: \(error.localizedDescription)")
                        continuation.resume(throwing: error)
                    }
                }
            } catch {
                logger.error("Failed to start git process: \(error.localizedDescription)")
                continuation.resume(throwing: GitError.libgit2Error("Failed to execute git command: \(error.localizedDescription)"))
            }
        }
    }

    // MARK: - Repository Info

    public func isValidRepository() async -> Bool {
        do {
            _ = try await execute(["rev-parse", "--git-dir"])
            return true
        } catch {
            return false
        }
    }

    public func getRepositoryRoot() async throws -> String {
        return try await execute(["rev-parse", "--show-toplevel"])
    }

    // MARK: - Branch Operations

    public func getCurrentBranch() async throws -> String? {
        do {
            let output = try await execute(["rev-parse", "--abbrev-ref", "HEAD"])
            return output.isEmpty ? nil : output
        } catch {
            // Might be in detached HEAD state or no commits yet
            return nil
        }
    }

    public func getBranches() async throws -> [String] {
        do {
            let output = try await execute(["branch", "--format=%(refname:short)"])
            return output.components(separatedBy: .newlines)
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
        } catch {
            logger.warning("Could not get branches: \(error.localizedDescription)")
            return []
        }
    }

    public func getRemoteBranches() async throws -> [String] {
        do {
            let output = try await execute(["branch", "-r", "--format=%(refname:short)"])
            return output.components(separatedBy: .newlines)
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
        } catch {
            logger.warning("Could not get remote branches: \(error.localizedDescription)")
            return []
        }
    }

    public func createBranch(_ name: String, from baseBranch: String? = nil) async throws {
        var args = ["checkout", "-b", name]
        if let base = baseBranch {
            args.append(base)
        }
        try await execute(args)
    }

    public func switchBranch(_ name: String) async throws {
        try await execute(["checkout", name])
    }

    public func deleteBranch(_ name: String, force: Bool = false) async throws {
        let flag = force ? "-D" : "-d"
        try await execute(["branch", flag, name])
    }

    // MARK: - Status Operations

    public func getRepositoryStatus() async throws -> [String: String] {
        do {
            let output = try await execute(["status", "--porcelain"])
            var status: [String: String] = [:]

            output.components(separatedBy: .newlines).forEach { line in
                guard line.count >= 3 else { return }
                let statusCode = String(line.prefix(2))
                let fileName = String(line.dropFirst(3))
                status[fileName] = statusCode
            }

            return status
        } catch {
            logger.warning("Could not get repository status: \(error.localizedDescription)")
            return [:]
        }
    }

    public func getFileStatus(_ filePath: String) async throws -> String? {
        do {
            let output = try await execute(["status", "--porcelain", filePath])
            guard !output.isEmpty, output.count >= 2 else { return nil }
            return String(output.prefix(2))
        } catch {
            return nil
        }
    }

    // MARK: - Staging Operations

    public func stageFile(_ filePath: String) async throws {
        try await execute(["add", filePath])
    }

    public func stageAllFiles() async throws {
        try await execute(["add", "."])
    }

    public func unstageFile(_ filePath: String) async throws {
        try await execute(["reset", "HEAD", filePath])
    }

    public func unstageAllFiles() async throws {
        try await execute(["reset", "HEAD"])
    }

    // MARK: - Commit Operations

    public func commit(message: String, author: String? = nil) async throws -> String {
        var args = ["commit", "-m", message]
        if let author = author {
            args.append(contentsOf: ["--author", author])
        }
        return try await execute(args)
    }

    public func amendCommit(message: String? = nil) async throws -> String {
        var args = ["commit", "--amend"]
        if let message = message {
            args.append(contentsOf: ["-m", message])
        } else {
            args.append("--no-edit")
        }
        return try await execute(args)
    }

    public func getCommitHistory(limit: Int = 100, branch: String? = nil) async throws -> [String] {
        var args = ["log", "--oneline", "--max-count=\(limit)"]
        if let branch = branch {
            args.append(branch)
        }

        let output = try await execute(args)
        return output.components(separatedBy: .newlines)
            .filter { !$0.isEmpty }
    }

    // MARK: - Diff Operations

    public func getDiff(filePath: String? = nil, staged: Bool = false) async throws -> String {
        var args = ["diff"]
        if staged {
            args.append("--cached")
        }
        if let filePath = filePath {
            args.append(filePath)
        }

        return try await execute(args)
    }

    // MARK: - Remote Operations

    public func getRemotes() async throws -> [String: String] {
        let output = try await execute(["remote", "-v"])
        var remotes: [String: String] = [:]

        output.components(separatedBy: .newlines).forEach { line in
            let components = line.components(separatedBy: .whitespaces)
            guard components.count >= 2 else { return }
            let name = components[0]
            let url = components[1]
            if !remotes.keys.contains(name) {
                remotes[name] = url
            }
        }

        return remotes
    }

    public func fetch(remote: String = "origin") async throws {
        try await execute(["fetch", remote])
    }

    public func pull(remote: String = "origin", branch: String? = nil) async throws {
        var args = ["pull", remote]
        if let branch = branch {
            args.append(branch)
        }
        try await execute(args)
    }

    public func push(remote: String = "origin", branch: String? = nil, setUpstream: Bool = false) async throws {
        var args = ["push"]
        if setUpstream {
            args.append("-u")
        }
        args.append(remote)
        if let branch = branch {
            args.append(branch)
        }
        try await execute(args)
    }
}
