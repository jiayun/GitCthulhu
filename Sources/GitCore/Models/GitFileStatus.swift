import Foundation

public enum GitFileStatus: String, CaseIterable {
    case untracked = "untracked"
    case modified = "modified"
    case added = "added"
    case deleted = "deleted"
    case renamed = "renamed"
    case copied = "copied"
    case unmerged = "unmerged"
    case ignored = "ignored"

    public var displayName: String {
        switch self {
        case .untracked:
            return "Untracked"
        case .modified:
            return "Modified"
        case .added:
            return "Added"
        case .deleted:
            return "Deleted"
        case .renamed:
            return "Renamed"
        case .copied:
            return "Copied"
        case .unmerged:
            return "Unmerged"
        case .ignored:
            return "Ignored"
        }
    }

    public var symbolName: String {
        switch self {
        case .untracked:
            return "questionmark.circle"
        case .modified:
            return "pencil.circle"
        case .added:
            return "plus.circle"
        case .deleted:
            return "minus.circle"
        case .renamed:
            return "arrow.triangle.2.circlepath"
        case .copied:
            return "doc.on.doc"
        case .unmerged:
            return "exclamationmark.triangle"
        case .ignored:
            return "eye.slash"
        }
    }
}
