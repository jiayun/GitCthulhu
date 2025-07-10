import Foundation
import Combine

@MainActor
public class RepositoryManager: ObservableObject {
    @Published public var currentRepository: GitRepository?
    @Published public var repositories: [GitRepository] = []
    @Published public var isLoading = false
    @Published public var error: GitError?
    
    public init() {}
    
    public func openRepository(at url: URL) async {
        isLoading = true
        error = nil
        
        do {
            let repository = try GitRepository(url: url)
            currentRepository = repository
            
            // Add to repositories list if not already present
            if !repositories.contains(where: { $0.url == url }) {
                repositories.append(repository)
            }
        } catch {
            self.error = GitError.failedToOpenRepository(error.localizedDescription)
        }
        
        isLoading = false
    }
    
    public func closeRepository() {
        currentRepository = nil
    }
}