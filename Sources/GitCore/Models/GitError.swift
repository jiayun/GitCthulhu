import Foundation

public enum GitError: Error, LocalizedError {
    case failedToOpenRepository(String)
    case failedToInitializeRepository(String)
    case invalidRepositoryPath
    case libgit2Error(String)
    case fileNotFound(String)
    case permissionDenied
    case networkError(String)
    case unknown(String)
    
    public var errorDescription: String? {
        switch self {
        case .failedToOpenRepository(let message):
            return "Failed to open repository: \(message)"
        case .failedToInitializeRepository(let message):
            return "Failed to initialize repository: \(message)"
        case .invalidRepositoryPath:
            return "Invalid repository path"
        case .libgit2Error(let message):
            return "Git operation failed: \(message)"
        case .fileNotFound(let path):
            return "File not found: \(path)"
        case .permissionDenied:
            return "Permission denied"
        case .networkError(let message):
            return "Network error: \(message)"
        case .unknown(let message):
            return "Unknown error: \(message)"
        }
    }
}