import GitCore
import SwiftUI

struct WelcomeView: View {
    @EnvironmentObject private var repositoryManager: RepositoryManager
    @State private var isDragOver = false
    @State private var showingError = false
    @State private var errorMessage = ""

    var body: some View {
        VStack(spacing: 30) {
            Spacer()

            headerSection

            Spacer()

            actionButtonsSection

            // Recent Repositories Section
            if !repositoryManager.recentRepositories.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Recent Repositories")
                        .font(.headline)
                        .foregroundColor(.primary)

                    ScrollView {
                        VStack(spacing: 8) {
                            ForEach(repositoryManager.recentRepositories, id: \.self) { url in
                                RecentRepositoryRow(url: url)
                            }
                        }
                    }
                    .frame(maxHeight: 120)
                }
                .padding(.horizontal, 40)
            }

            Spacer()

            // Status Text
            VStack(spacing: 8) {
                if repositoryManager.isLoading {
                    HStack {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Opening repository...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                } else {
                    Text("Ready to explore your Git repositories")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text("Drag and drop a Git repository folder here")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.bottom, 20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(NSColor.windowBackgroundColor))
        .overlay(
            // Drag and drop overlay
            Rectangle()
                .fill(isDragOver ? Color.blue.opacity(0.1) : Color.clear)
                .border(isDragOver ? Color.blue : Color.clear, width: 2)
                .animation(.easeInOut(duration: 0.2), value: isDragOver)
        )
        .onDrop(of: ["public.file-url"], isTargeted: $isDragOver) { providers in
            handleDrop(providers: providers)
        }
        .alert("Error Opening Repository", isPresented: $showingError) {
            Button("OK") {}
        } message: {
            Text(errorMessage)
        }
        .onChange(of: repositoryManager.error) { newError in
            if let error = newError {
                errorMessage = error.localizedDescription
                showingError = true
            }
        }
    }

    // MARK: - View Components

    private var headerSection: some View {
        VStack(spacing: 20) {
            Image(systemName: "terminal")
                .font(.system(size: 80))
                .foregroundColor(.blue)

            Text("GitCthulhu")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("A Modern Git Client for macOS")
                .font(.title2)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    private var actionButtonsSection: some View {
        VStack(spacing: 16) {
            Button("Open Repository") {
                Task {
                    await repositoryManager.openRepositoryWithFileBrowser()
                }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .frame(width: 200)
            .disabled(repositoryManager.isLoading)

            Button("Clone Repository") {
                print("Clone Repository tapped")
                // TODO: Implement repository cloning
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
            .frame(width: 200)
        }
    }

    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first else { return false }

        provider.loadObject(ofClass: NSURL.self) { url, _ in
            guard let url = url as? URL else { return }

            Task { @MainActor in
                if repositoryManager.validateRepositoryPath(url) {
                    await repositoryManager.openRepository(at: url)
                } else {
                    errorMessage = "Selected folder is not a Git repository"
                    showingError = true
                }
            }
        }

        return true
    }
}

struct RecentRepositoryRow: View {
    let url: URL
    @EnvironmentObject private var repositoryManager: RepositoryManager
    @State private var repositoryInfo: (name: String, path: String, branch: String?)?

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(repositoryInfo?.name ?? url.lastPathComponent)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)

                HStack {
                    Text(url.path)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)

                    if let branch = repositoryInfo?.branch {
                        Text("• \(branch)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }

            Spacer()

            Button(action: {
                Task {
                    await repositoryManager.openRepository(at: url)
                }
            }) {
                Image(systemName: "arrow.right.circle")
                    .foregroundColor(.blue)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
        .onAppear {
            Task {
                repositoryInfo = await repositoryManager.getRepositoryInfo(at: url)
            }
        }
    }
}

#Preview {
    WelcomeView()
        .frame(width: 600, height: 400)
        .environmentObject(RepositoryManager())
}
