import SwiftUI
import GitCore
import UIKit

struct ContentView: View {
    @StateObject private var repositoryManager = RepositoryManager()
    
    var body: some View {
        if #available(macOS 13.0, *) {
            NavigationSplitView {
                RepositorySidebar()
            } detail: {
                if repositoryManager.currentRepository != nil {
                    RepositoryDetailView()
                } else {
                    WelcomeView()
                }
            }
            .environmentObject(repositoryManager)
        } else {
            // Fallback for macOS 12
            NavigationView {
                RepositorySidebar()
                
                if repositoryManager.currentRepository != nil {
                    RepositoryDetailView()
                } else {
                    WelcomeView()
                }
            }
            .environmentObject(repositoryManager)
        }
    }
}

#Preview {
    ContentView()
}