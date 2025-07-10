import Foundation

public class GitRepository: ObservableObject, Identifiable {
    public let id = UUID()
    public let url: URL
    public let name: String
    
    @Published public var status: [String: GitFileStatus] = [:]
    @Published public var branches: [GitBranch] = []
    @Published public var currentBranch: GitBranch?
    
    public init(url: URL) throws {
        self.url = url
        self.name = url.lastPathComponent
        
        // Validate that this is a git repository
        let gitDir = url.appendingPathComponent(".git")
        guard FileManager.default.fileExists(atPath: gitDir.path) else {
            throw GitError.failedToOpenRepository("No .git directory found at \(url.path)")
        }
        
        // Load initial data
        Task { @MainActor in
            await loadRepositoryData()
        }
    }
    
    @MainActor
    private func loadRepositoryData() async {
        // TODO: Load current branch using git commands
        // TODO: Load status using git commands  
        // TODO: Load branches using git commands
        // This will be implemented with proper git integration in subsequent sprints
    }
}