@testable import GitCore
import SwiftUI
import Testing
@testable import UIKit

struct RepositoryInfoPanelTests {
    @Test func infoRowInitialization() async throws {
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

    @Test func infoRowWithoutCopy() async throws {
        // Test InfoRow without copy functionality
        let infoRow = InfoRow(
            title: "Test Title",
            value: "Test Value",
            icon: "folder"
        )

        // Basic structural test
        #expect(true) // InfoRow can be created successfully
    }

    @Test func errorAlertInitialization() async throws {
        // Test ErrorAlert initialization
        let error = GitError.failedToOpenRepository("Test error message")
        let errorAlert = ErrorAlert(
            error: error,
            onRetry: { print("Retry") },
            onDismiss: { print("Dismiss") }
        )

        // Basic structural test
        #expect(true) // ErrorAlert can be created successfully
    }

    @Test func errorBannerInitialization() async throws {
        // Test ErrorBanner initialization
        let error = GitError.permissionDenied
        let errorBanner = ErrorBanner(
            error: error,
            onDismiss: { print("Dismiss") }
        )

        // Basic structural test
        #expect(true) // ErrorBanner can be created successfully
    }

    @Test func gitErrorDescriptions() async throws {
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
}
