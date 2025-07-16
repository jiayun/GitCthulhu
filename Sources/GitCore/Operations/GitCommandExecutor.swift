//
// GitCommandExecutor.swift
// GitCthulhu
//
// Created by GitCthulhu Team on 2025-07-11.
//

import Foundation
import Utilities

public class GitCommandExecutor {
    private let repositoryURL: URL
    let logger = Logger(category: "GitCommandExecutor")

    public init(repositoryURL: URL) {
        self.repositoryURL = repositoryURL
    }

    @discardableResult
    public func execute(_ arguments: [String]) async throws -> String {
        // Validate all arguments before execution
        try GitInputValidator.validateArguments(arguments)

        return try await withCheckedThrowingContinuation { continuation in
            let process = setupProcess(with: arguments)
            let (pipe, errorPipe) = setupPipes(for: process)

            logger.debug("Executing git command: git \(arguments.joined(separator: " "))")

            do {
                try process.run()
                process.terminationHandler = { [weak self] process in
                    self?.handleProcessTermination(
                        process,
                        pipe: pipe,
                        errorPipe: errorPipe,
                        arguments: arguments,
                        continuation: continuation
                    )
                }
            } catch {
                handleProcessStartError(error, continuation: continuation)
            }
        }
    }

    private func setupProcess(with arguments: [String]) -> Process {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/git")
        process.arguments = arguments
        process.currentDirectoryURL = repositoryURL
        return process
    }

    private func setupPipes(for process: Process) -> (Pipe, Pipe) {
        let pipe = Pipe()
        let errorPipe = Pipe()
        process.standardOutput = pipe
        process.standardError = errorPipe
        return (pipe, errorPipe)
    }

    private func handleProcessTermination(
        _ process: Process,
        pipe: Pipe,
        errorPipe: Pipe,
        arguments: [String],
        continuation: CheckedContinuation<String, Error>
    ) {
        let output = readOutput(from: pipe)
        let errorOutput = readOutput(from: errorPipe)

        if process.terminationStatus == 0 {
            handleSuccessfulCommand(output: output, arguments: arguments, continuation: continuation)
        } else {
            handleFailedCommand(
                output: output,
                errorOutput: errorOutput,
                status: process.terminationStatus,
                continuation: continuation
            )
        }
    }

    private func readOutput(from pipe: Pipe) -> String {
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        return String(data: data, encoding: .utf8) ?? ""
    }

    private func handleSuccessfulCommand(
        output: String,
        arguments: [String],
        continuation: CheckedContinuation<String, Error>
    ) {
        let processedOutput = processCommandOutput(output, arguments: arguments)
        logger.debug("Git command succeeded: \(processedOutput)")
        continuation.resume(returning: processedOutput)
    }

    private func processCommandOutput(_ output: String, arguments: [String]) -> String {
        // For porcelain format commands, preserve leading whitespace as it's part of the format
        if arguments.contains("--porcelain") || arguments.contains("--porcelain=v1") {
            // Only remove trailing newline, preserve leading whitespace
            return output.trimmingCharacters(in: .newlines)
        }

        // For other commands, use normal trimming
        return output.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func handleFailedCommand(
        output: String,
        errorOutput: String,
        status: Int32,
        continuation: CheckedContinuation<String, Error>
    ) {
        let fullError = errorOutput.isEmpty ? output : errorOutput
        let error = GitError.libgit2Error("Git command failed with status \(status): \(fullError)")
        logger.error("Git command failed: \(error.localizedDescription)")
        continuation.resume(throwing: error)
    }

    private func handleProcessStartError(_ error: Error, continuation: CheckedContinuation<String, Error>) {
        logger.error("Failed to start git process: \(error.localizedDescription)")
        let gitError = GitError.libgit2Error("Failed to execute git command: \(error.localizedDescription)")
        continuation.resume(throwing: gitError)
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
        try await execute(["rev-parse", "--show-toplevel"])
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
        let sanitizedName = try GitInputValidator.sanitizeBranchName(name)
        var args = ["checkout", "-b", sanitizedName]
        if let base = baseBranch {
            let sanitizedBase = try GitInputValidator.sanitizeBranchName(base)
            args.append(sanitizedBase)
        }
        try await execute(args)
    }

    public func switchBranch(_ name: String) async throws {
        let sanitizedName = try GitInputValidator.sanitizeBranchName(name)
        try await execute(["checkout", sanitizedName])
    }

    public func deleteBranch(_ name: String, force: Bool = false) async throws {
        let sanitizedName = try GitInputValidator.sanitizeBranchName(name)
        let flag = force ? "-D" : "-d"
        try await execute(["branch", flag, sanitizedName])
    }

    // MARK: - Status Operations

    public func getRepositoryStatus() async throws -> [String: String] {
        do {
            let output = try await execute(["status", "--porcelain"])
            var status: [String: String] = [:]

            for line in output.components(separatedBy: .newlines) {
                guard line.count >= 3 else { continue }
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

    /// Gets detailed status entries using the GitStatusManager
    public func getDetailedStatusEntries() async throws -> [GitStatusEntry] {
        let statusManager = GitStatusManager(repositoryURL: repositoryURL)
        return try await statusManager.getDetailedStatus()
    }

    /// Gets status summary using the GitStatusManager
    public func getStatusSummary() async throws -> GitStatusSummary {
        let statusManager = GitStatusManager(repositoryURL: repositoryURL)
        return try await statusManager.getStatusSummary()
    }

    // MARK: - Staging Operations

    public func stageFile(_ filePath: String) async throws {
        let sanitizedPath = try GitInputValidator.sanitizeFilePath(filePath)
        try await execute(["add", sanitizedPath])
    }

    public func stageAllFiles() async throws {
        try await execute(["add", "."])
    }

    public func unstageFile(_ filePath: String) async throws {
        let sanitizedPath = try GitInputValidator.sanitizeFilePath(filePath)
        try await execute(["reset", "HEAD", sanitizedPath])
    }

    public func unstageAllFiles() async throws {
        try await execute(["reset", "HEAD"])
    }

    // MARK: - Commit Operations

    public func commit(message: String, author: String? = nil) async throws -> String {
        let sanitizedMessage = try GitInputValidator.sanitizeCommitMessage(message)
        var args = ["commit", "-m", sanitizedMessage]
        if let author {
            // Basic validation for author string
            if author.contains("\0") || author.isEmpty {
                throw GitError.commitFailed("Invalid author format")
            }
            args.append(contentsOf: ["--author", author])
        }
        return try await execute(args)
    }

    public func amendCommit(message: String? = nil) async throws -> String {
        var args = ["commit", "--amend"]
        if let message {
            let sanitizedMessage = try GitInputValidator.sanitizeCommitMessage(message)
            args.append(contentsOf: ["-m", sanitizedMessage])
        } else {
            args.append("--no-edit")
        }
        return try await execute(args)
    }

    public func getCommitHistory(limit: Int = 100, branch: String? = nil) async throws -> [String] {
        var args = ["log", "--oneline", "--max-count=\(limit)"]
        if let branch {
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
        if let filePath {
            args.append(filePath)
        }

        return try await execute(args)
    }

    // MARK: - Remote Operations

    public func getRemotes() async throws -> [String: String] {
        let output = try await execute(["remote", "-v"])
        var remotes: [String: String] = [:]

        for line in output.components(separatedBy: .newlines) {
            let components = line.components(separatedBy: .whitespaces)
            guard components.count >= 2 else { continue }
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
        if let branch {
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
        if let branch {
            args.append(branch)
        }
        try await execute(args)
    }
}
