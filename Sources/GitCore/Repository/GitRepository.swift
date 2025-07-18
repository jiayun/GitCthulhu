//
// GitRepository.swift
// GitCthulhu
//
// Created by GitCthulhu Team on 2025-07-11.
//

import Combine
import Foundation
import Utilities

/// CLI-based implementation of GitRepositoryProtocol
/// This implementation uses the git command-line interface
@MainActor
public class GitRepository: ObservableObject, GitRepositoryProtocol, Identifiable {
    public let id = UUID()
    public let url: URL
    public let name: String

    private let gitExecutor: GitCommandExecutor
    private let statusManager: GitStatusManager
    private let logger = Logger(category: "GitRepository")

    // File system monitoring
    private let fileSystemMonitor: FileSystemMonitor
    private var fileSystemSubscription: AnyCancellable?

    @Published public var status: [String: GitFileStatus] = [:]
    @Published public var statusEntries: [GitStatusEntry] = []
    @Published public var statusSummary = GitStatusSummary(
        stagedCount: 0,
        unstagedCount: 0,
        untrackedCount: 0,
        conflictedCount: 0,
        isClean: true
    )
    @Published public var branches: [GitBranch] = []
    @Published public var currentBranch: GitBranch?
    @Published public var isLoading = false

    // Performance optimization: debouncing mechanism
    private var refreshTask: Task<Void, Never>?
    private var lastRefreshTime: Date = .distantPast
    private let refreshDebounceInterval: TimeInterval = 0.5

    public init(url: URL) throws {
        self.url = url
        name = url.lastPathComponent
        gitExecutor = GitCommandExecutor(repositoryURL: url)
        statusManager = GitStatusManager(repositoryURL: url)
        fileSystemMonitor = FileSystemMonitor(repositoryPath: url)

        // Validate that this is a git repository
        let gitDir = url.appendingPathComponent(".git")
        guard FileManager.default.fileExists(atPath: gitDir.path) else {
            throw GitError.failedToOpenRepository("No .git directory found at \(url.path)")
        }

        // Note: Initial data loading should be done explicitly after initialization
        // to avoid race conditions
    }

    /// Testing initializer that skips validation
    public init(url: URL, skipValidation _: Bool) {
        self.url = url
        name = url.lastPathComponent
        gitExecutor = GitCommandExecutor(repositoryURL: url)
        statusManager = GitStatusManager(repositoryURL: url)
        fileSystemMonitor = FileSystemMonitor(repositoryPath: url)

        // Skip validation for testing
    }

    /// Factory method to create and initialize a GitRepository
    @MainActor
    public static func create(url: URL) async throws -> GitRepository {
        let repository = try GitRepository(url: url)
        await repository.loadRepositoryData()
        await repository.startFileSystemMonitoring()
        return repository
    }

    @MainActor
    private func loadRepositoryData() async {
        isLoading = true

        // Verify this is a valid Git repository first
        guard await gitExecutor.isValidRepository() else {
            logger.error("Invalid Git repository at \(url.path)")
            isLoading = false
            return
        }

        await loadCurrentBranch()
        await loadBranches()
        await loadStatus()

        isLoading = false
    }

    @MainActor
    private func loadCurrentBranch() async {
        do {
            if let branchName = try await gitExecutor.getCurrentBranch() {
                currentBranch = GitBranch(
                    name: branchName,
                    shortName: branchName,
                    isCurrent: true
                )
                logger.info("Current branch: \(branchName)")
            }
        } catch {
            logger.warning("Could not load current branch: \(error.localizedDescription)")
        }
    }

    @MainActor
    private func loadBranches() async {
        do {
            // Load local branches
            let localBranchNames = try await gitExecutor.getBranches()
            let localBranches = localBranchNames.map { branchName in
                let isCurrent = branchName == currentBranch?.shortName
                return GitBranch(
                    name: branchName,
                    shortName: branchName,
                    isRemote: false,
                    isCurrent: isCurrent
                )
            }

            // Load remote branches
            let remoteBranchNames = try await gitExecutor.getRemoteBranches()
            let remoteBranches = remoteBranchNames.map { branchName in
                GitBranch(
                    name: branchName,
                    shortName: branchName.components(separatedBy: "/").last ?? branchName,
                    isRemote: true,
                    isCurrent: false
                )
            }

            branches = localBranches + remoteBranches
            logger.info("Loaded \(localBranches.count) local and \(remoteBranches.count) remote branches")
        } catch {
            logger.warning("Could not load branches: \(error.localizedDescription)")
        }
    }

    @MainActor
    private func loadStatus() async {
        do {
            // Load detailed status entries
            let entries = try await statusManager.getDetailedStatus()
            statusEntries = entries

            // Load status summary
            let summary = try await statusManager.getStatusSummary()
            statusSummary = summary

            // Keep backward compatibility with existing status format
            let statusMap = try await gitExecutor.getRepositoryStatus()
            var convertedStatus: [String: GitFileStatus] = [:]

            for (fileName, statusCode) in statusMap {
                let gitStatus = convertGitStatus(statusCode)
                convertedStatus[fileName] = gitStatus
            }

            status = convertedStatus
            logger.info("Loaded status for \(status.count) files, \(entries.count) detailed entries")
        } catch {
            logger.warning("Could not load repository status: \(error.localizedDescription)")
        }
    }

    private func convertGitStatus(_ statusCode: String) -> GitFileStatus {
        switch statusCode.prefix(2) {
        case "??": .untracked
        case "A ", " A": .added
        case "M ", " M", "MM": .modified
        case "D ", " D": .deleted
        case "R ", " R": .renamed
        case "C ", " C": .copied
        case "UU", "AA", "DD": .unmerged
        default: .modified
        }
    }

    // MARK: - GitRepositoryProtocol Implementation

    public func isValidRepository() async -> Bool {
        await gitExecutor.isValidRepository()
    }

    public func getRepositoryRoot() async throws -> String {
        try await gitExecutor.getRepositoryRoot()
    }

    public func getCurrentBranch() async throws -> String? {
        try await gitExecutor.getCurrentBranch()
    }

    public func getBranches() async throws -> [String] {
        try await gitExecutor.getBranches()
    }

    public func getRemoteBranches() async throws -> [String] {
        try await gitExecutor.getRemoteBranches()
    }

    public func deleteBranch(_ name: String, force: Bool) async throws {
        try await gitExecutor.deleteBranch(name, force: force)
        await loadBranches()
    }

    public func getRepositoryStatus() async throws -> [String: GitFileStatus] {
        let statusMap = try await gitExecutor.getRepositoryStatus()
        var convertedStatus: [String: GitFileStatus] = [:]

        for (fileName, statusCode) in statusMap {
            let gitStatus = convertGitStatus(statusCode)
            convertedStatus[fileName] = gitStatus
        }

        return convertedStatus
    }

    public func refreshStatus() async {
        // Force cache invalidation before loading new status
        statusManager.invalidateCache()
        await loadStatus()
    }

    /// Gets detailed status entries
    public func getDetailedStatusEntries() async throws -> [GitStatusEntry] {
        try await statusManager.getDetailedStatus()
    }

    /// Gets status summary
    public func getStatusSummary() async throws -> GitStatusSummary {
        try await statusManager.getStatusSummary()
    }

    /// Gets staged files
    public func getStagedFiles() async throws -> [GitStatusEntry] {
        try await statusManager.getStagedFiles()
    }

    /// Gets unstaged files
    public func getUnstagedFiles() async throws -> [GitStatusEntry] {
        try await statusManager.getUnstagedFiles()
    }

    /// Gets untracked files
    public func getUntrackedFiles() async throws -> [GitStatusEntry] {
        try await statusManager.getUntrackedFiles()
    }

    /// Gets conflicted files
    public func getConflictedFiles() async throws -> [GitStatusEntry] {
        try await statusManager.getConflictedFiles()
    }

    /// Checks if repository is clean
    public func isRepositoryClean() async throws -> Bool {
        try await statusManager.isRepositoryClean()
    }

    public func stageFile(_ filePath: String) async throws {
        try await gitExecutor.stageFile(filePath)
        statusManager.invalidateCache()
        await refreshStatus()
    }

    public func stageAllFiles() async throws {
        try await gitExecutor.stageAllFiles()
        statusManager.invalidateCache()
        await refreshStatus()
    }

    public func unstageFile(_ filePath: String) async throws {
        try await gitExecutor.unstageFile(filePath)
        statusManager.invalidateCache()
        await refreshStatus()
    }

    public func unstageAllFiles() async throws {
        try await gitExecutor.unstageAllFiles()
        statusManager.invalidateCache()
        await refreshStatus()
    }

    public func commit(message: String, author: String? = nil) async throws -> String {
        let result = try await gitExecutor.commit(message: message, author: author)
        statusManager.invalidateCache()
        await loadRepositoryData()
        return result
    }

    public func amendCommit(message: String?) async throws -> String {
        let result = try await gitExecutor.amendCommit(message: message)
        statusManager.invalidateCache()
        await loadRepositoryData()
        return result
    }

    public func getCommitHistory(limit: Int, branch: String?) async throws -> [String] {
        try await gitExecutor.getCommitHistory(limit: limit, branch: branch)
    }

    public func getDiff(filePath: String?, staged: Bool) async throws -> String {
        try await gitExecutor.getDiff(filePath: filePath, staged: staged)
    }

    public func getRemotes() async throws -> [String: String] {
        try await gitExecutor.getRemotes()
    }

    public func fetch(remote: String) async throws {
        try await gitExecutor.fetch(remote: remote)
    }

    public func pull(remote: String, branch: String?) async throws {
        try await gitExecutor.pull(remote: remote, branch: branch)
        await loadRepositoryData()
    }

    public func push(remote: String, branch: String?, setUpstream: Bool) async throws {
        try await gitExecutor.push(remote: remote, branch: branch, setUpstream: setUpstream)
    }

    public func switchBranch(_ branchName: String) async throws {
        try await gitExecutor.switchBranch(branchName)
        await loadRepositoryData()
    }

    public func createBranch(_ name: String, from baseBranch: String? = nil) async throws {
        try await gitExecutor.createBranch(name, from: baseBranch)
        await loadBranches()
    }

    /// Debounced refresh to prevent excessive UI updates
    @MainActor
    public func refreshWithDebounce() {
        let now = Date()
        guard now.timeIntervalSince(lastRefreshTime) >= refreshDebounceInterval else {
            return
        }

        refreshTask?.cancel()
        refreshTask = Task {
            try? await Task.sleep(nanoseconds: UInt64(refreshDebounceInterval * 1_000_000_000))
            guard !Task.isCancelled else { return }

            lastRefreshTime = Date()
            await loadRepositoryData()
        }
    }

    // MARK: - File System Monitoring

    @MainActor
    private func startFileSystemMonitoring() async {
        await setupFileSystemEventSubscription()
        fileSystemMonitor.startMonitoring()
        logger.info("File system monitoring started for repository: \(name)")
    }

    @MainActor
    private func setupFileSystemEventSubscription() async {
        fileSystemSubscription = fileSystemMonitor.eventPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] events in
                Task { @MainActor in
                    await self?.handleFileSystemEvents(events)
                }
            }
    }

    @MainActor
    private func handleFileSystemEvents(_ events: [FileSystemEvent]) async {
        guard !events.isEmpty else { return }

        logger.info("Received \(events.count) file system events for repository: \(name)")

        // Check if any events affect Git status
        let shouldRefresh = events.contains { event in
            shouldRefreshForEvent(event)
        }

        if shouldRefresh {
            logger.info("File system changes detected, refreshing repository status")
            refreshWithDebounce()
        }
    }

    @MainActor
    public func stopFileSystemMonitoring() {
        fileSystemSubscription?.cancel()
        fileSystemSubscription = nil
        fileSystemMonitor.stopMonitoring()
        logger.info("File system monitoring stopped for repository: \(name)")
    }

    deinit {
        refreshTask?.cancel()
        fileSystemSubscription?.cancel()
    }

    public func close() async {
        refreshTask?.cancel()
        stopFileSystemMonitoring()
        logger.info("Repository closed")
    }

    // MARK: - Private Helpers

    /// Determines if a file system event should trigger a repository refresh
    private func shouldRefreshForEvent(_ event: FileSystemEvent) -> Bool {
        let eventURL = URL(fileURLWithPath: event.path)

        // Ensure event is within our repository using URL-based comparison
        guard eventURL.path.hasPrefix(url.path) else { return false }

        // Calculate relative path using URL relationship
        guard let relativePath = getRelativePath(from: url, to: eventURL) else { return false }

        logger.info("Evaluating event for refresh: \(relativePath)")

        // Always refresh for working directory changes (not in .git)
        if !relativePath.hasPrefix(".git/") {
            logger.info("  -> Working directory change, will refresh")
            return true
        }

        // For .git directory changes, only monitor specific important files
        // that affect repository state, branches, or staging
        let gitRefreshPaths = [
            ".git/HEAD", // Current branch pointer
            ".git/index", // Staging area
            ".git/refs/heads/", // Local branches
            ".git/refs/remotes/", // Remote branches
            ".git/refs/tags/", // Tags
            ".git/MERGE_HEAD", // Merge state
            ".git/CHERRY_PICK_HEAD", // Cherry-pick state
            ".git/REBASE_HEAD" // Rebase state
        ]

        let shouldRefresh = gitRefreshPaths.contains { gitPath in
            if gitPath.hasSuffix("/") {
                relativePath.hasPrefix(gitPath)
            } else {
                relativePath == gitPath
            }
        }

        logger.info("  -> Git file \(relativePath): \(shouldRefresh ? "will refresh" : "ignoring")")
        return shouldRefresh
    }

    /// Safely calculates relative path between URLs
    private func getRelativePath(from baseURL: URL, to targetURL: URL) -> String? {
        // Normalize paths to handle symbolic links and resolve components
        let basePath = baseURL.standardized.path
        let targetPath = targetURL.standardized.path

        // Ensure target is within base
        guard targetPath.hasPrefix(basePath) else { return nil }

        // Remove base path and leading slash
        let relativePath = String(targetPath.dropFirst(basePath.count))
        return relativePath.hasPrefix("/") ? String(relativePath.dropFirst()) : relativePath
    }
}
