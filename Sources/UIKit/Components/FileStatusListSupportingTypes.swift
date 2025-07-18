//
// FileStatusListSupportingTypes.swift
// GitCthulhu
//
// Created by GitCthulhu Team on 2025-07-18.
//

import Foundation

public enum FileStatusFilter: String, CaseIterable, Identifiable {
    case all = "All Files"
    case staged = "Staged Only"
    case unstaged = "Modified Only"
    case untracked = "Untracked Only"
    case conflicted = "Conflicted Only"

    public var id: String { rawValue }
    public var systemImage: String {
        switch self {
        case .all: "doc.on.doc"
        case .staged: "checkmark.circle"
        case .unstaged: "pencil.circle"
        case .untracked: "plus.circle"
        case .conflicted: "exclamationmark.triangle"
        }
    }
}

public enum FileStatusGrouping: String, CaseIterable, Identifiable {
    case none = "No Grouping"
    case status = "Group by Status"
    case directory = "Group by Directory"

    public var id: String { rawValue }
}

public struct FileStatusGroup: Identifiable {
    public let id = UUID()
    public let title: String?
    public let files: [GitStatusEntry]

    public init(title: String?, files: [GitStatusEntry]) {
        self.title = title
        self.files = files
    }
}
