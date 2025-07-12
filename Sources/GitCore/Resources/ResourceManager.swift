//
// ResourceManager.swift
// GitCthulhu
//
// Created by GitCthulhu Team on 2025-07-12.
//

import Foundation
import SwiftGit2
import Utilities

/// Manages repository resources and ensures proper cleanup
/// This class provides automatic resource management for Git repositories
public actor ResourceManager {
    private var openRepositories: [URL: WeakRepository] = [:]
    private let logger = Logger(category: "ResourceManager")
    private var cleanupTimer: Timer?

    /// Wrapper for weak repository references
    private class WeakRepository {
        weak var repository: LibGit2Repository?
        let openedAt: Date

        init(repository: LibGit2Repository) {
            self.repository = repository
            self.openedAt = Date()
        }
    }

    public init() {
        startCleanupTimer()
    }

    deinit {
        cleanupTimer?.invalidate()
    }

    // MARK: - Repository Management

    /// Opens a repository with automatic resource management
    public func openRepository(at url: URL) async throws -> LibGit2Repository {
        // Check if repository is already open
        if let weakRepo = openRepositories[url],
           let repository = weakRepo.repository {
            logger.debug("Returning existing repository for \(url.path)")
            return repository
        }

        // Open new repository
        logger.info("Opening new repository at \(url.path)")
        let repository = try LibGit2Repository(url: url)
        openRepositories[url] = WeakRepository(repository: repository)

        return repository
    }

    /// Closes a repository and releases its resources
    public func closeRepository(at url: URL) async {
        guard let weakRepo = openRepositories[url],
              let repository = weakRepo.repository else {
            logger.debug("Repository at \(url.path) not found or already closed")
            return
        }

        logger.info("Closing repository at \(url.path)")
        await repository.close()
        openRepositories.removeValue(forKey: url)
    }

    /// Closes all open repositories
    public func closeAllRepositories() async {
        logger.info("Closing all \(openRepositories.count) open repositories")

        for (url, weakRepo) in openRepositories {
            if let repository = weakRepo.repository {
                await repository.close()
            }
        }

        openRepositories.removeAll()
    }

    /// Gets the count of currently open repositories
    public func openRepositoryCount() -> Int {
        // Clean up any deallocated repositories
        openRepositories = openRepositories.filter { _, weakRepo in
            weakRepo.repository != nil
        }
        return openRepositories.count
    }

    // MARK: - Cleanup

    private func startCleanupTimer() {
        // Run cleanup every 5 minutes
        let timer = Timer(timeInterval: 300, repeats: true) { [weak self] _ in
            Task {
                await self?.performCleanup()
            }
        }

        RunLoop.main.add(timer, forMode: .common)
        cleanupTimer = timer
    }

    private func performCleanup() async {
        logger.debug("Performing resource cleanup")

        var closedCount = 0
        let cutoffTime = Date().addingTimeInterval(-3600) // 1 hour ago

        // Remove deallocated repositories and close old ones
        for (url, weakRepo) in openRepositories {
            if weakRepo.repository == nil {
                // Repository was deallocated
                openRepositories.removeValue(forKey: url)
                closedCount += 1
            } else if weakRepo.openedAt < cutoffTime {
                // Repository is older than 1 hour
                if let repository = weakRepo.repository {
                    await repository.close()
                    openRepositories.removeValue(forKey: url)
                    closedCount += 1
                    logger.info("Closed idle repository at \(url.path)")
                }
            }
        }

        if closedCount > 0 {
            logger.info("Cleanup completed: closed \(closedCount) repositories")
        }
    }

    // MARK: - Memory Management

    /// Reports current memory usage for diagnostics
    public func memoryReport() -> MemoryReport {
        let activeRepos = openRepositories.compactMap { _, weakRepo in
            weakRepo.repository
        }

        return MemoryReport(
            openRepositoryCount: activeRepos.count,
            totalRepositories: openRepositories.count,
            oldestRepository: openRepositories.values
                .compactMap { $0.openedAt }
                .min()
        )
    }
}

/// Memory usage report
public struct MemoryReport {
    public let openRepositoryCount: Int
    public let totalRepositories: Int
    public let oldestRepository: Date?

    public var description: String {
        var desc = "Open repositories: \(openRepositoryCount)/\(totalRepositories)"
        if let oldest = oldestRepository {
            let formatter = DateComponentsFormatter()
            formatter.allowedUnits = [.hour, .minute]
            formatter.unitsStyle = .abbreviated
            if let age = formatter.string(from: oldest, to: Date()) {
                desc += ", Oldest: \(age) ago"
            }
        }
        return desc
    }
}

// MARK: - Global Instance

/// Shared resource manager instance
public let sharedResourceManager = ResourceManager()
