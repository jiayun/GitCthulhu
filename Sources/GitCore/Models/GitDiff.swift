//
// GitDiff.swift
// GitCthulhu
//
// Created by GitCthulhu Team on 2025-07-17.
//

import Foundation

/// Represents the complete diff for a single file
public struct GitDiff: Identifiable, Equatable {
    public let id = UUID()

    /// Path to the file in the new version
    public let filePath: String

    /// Path to the file in the old version (different if renamed)
    public let oldPath: String?

    /// Type of change for this file
    public let changeType: GitChangeType

    /// All chunks of changes in this file
    public let chunks: [GitDiffChunk]

    /// True if this is a binary file
    public let isBinary: Bool

    /// True if this file is new (added)
    public let isNew: Bool

    /// True if this file was deleted
    public let isDeleted: Bool

    /// True if this file was renamed
    public let isRenamed: Bool

    /// File mode changes (if any)
    public let oldMode: String?
    public let newMode: String?

    /// Original git diff header lines
    public let headerLines: [String]

    /// Raw diff content
    public let rawDiff: String

    public init(
        filePath: String,
        oldPath: String? = nil,
        changeType: GitChangeType,
        chunks: [GitDiffChunk] = [],
        isBinary: Bool = false,
        isNew: Bool = false,
        isDeleted: Bool = false,
        isRenamed: Bool = false,
        oldMode: String? = nil,
        newMode: String? = nil,
        headerLines: [String] = [],
        rawDiff: String = ""
    ) {
        self.filePath = filePath
        self.oldPath = oldPath
        self.changeType = changeType
        self.chunks = chunks
        self.isBinary = isBinary
        self.isNew = isNew
        self.isDeleted = isDeleted
        self.isRenamed = isRenamed
        self.oldMode = oldMode
        self.newMode = newMode
        self.headerLines = headerLines
        self.rawDiff = rawDiff
    }
}

/// Type of change for a file in Git
public enum GitChangeType: String, CaseIterable, Equatable {
    /// File was modified
    case modified = "M"

    /// File was added
    case added = "A"

    /// File was deleted
    case deleted = "D"

    /// File was renamed
    case renamed = "R"

    /// File was copied
    case copied = "C"

    /// File has conflicts (unmerged)
    case unmerged = "U"

    /// File type changed (e.g., file to symlink)
    case typeChanged = "T"

    /// Unknown change type
    case unknown = "?"

    /// Display name for the change type
    public var displayName: String {
        switch self {
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
        case .typeChanged:
            return "Type Changed"
        case .unknown:
            return "Unknown"
        }
    }

    /// Color associated with this change type
    public var color: String {
        switch self {
        case .modified:
            return "orange"
        case .added:
            return "green"
        case .deleted:
            return "red"
        case .renamed:
            return "blue"
        case .copied:
            return "purple"
        case .unmerged:
            return "red"
        case .typeChanged:
            return "yellow"
        case .unknown:
            return "gray"
        }
    }

    /// Symbol associated with this change type
    public var symbol: String {
        switch self {
        case .modified:
            return "pencil"
        case .added:
            return "plus"
        case .deleted:
            return "minus"
        case .renamed:
            return "arrow.right"
        case .copied:
            return "doc.on.doc"
        case .unmerged:
            return "exclamationmark.triangle"
        case .typeChanged:
            return "arrow.triangle.2.circlepath"
        case .unknown:
            return "questionmark"
        }
    }
}

// MARK: - Computed Properties

extension GitDiff {
    /// All lines from all chunks
    public var allLines: [GitDiffLine] {
        return chunks.flatMap { $0.lines }
    }

    /// Lines that represent additions
    public var addedLines: [GitDiffLine] {
        return allLines.filter { $0.type == .addition }
    }

    /// Lines that represent deletions
    public var deletedLines: [GitDiffLine] {
        return allLines.filter { $0.type == .deletion }
    }

    /// Lines that represent context (unchanged)
    public var contextLines: [GitDiffLine] {
        return allLines.filter { $0.type == .context }
    }

    /// Number of lines added
    public var additionsCount: Int {
        return addedLines.count
    }

    /// Number of lines deleted
    public var deletionsCount: Int {
        return deletedLines.count
    }

    /// Number of context lines
    public var contextCount: Int {
        return contextLines.count
    }

    /// Total number of lines in the diff
    public var totalLines: Int {
        return allLines.count
    }

    /// Net change in lines (additions - deletions)
    public var netChange: Int {
        return additionsCount - deletionsCount
    }

    /// Total number of changed lines (additions + deletions)
    public var totalChanges: Int {
        return additionsCount + deletionsCount
    }

    /// Returns true if this diff has any changes
    public var hasChanges: Bool {
        return totalChanges > 0 || isBinary
    }

    /// File name without path
    public var fileName: String {
        return URL(fileURLWithPath: filePath).lastPathComponent
    }

    /// Directory path
    public var directoryPath: String? {
        let url = URL(fileURLWithPath: filePath)
        let directory = url.deletingLastPathComponent().path
        return directory.isEmpty || directory == "." ? nil : directory
    }

    /// File extension
    public var fileExtension: String {
        return URL(fileURLWithPath: filePath).pathExtension
    }

    /// Effective file path for display (handles renames)
    public var displayPath: String {
        if isRenamed, let oldPath = oldPath {
            return "\(oldPath) → \(filePath)"
        }
        return filePath
    }
}

// MARK: - Statistics

extension GitDiff {
    /// Statistics for this diff
    public var stats: GitDiffStats {
        return GitDiffStats(
            additions: additionsCount,
            deletions: deletionsCount,
            context: contextCount,
            chunks: chunks.count,
            isBinary: isBinary
        )
    }
}

/// Statistics for a diff
public struct GitDiffStats: Equatable {
    public let additions: Int
    public let deletions: Int
    public let context: Int
    public let chunks: Int
    public let isBinary: Bool

    public init(
        additions: Int,
        deletions: Int,
        context: Int,
        chunks: Int,
        isBinary: Bool = false
    ) {
        self.additions = additions
        self.deletions = deletions
        self.context = context
        self.chunks = chunks
        self.isBinary = isBinary
    }

    /// Net change in lines (additions - deletions)
    public var netChange: Int {
        return additions - deletions
    }

    /// Total number of changed lines (additions + deletions)
    public var totalChanges: Int {
        return additions + deletions
    }

    /// Total number of lines (including context)
    public var totalLines: Int {
        return additions + deletions + context
    }

    /// Returns true if there are any changes
    public var hasChanges: Bool {
        return totalChanges > 0 || isBinary
    }

    /// Percentage of lines that are additions (0.0 to 1.0)
    public var additionPercentage: Double {
        guard totalChanges > 0 else { return 0.0 }
        return Double(additions) / Double(totalChanges)
    }

    /// Percentage of lines that are deletions (0.0 to 1.0)
    public var deletionPercentage: Double {
        guard totalChanges > 0 else { return 0.0 }
        return Double(deletions) / Double(totalChanges)
    }
}

// MARK: - Factory Methods

extension GitDiff {
    /// Creates a diff for a binary file
    public static func binaryFile(
        filePath: String,
        changeType: GitChangeType,
        oldPath: String? = nil
    ) -> GitDiff {
        return GitDiff(
            filePath: filePath,
            oldPath: oldPath,
            changeType: changeType,
            isBinary: true,
            isNew: changeType == .added,
            isDeleted: changeType == .deleted,
            isRenamed: changeType == .renamed
        )
    }

    /// Creates a diff for a new file
    public static func newFile(
        filePath: String,
        chunks: [GitDiffChunk] = []
    ) -> GitDiff {
        return GitDiff(
            filePath: filePath,
            changeType: .added,
            chunks: chunks,
            isNew: true
        )
    }

    /// Creates a diff for a deleted file
    public static func deletedFile(
        filePath: String,
        chunks: [GitDiffChunk] = []
    ) -> GitDiff {
        return GitDiff(
            filePath: filePath,
            changeType: .deleted,
            chunks: chunks,
            isDeleted: true
        )
    }

    /// Creates a diff for a renamed file
    public static func renamedFile(
        oldPath: String,
        newPath: String,
        chunks: [GitDiffChunk] = []
    ) -> GitDiff {
        return GitDiff(
            filePath: newPath,
            oldPath: oldPath,
            changeType: .renamed,
            chunks: chunks,
            isRenamed: true
        )
    }
}
