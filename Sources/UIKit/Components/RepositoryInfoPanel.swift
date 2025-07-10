import SwiftUI
import GitCore

public struct RepositoryInfoPanel: View {
    let repository: GitRepository
    @State private var repositoryInfo: (name: String, path: String, branch: String?)?
    @State private var isLoading = true
    
    public init(repository: GitRepository) {
        self.repository = repository
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Repository Header
            HStack {
                Image(systemName: "folder.fill")
                    .font(.title2)
                    .foregroundColor(.blue)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(repository.name)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text(repository.url.path)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }
            
            Divider()
            
            // Repository Information
            VStack(alignment: .leading, spacing: 12) {
                InfoRow(
                    title: "Current Branch",
                    value: repository.currentBranch?.shortName ?? "Unknown",
                    icon: "arrow.triangle.branch"
                )
                
                InfoRow(
                    title: "Total Branches",
                    value: "\(repository.branches.count)",
                    icon: "arrow.triangle.merge"
                )
                
                InfoRow(
                    title: "Modified Files",
                    value: "\(repository.status.count)",
                    icon: "doc.text"
                )
                
                InfoRow(
                    title: "Repository Path",
                    value: repository.url.path,
                    icon: "folder",
                    allowsCopy: true
                )
            }
            
            Spacer()
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
        .onAppear {
            loadRepositoryInfo()
        }
    }
    
    private func loadRepositoryInfo() {
        isLoading = true
        
        Task {
            // Simulate loading delay for better UX
            try? await Task.sleep(nanoseconds: 500_000_000)
            
            await MainActor.run {
                repositoryInfo = (
                    name: repository.name,
                    path: repository.url.path,
                    branch: repository.currentBranch?.shortName
                )
                isLoading = false
            }
        }
    }
}

struct InfoRow: View {
    let title: String
    let value: String
    let icon: String
    let allowsCopy: Bool
    
    init(title: String, value: String, icon: String, allowsCopy: Bool = false) {
        self.title = title
        self.value = value
        self.icon = icon
        self.allowsCopy = allowsCopy
    }
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(value)
                    .font(.subheadline)
                    .foregroundColor(.primary)
            }
            
            Spacer()
            
            if allowsCopy {
                Button(action: {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(value, forType: .string)
                }) {
                    Image(systemName: "doc.on.doc")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .help("Copy to clipboard")
            }
        }
    }
}

#Preview {
    // This won't work in preview since we can't create a real GitRepository
    // but shows the structure
    VStack {
        Text("Repository Info Panel Preview")
            .font(.title)
        
        // Mock info panel structure
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "folder.fill")
                    .font(.title2)
                    .foregroundColor(.blue)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Example Repository")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("/Users/example/repo")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            Divider()
            
            VStack(alignment: .leading, spacing: 12) {
                InfoRow(title: "Current Branch", value: "main", icon: "arrow.triangle.branch")
                InfoRow(title: "Total Branches", value: "3", icon: "arrow.triangle.merge")
                InfoRow(title: "Modified Files", value: "2", icon: "doc.text")
                InfoRow(title: "Repository Path", value: "/Users/example/repo", icon: "folder", allowsCopy: true)
            }
            
            Spacer()
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
    }
    .padding()
    .frame(width: 400, height: 300)
}