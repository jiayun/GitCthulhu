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
    public var filePath: String

    /// Path to the file in the old version (different if renamed)
    public var oldPath: String?

    /// Type of change for this file
    public var changeType: GitChangeType

    /// All chunks of changes in this file
    public var chunks: [GitDiffChunk]

    /// True if this is a binary file
    public var isBinary: Bool

    /// True if this file is new (added)
    public var isNew: Bool

    /// True if this file was deleted
    public var isDeleted: Bool

    /// True if this file was renamed
    public var isRenamed: Bool

    /// File mode changes (if any)
    public var oldMode: String?
    public var newMode: String?

    /// Original git diff header lines
    public var headerLines: [String]

    /// Raw diff content
    public var rawDiff: String

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
        case .typeChanged:
            "Type Changed"
        case .unknown:
            "Unknown"
        }
    }

    /// Color associated with this change type
    public var color: String {
        switch self {
        case .modified:
            "orange"
        case .added:
            "green"
        case .deleted:
            "red"
        case .renamed:
            "blue"
        case .copied:
            "purple"
        case .unmerged:
            "red"
        case .typeChanged:
            "yellow"
        case .unknown:
            "gray"
        }
    }

    /// Symbol associated with this change type
    public var symbol: String {
        switch self {
        case .modified:
            "pencil"
        case .added:
            "plus"
        case .deleted:
            "minus"
        case .renamed:
            "arrow.right"
        case .copied:
            "doc.on.doc"
        case .unmerged:
            "exclamationmark.triangle"
        case .typeChanged:
            "arrow.triangle.2.circlepath"
        case .unknown:
            "questionmark"
        }
    }
}

// MARK: - Computed Properties

public extension GitDiff {
    /// All lines from all chunks
    var allLines: [GitDiffLine] {
        chunks.flatMap(\.lines)
    }

    /// Lines that represent additions
    var addedLines: [GitDiffLine] {
        allLines.filter { $0.type == .addition }
    }

    /// Lines that represent deletions
    var deletedLines: [GitDiffLine] {
        allLines.filter { $0.type == .deletion }
    }

    /// Lines that represent context (unchanged)
    var contextLines: [GitDiffLine] {
        allLines.filter { $0.type == .context }
    }

    /// Number of lines added
    var additionsCount: Int {
        addedLines.count
    }

    /// Number of lines deleted
    var deletionsCount: Int {
        deletedLines.count
    }

    /// Number of context lines
    var contextCount: Int {
        contextLines.count
    }

    /// Total number of lines in the diff
    var totalLines: Int {
        allLines.count
    }

    /// Net change in lines (additions - deletions)
    var netChange: Int {
        additionsCount - deletionsCount
    }

    /// Total number of changed lines (additions + deletions)
    var totalChanges: Int {
        additionsCount + deletionsCount
    }

    /// Returns true if this diff has any changes
    var hasChanges: Bool {
        totalChanges > 0 || isBinary
    }

    /// File name without path
    var fileName: String {
        URL(fileURLWithPath: filePath).lastPathComponent
    }

    /// Directory path
    var directoryPath: String? {
        let url = URL(fileURLWithPath: filePath)
        let directory = url.deletingLastPathComponent().path
        return directory.isEmpty || directory == "." ? nil : directory
    }

    /// File extension
    var fileExtension: String {
        URL(fileURLWithPath: filePath).pathExtension
    }

    /// Effective file path for display (handles renames)
    var displayPath: String {
        if isRenamed, let oldPath {
            return "\(oldPath) → \(filePath)"
        }
        return filePath
    }
}

// MARK: - Statistics

public extension GitDiff {
    /// Statistics for this diff
    var stats: GitDiffStats {
        GitDiffStats(
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
        additions - deletions
    }

    /// Total number of changed lines (additions + deletions)
    public var totalChanges: Int {
        additions + deletions
    }

    /// Total number of lines (including context)
    public var totalLines: Int {
        additions + deletions + context
    }

    /// Returns true if there are any changes
    public var hasChanges: Bool {
        totalChanges > 0 || isBinary
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

public extension GitDiff {
    /// Creates a diff for a binary file
    static func binaryFile(
        filePath: String,
        changeType: GitChangeType,
        oldPath: String? = nil
    ) -> GitDiff {
        GitDiff(
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
    static func newFile(
        filePath: String,
        chunks: [GitDiffChunk] = []
    ) -> GitDiff {
        GitDiff(
            filePath: filePath,
            changeType: .added,
            chunks: chunks,
            isNew: true
        )
    }

    /// Creates a diff for a deleted file
    static func deletedFile(
        filePath: String,
        chunks: [GitDiffChunk] = []
    ) -> GitDiff {
        GitDiff(
            filePath: filePath,
            changeType: .deleted,
            chunks: chunks,
            isDeleted: true
        )
    }

    /// Creates a diff for a renamed file
    static func renamedFile(
        oldPath: String,
        newPath: String,
        chunks: [GitDiffChunk] = []
    ) -> GitDiff {
        GitDiff(
            filePath: newPath,
            oldPath: oldPath,
            changeType: .renamed,
            chunks: chunks,
            isRenamed: true
        )
    }
}
