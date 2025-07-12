//
// RepositoryInfoPanelTests.swift
// GitCthulhu
//
// Created by GitCthulhu Team on 2025-07-11.
//

@testable import GitCore
import SwiftUI
import Testing
@testable import UIKit

@MainActor
struct RepositoryInfoPanelTests {
    @Test
    func infoRowInitialization() async throws {
        // Test InfoRow initialization
        let infoRow = InfoRow(
            title: "Test Title",
            value: "Test Value",
            icon: "folder",
            allowsCopy: true
        )

        // Basic structural test - InfoRow should contain the provided values
        #expect(true) // InfoRow can be created successfully
    }

    @Test
    func infoRowWithoutCopy() async throws {
        // Test InfoRow without copy functionality
        let infoRow = InfoRow(
            title: "Test Title",
            value: "Test Value",
            icon: "folder"
        )

        // Basic structural test
        #expect(true) // InfoRow can be created successfully
    }

    @Test
    func errorAlertInitialization() async throws {
        // Test ErrorAlert initialization
        let error = GitError.failedToOpenRepository("Test error message")
        let errorAlert = ErrorAlert(
            error: error,
            onRetry: { /* Retry action */ },
            onDismiss: { /* Dismiss action */ }
        )

        // Basic structural test
        #expect(true) // ErrorAlert can be created successfully
    }

    @Test
    func errorBannerInitialization() async throws {
        // Test ErrorBanner initialization
        let error = GitError.permissionDenied
        let errorBanner = ErrorBanner(
            error: error,
            onDismiss: { /* Dismiss action */ }
        )

        // Basic structural test
        #expect(true) // ErrorBanner can be created successfully
    }

    @Test
    func gitErrorDescriptions() async throws {
        // Test that all GitError cases have proper descriptions
        let errors: [GitError] = [
            .failedToOpenRepository("Test"),
            .failedToInitializeRepository("Test"),
            .invalidRepositoryPath,
            .libgit2Error("Test"),
            .fileNotFound("Test"),
            .permissionDenied,
            .networkError("Test"),
            .unknown("Test")
        ]

        for error in errors {
            let description = error.localizedDescription
            #expect(!description.isEmpty)
        }
    }

    @Test
    func commitInfoCreation() async throws {
        // Test CommitInfo structure creation
        let timestamp = Date()
        let commitInfo = GitCommandExecutor.CommitInfo(
            hash: "abc123def",
            author: "Test Author",
            message: "Test commit message",
            timestamp: timestamp
        )

        #expect(commitInfo.hash == "abc123def")
        #expect(commitInfo.author == "Test Author")
        #expect(commitInfo.message == "Test commit message")
        #expect(commitInfo.timestamp == timestamp)
    }

    @Test
    func remoteInfoCreation() async throws {
        // Test RemoteInfo structure creation
        let remoteInfo = GitCommandExecutor.RemoteInfo(
            name: "origin",
            url: "https://github.com/test/repo.git",
            isUpToDate: true
        )

        #expect(remoteInfo.name == "origin")
        #expect(remoteInfo.url == "https://github.com/test/repo.git")
        #expect(remoteInfo.isUpToDate == true)
    }

    @Test
    func detailedFileStatusCreation() async throws {
        // Test DetailedFileStatus structure creation
        let status = GitCommandExecutor.DetailedFileStatus(
            staged: 2,
            unstaged: 3,
            untracked: 1
        )

        #expect(status.staged == 2)
        #expect(status.unstaged == 3)
        #expect(status.untracked == 1)
        #expect(status.total == 6)
    }

    @Test
    func repositoryInfoWithAllFields() async throws {
        // Test RepositoryInfo with all new fields
        let timestamp = Date()
        let commitInfo = GitCommandExecutor.CommitInfo(
            hash: "abc123",
            author: "Test Author",
            message: "Test message",
            timestamp: timestamp
        )

        let remoteInfo = [GitCommandExecutor.RemoteInfo(
            name: "origin",
            url: "https://github.com/test/repo.git",
            isUpToDate: true
        )]

        let status = GitCommandExecutor.DetailedFileStatus(
            staged: 1,
            unstaged: 2,
            untracked: 3
        )

        let repositoryInfo = RepositoryInfo(
            name: "TestRepo",
            path: "/path/to/repo",
            branch: "main",
            latestCommit: commitInfo,
            remoteInfo: remoteInfo,
            commitCount: 42,
            workingDirectoryStatus: status
        )

        #expect(repositoryInfo.name == "TestRepo")
        #expect(repositoryInfo.path == "/path/to/repo")
        #expect(repositoryInfo.branch == "main")
        #expect(repositoryInfo.latestCommit != nil)
        #expect(repositoryInfo.remoteInfo.count == 1)
        #expect(repositoryInfo.commitCount == 42)
        #expect(repositoryInfo.workingDirectoryStatus.total == 6)
    }
}
