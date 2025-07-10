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
    @StateObject private var repositoryManager = RepositoryManager()

    init() {
        // Force the app to appear as a regular macOS application
        NSApplication.shared.setActivationPolicy(.regular)
        NSApplication.shared.activate(ignoringOtherApps: true)

        // Prevent multiple windows
        if NSApp.windows.count > 1 {
            NSApp.windows.dropFirst().forEach { $0.close() }
        }
    }

    var body: some Scene {
        WindowGroup("GitCthulhu") {
            ContentView()
                .environmentObject(repositoryManager)
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
                    Task {
                        await repositoryManager.openRepositoryWithFileBrowser()
                    }
                }
                .keyboardShortcut("o", modifiers: .command)
            }

            CommandGroup(after: .newItem) {
                Button("Close Repository") {
                    repositoryManager.closeRepository()
                }
                .keyboardShortcut("w", modifiers: [.command, .shift])
                .disabled(repositoryManager.currentRepository == nil)
            }
        }
    }
}
