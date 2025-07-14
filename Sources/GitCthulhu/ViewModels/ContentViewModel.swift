//
// ContentViewModel.swift
// GitCthulhu
//
// Created by GitCthulhu Team on 2025-07-14.
//

import Combine
import Foundation

@MainActor
final class ContentViewModel: ViewModelBase {
    @Published var sidebarWidth: CGFloat = 250
    @Published var isShowingWelcomeView = true

    private let appViewModel: AppViewModel

    init(appViewModel: AppViewModel) {
        self.appViewModel = appViewModel
        super.init()
        setupBindings()
    }

    private func setupBindings() {
        appViewModel.$selectedRepositoryId
            .map { $0 == nil }
            .assign(to: &$isShowingWelcomeView)
    }

    func adjustSidebarWidth(_ width: CGFloat) {
        let minWidth: CGFloat = 200
        let maxWidth: CGFloat = 400
        sidebarWidth = max(minWidth, min(maxWidth, width))
    }
}
