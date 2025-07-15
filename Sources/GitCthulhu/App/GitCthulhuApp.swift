//
// GitCthulhuApp.swift
// GitCthulhu
//
// Created by GitCthulhu Team on 2025-07-11.
//

import AppKit
import GitCore
import SwiftUI

@main
struct GitCthulhuApp: App {
    @StateObject private var dependencyContainer = DependencyContainer.shared

    init() {
        // Force the app to appear as a regular macOS application
        NSApplication.shared.setActivationPolicy(.regular)
        NSApplication.shared.activate(ignoringOtherApps: true)
    }

    var body: some Scene {
        WindowGroup("GitCthulhu") {
            ContentView()
                .environment(\.dependencyContainer, dependencyContainer)
        }
        .commands {
            CommandGroup(replacing: .appInfo) {
                Button("About GitCthulhu") {
                    NSApplication.shared.orderFrontStandardAboutPanel(
                        options: [
                            .applicationName: "GitCthulhu",
                            .applicationVersion: "1.0.0"
                        ]
                    )
                }
            }

            CommandGroup(replacing: .newItem) {
                Button("Open Repository...") {
                    dependencyContainer.appViewModel.openRepository()
                }
                .keyboardShortcut("o", modifiers: .command)
            }

            CommandGroup(after: .newItem) {
                Button("Clone Repository...") {
                    dependencyContainer.appViewModel.cloneRepository()
                }
                .keyboardShortcut("c", modifiers: [.command, .shift])
            }
        }
    }
}
