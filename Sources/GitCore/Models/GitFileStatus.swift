import Foundation

public enum GitFileStatus: String, CaseIterable {
    case untracked
    case modified
    case added
    case deleted
    case renamed
    case copied
    case unmerged
    case ignored

    public var displayName: String {
        switch self {
        case .untracked:
            "Untracked"
        case .modified:
            "Modified"
        case .added:
            "Added"
        case .deleted:
            "Deleted"
        case .renamed:
            "Renamed"
        case .copied:
            "Copied"
        case .unmerged:
            "Unmerged"
        case .ignored:
            "Ignored"
        }
    }

    public var symbolName: String {
        switch self {
        case .untracked:
            "questionmark.circle"
        case .modified:
            "pencil.circle"
        case .added:
            "plus.circle"
        case .deleted:
            "minus.circle"
        case .renamed:
            "arrow.triangle.2.circlepath"
        case .copied:
            "doc.on.doc"
        case .unmerged:
            "exclamationmark.triangle"
        case .ignored:
            "eye.slash"
        }
    }
}
