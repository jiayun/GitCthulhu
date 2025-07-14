//
// ContentView.swift
// GitCthulhu
//
// Created by GitCthulhu Team on 2025-07-11.
//

import GitCore
import SwiftUI
import UIKit

struct ContentView: View {
    @Environment(\.dependencyContainer)
    private var container
    @StateObject private var contentViewModel: ContentViewModel
    @StateObject private var sidebarViewModel: RepositorySidebarViewModel
    @StateObject private var detailViewModel: RepositoryDetailViewModel

    init() {
        let container = DependencyContainer.shared
        _contentViewModel = StateObject(wrappedValue: container.makeContentViewModel())
        _sidebarViewModel = StateObject(wrappedValue: container.makeRepositorySidebarViewModel())
        _detailViewModel = StateObject(wrappedValue: container.makeRepositoryDetailViewModel())
    }

    var body: some View {
        VStack {
            if #available(macOS 13.0, *) {
                NavigationSplitView {
                    RepositorySidebar()
                        .environmentObject(sidebarViewModel)
                        .frame(minWidth: 200)
                } detail: {
                    if !contentViewModel.isShowingWelcomeView {
                        RepositoryDetailView()
                            .environmentObject(detailViewModel)
                    } else {
                        WelcomeView()
                            .environmentObject(container.appViewModel)
                    }
                }
            } else {
                // Fallback for macOS 12
                HStack {
                    RepositorySidebar()
                        .environmentObject(sidebarViewModel)
                        .frame(minWidth: 200, maxWidth: 300)

                    Divider()

                    if !contentViewModel.isShowingWelcomeView {
                        RepositoryDetailView()
                            .environmentObject(detailViewModel)
                    } else {
                        WelcomeView()
                            .environmentObject(container.appViewModel)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    ContentView()
}
