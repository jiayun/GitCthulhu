//
// FileStatusListMessageView.swift
// GitCthulhu
//
// Created by GitCthulhu Team on 2025-07-18.
//

import GitCore
import SwiftUI

struct FileStatusListMessageView: View {
    @ObservedObject var stagingViewModel: StagingViewModel

    var body: some View {
        VStack(spacing: 0) {
            // Error message display
            if let errorMessage = stagingViewModel.errorMessage {
                errorBanner(message: errorMessage)
            }

            // Success message display
            if let successMessage = stagingViewModel.lastOperationSuccessMessage {
                successBanner(message: successMessage)
            }
        }
    }

    private func errorBanner(message: String) -> some View {
        banner(message: message, color: .red, icon: "exclamationmark.triangle.fill") { stagingViewModel.clearError() }
    }

    private func successBanner(message: String) -> some View {
        banner(message: message, color: .green, icon: "checkmark.circle.fill") { stagingViewModel.clearLastResult() }
    }

    private func banner(message: String, color: Color, icon: String, onDismiss: @escaping () -> Void) -> some View {
        HStack {
            Image(systemName: icon).foregroundColor(color)
            Text(message).font(.caption).foregroundColor(color)
            Spacer()
            Button("Dismiss", action: onDismiss).font(.caption).foregroundColor(color)
        }
        .padding(.horizontal, 16).padding(.vertical, 8)
        .background(color.opacity(0.1)).cornerRadius(6)
        .padding(.horizontal, 16).padding(.bottom, 8)
    }
}
