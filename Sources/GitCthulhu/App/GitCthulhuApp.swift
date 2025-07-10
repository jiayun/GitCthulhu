import SwiftUI
import AppKit

@main
struct GitCthulhuApp: App {
    init() {
        // Force the app to appear as a regular macOS application
        NSApplication.shared.setActivationPolicy(.regular)
        NSApplication.shared.activate(ignoringOtherApps: true)
    }
    
    var body: some Scene {
        WindowGroup("GitCthulhu") {
            ContentView()
        }
        .windowStyle(.automatic)
        .windowToolbarStyle(.automatic)
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
        }
    }
}