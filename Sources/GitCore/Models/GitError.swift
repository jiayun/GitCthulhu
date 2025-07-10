import Foundation

public enum GitError: Error, LocalizedError, Equatable {
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
        case let .failedToOpenRepository(message):
            "Failed to open repository: \(message)"
        case let .failedToInitializeRepository(message):
            "Failed to initialize repository: \(message)"
        case .invalidRepositoryPath:
            "Invalid repository path"
        case let .libgit2Error(message):
            "Git operation failed: \(message)"
        case let .fileNotFound(path):
            "File not found: \(path)"
        case .permissionDenied:
            "Permission denied"
        case let .networkError(message):
            "Network error: \(message)"
        case let .unknown(message):
            "Unknown error: \(message)"
        }
    }
}
