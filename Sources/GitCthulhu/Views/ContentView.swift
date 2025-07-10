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
    @EnvironmentObject private var repositoryManager: RepositoryManager

    var body: some View {
        VStack {
            if #available(macOS 13.0, *) {
                NavigationSplitView {
                    RepositorySidebar()
                        .frame(minWidth: 200)
                } detail: {
                    if repositoryManager.currentRepository != nil {
                        RepositoryDetailView()
                    } else {
                        WelcomeView()
                    }
                }
            } else {
                // Fallback for macOS 12
                HStack {
                    RepositorySidebar()
                        .frame(minWidth: 200, maxWidth: 300)

                    Divider()

                    if repositoryManager.currentRepository != nil {
                        RepositoryDetailView()
                    } else {
                        WelcomeView()
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    ContentView()
        .environmentObject(RepositoryManager())
}
