//
// ErrorAlert.swift
// GitCthulhu
//
// Created by GitCthulhu Team on 2025-07-11.
//

import GitCore
import SwiftUI
import Utilities

public struct ErrorAlert: View {
    let error: GitError
    let onRetry: (() -> Void)?
    let onDismiss: () -> Void

    public init(error: GitError, onRetry: (() -> Void)? = nil, onDismiss: @escaping () -> Void) {
        self.error = error
        self.onRetry = onRetry
        self.onDismiss = onDismiss
    }

    public var body: some View {
        VStack(spacing: 16) {
            // Error Icon
            Image(systemName: errorIcon)
                .font(.system(size: 48))
                .foregroundColor(.red)

            // Error Title
            Text(errorTitle)
                .font(.title2)
                .fontWeight(.semibold)

            // Error Description
            Text(error.localizedDescription)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            // Action Buttons
            HStack(spacing: 12) {
                Button("Dismiss") {
                    onDismiss()
                }
                .buttonStyle(.bordered)

                if let onRetry {
                    Button("Retry") {
                        onRetry()
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
        .padding()
        .background(Color(NSColor.windowBackgroundColor))
        .cornerRadius(12)
        .shadow(radius: 8)
    }

    private var errorIcon: String {
        switch error {
        case .failedToOpenRepository:
            "folder.badge.questionmark"
        case .failedToInitializeRepository:
            "plus.square.dashed"
        case .invalidRepositoryPath:
            "exclamationmark.triangle"
        case .libgit2Error:
            "terminal"
        case .fileNotFound:
            "doc.badge.exclamationmark"
        case .permissionDenied:
            "lock.shield"
        case .networkError:
            "wifi.exclamationmark"
        case .unknown:
            "questionmark.circle"
        }
    }

    private var errorTitle: String {
        switch error {
        case .failedToOpenRepository:
            "Failed to Open Repository"
        case .failedToInitializeRepository:
            "Failed to Initialize Repository"
        case .invalidRepositoryPath:
            "Invalid Repository Path"
        case .libgit2Error:
            "Git Operation Failed"
        case .fileNotFound:
            "File Not Found"
        case .permissionDenied:
            "Permission Denied"
        case .networkError:
            "Network Error"
        case .unknown:
            "Unknown Error"
        }
    }
}

public struct ErrorBanner: View {
    let error: GitError
    let onDismiss: () -> Void

    public init(error: GitError, onDismiss: @escaping () -> Void) {
        self.error = error
        self.onDismiss = onDismiss
    }

    public var body: some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.red)

            VStack(alignment: .leading, spacing: 2) {
                Text("Error")
                    .font(.headline)
                    .foregroundColor(.primary)

                Text(error.localizedDescription)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Button(action: onDismiss) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding()
        .background(Color.red.opacity(0.1))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.red.opacity(0.3), lineWidth: 1)
        )
    }
}

#Preview("Error Alert") {
    ErrorAlert(
        error: .failedToOpenRepository("The selected folder is not a valid Git repository."),
        onRetry: { Logger(category: "ErrorAlert").info("Retry action") },
        onDismiss: { Logger(category: "ErrorAlert").info("Dismiss action") }
    )
    .frame(width: 400, height: 300)
}

#Preview("Error Banner") {
    ErrorBanner(
        error: .permissionDenied,
        onDismiss: { Logger(category: "ErrorAlert").info("Dismiss action") }
    )
    .padding()
}
