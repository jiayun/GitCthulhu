//
// FileStatusListUtilityViews.swift
// GitCthulhu
//
// Created by GitCthulhu Team on 2025-07-18.
//

import GitCore
import SwiftUI

extension FileStatusListView {
    var refreshButton: some View {
        Button(action: {
            Task {
                await repository.refreshStatus()
                await stagingViewModel.refreshStagingStatus()
            }
        }) { Image(systemName: "arrow.clockwise") }.help("Refresh file status")
    }

    func errorBanner(message: String) -> some View {
        banner(message: message, color: .red, icon: "exclamationmark.triangle.fill") { stagingViewModel.clearError() }
    }

    func successBanner(message: String) -> some View {
        banner(message: message, color: .green, icon: "checkmark.circle.fill") { stagingViewModel.clearLastResult() }
    }

    func banner(message: String, color: Color, icon: String, onDismiss: @escaping () -> Void) -> some View {
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
