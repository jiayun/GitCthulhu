import Foundation
import Utilities

public class GitRepository: ObservableObject, Identifiable {
    public let id = UUID()
    public let url: URL
    public let name: String
    
    private let gitExecutor: GitCommandExecutor
    private let logger = Logger(category: "GitRepository")
    
    @Published public var status: [String: GitFileStatus] = [:]
    @Published public var branches: [GitBranch] = []
    @Published public var currentBranch: GitBranch?
    @Published public var isLoading = false
    
    public init(url: URL) throws {
        self.url = url
        self.name = url.lastPathComponent
        self.gitExecutor = GitCommandExecutor(repositoryURL: url)
        
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
        isLoading = true
        
        // Verify this is a valid Git repository first
        guard await gitExecutor.isValidRepository() else {
            logger.error("Invalid Git repository at \(url.path)")
            isLoading = false
            return
        }
        
        await loadCurrentBranch()
        await loadBranches()
        await loadStatus()
        
        isLoading = false
    }
    
    @MainActor
    private func loadCurrentBranch() async {
        do {
            if let branchName = try await gitExecutor.getCurrentBranch() {
                currentBranch = GitBranch(
                    name: branchName,
                    shortName: branchName,
                    isCurrent: true
                )
                logger.info("Current branch: \(branchName)")
            }
        } catch {
            logger.warning("Could not load current branch: \(error.localizedDescription)")
        }
    }
    
    @MainActor
    private func loadBranches() async {
        do {
            // Load local branches
            let localBranchNames = try await gitExecutor.getBranches()
            let localBranches = localBranchNames.map { branchName in
                let isCurrent = branchName == currentBranch?.shortName
                return GitBranch(
                    name: branchName,
                    shortName: branchName,
                    isRemote: false,
                    isCurrent: isCurrent
                )
            }
            
            // Load remote branches
            let remoteBranchNames = try await gitExecutor.getRemoteBranches()
            let remoteBranches = remoteBranchNames.map { branchName in
                return GitBranch(
                    name: branchName,
                    shortName: branchName.components(separatedBy: "/").last ?? branchName,
                    isRemote: true,
                    isCurrent: false
                )
            }
            
            branches = localBranches + remoteBranches
            logger.info("Loaded \(localBranches.count) local and \(remoteBranches.count) remote branches")
        } catch {
            logger.warning("Could not load branches: \(error.localizedDescription)")
        }
    }
    
    @MainActor
    private func loadStatus() async {
        do {
            let statusMap = try await gitExecutor.getRepositoryStatus()
            var convertedStatus: [String: GitFileStatus] = [:]
            
            for (fileName, statusCode) in statusMap {
                let gitStatus = convertGitStatus(statusCode)
                convertedStatus[fileName] = gitStatus
            }
            
            status = convertedStatus
            logger.info("Loaded status for \(status.count) files")
        } catch {
            logger.warning("Could not load repository status: \(error.localizedDescription)")
        }
    }
    
    private func convertGitStatus(_ statusCode: String) -> GitFileStatus {
        switch statusCode.prefix(2) {
        case "??": return .untracked
        case "A ", " A": return .added
        case "M ", " M", "MM": return .modified
        case "D ", " D": return .deleted
        case "R ", " R": return .renamed
        case "C ", " C": return .copied
        case "UU", "AA", "DD": return .unmerged
        default: return .modified
        }
    }
    
    // MARK: - Public Git Operations
    
    public func refreshStatus() async {
        await loadStatus()
    }
    
    public func stageFile(_ filePath: String) async throws {
        try await gitExecutor.stageFile(filePath)
        await refreshStatus()
    }
    
    public func unstageFile(_ filePath: String) async throws {
        try await gitExecutor.unstageFile(filePath)
        await refreshStatus()
    }
    
    public func commit(message: String) async throws {
        _ = try await gitExecutor.commit(message: message)
        await loadRepositoryData() // Refresh all data after commit
    }
    
    public func switchBranch(_ branchName: String) async throws {
        try await gitExecutor.switchBranch(branchName)
        await loadRepositoryData() // Refresh all data after branch switch
    }
    
    public func createBranch(_ name: String, from baseBranch: String? = nil) async throws {
        try await gitExecutor.createBranch(name, from: baseBranch)
        await loadBranches() // Refresh branches after creation
    }
}