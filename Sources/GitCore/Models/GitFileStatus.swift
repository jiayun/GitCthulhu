//
// GitFileStatus.swift
// GitCthulhu
//
// Created by GitCthulhu Team on 2025-07-11.
//

import Foundation

public enum GitFileStatus: String, CaseIterable, Comparable {
    case unmodified = "unmodified"
    case modified = "modified"
    case added = "added"
    case deleted = "deleted"
    case renamed = "renamed"
    case copied = "copied"
    case untracked = "untracked"
    case ignored = "ignored"
    case typeChanged = "typeChanged"
    case conflicted = "conflicted"

    public var displayName: String {
        switch self {
        case .unmodified:
            "Unmodified"
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
        case .untracked:
            "Untracked"
        case .ignored:
            "Ignored"
        case .typeChanged:
            "Type Changed"
        case .conflicted:
            "Conflicted"
        }
    }

    public var symbolName: String {
        switch self {
        case .unmodified:
            "checkmark.circle"
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
        case .untracked:
            "questionmark.circle"
        case .ignored:
            "eye.slash"
        case .typeChanged:
            "arrow.up.arrow.down.circle"
        case .conflicted:
            "exclamationmark.triangle"
        }
    }

    public var priority: Int {
        switch self {
        case .conflicted:
            0
        case .untracked:
            1
        case .modified:
            2
        case .added:
            3
        case .deleted:
            4
        case .renamed:
            5
        case .copied:
            6
        case .typeChanged:
            7
        case .ignored:
            8
        case .unmodified:
            9
        }
    }

    public static func < (lhs: GitFileStatus, rhs: GitFileStatus) -> Bool {
        lhs.priority < rhs.priority
    }
}
