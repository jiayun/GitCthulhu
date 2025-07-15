//
// FileStatusInfo.swift
// GitCthulhu
//
// Created by GitCthulhu Team on 2025-07-15.
//

import Foundation

public struct FileStatusInfo: Identifiable, Equatable, Hashable {
    public let id: String
    public let fileName: String
    public let filePath: String
    public let status: GitFileStatus
    public let isStaged: Bool
    public let isUnstaged: Bool
    public let fileSize: Int64?
    public let modificationDate: Date?
    
    public init(
        fileName: String,
        filePath: String,
        status: GitFileStatus,
        isStaged: Bool = false,
        isUnstaged: Bool = false,
        fileSize: Int64? = nil,
        modificationDate: Date? = nil
    ) {
        self.id = filePath
        self.fileName = fileName
        self.filePath = filePath
        self.status = status
        self.isStaged = isStaged
        self.isUnstaged = isUnstaged
        self.fileSize = fileSize
        self.modificationDate = modificationDate
    }
    
    public var displayName: String {
        fileName
    }
    
    public var relativePath: String {
        filePath
    }
    
    public var statusDescription: String {
        switch (isStaged, isUnstaged) {
        case (true, true):
            return "Staged & Modified"
        case (true, false):
            return "Staged"
        case (false, true):
            return status.displayName
        case (false, false):
            return status.displayName
        }
    }
    
    public var primaryStatus: GitFileStatus {
        status
    }
    
    public var formattedFileSize: String? {
        guard let fileSize = fileSize else { return nil }
        return ByteCountFormatter.string(fromByteCount: fileSize, countStyle: .file)
    }
    
    public var formattedModificationDate: String? {
        guard let modificationDate = modificationDate else { return nil }
        let formatter = RelativeDateTimeFormatter()
        formatter.dateTimeStyle = .named
        return formatter.localizedString(for: modificationDate, relativeTo: Date())
    }
}

// MARK: - File grouping

public extension FileStatusInfo {
    var groupCategory: FileGroupCategory {
        switch status {
        case .untracked:
            return .untracked
        case .modified:
            return isStaged ? .staged : .modified
        case .added:
            return .staged
        case .deleted:
            return isStaged ? .staged : .deleted
        case .renamed, .copied:
            return .staged
        case .unmerged:
            return .conflicted
        case .ignored:
            return .ignored
        }
    }
}

public enum FileGroupCategory: String, CaseIterable {
    case staged = "Staged"
    case modified = "Modified"
    case untracked = "Untracked"
    case deleted = "Deleted"
    case conflicted = "Conflicted"
    case ignored = "Ignored"
    
    public var displayName: String {
        rawValue
    }
    
    public var symbolName: String {
        switch self {
        case .staged:
            return "checkmark.circle.fill"
        case .modified:
            return "pencil.circle.fill"
        case .untracked:
            return "questionmark.circle.fill"
        case .deleted:
            return "minus.circle.fill"
        case .conflicted:
            return "exclamationmark.triangle.fill"
        case .ignored:
            return "eye.slash.fill"
        }
    }
    
    public var priority: Int {
        switch self {
        case .staged:
            return 1
        case .modified:
            return 2
        case .untracked:
            return 3
        case .deleted:
            return 4
        case .conflicted:
            return 0 // Highest priority
        case .ignored:
            return 5 // Lowest priority
        }
    }
}