//
// GitDiffChunk.swift
// GitCthulhu
//
// Created by GitCthulhu Team on 2025-07-17.
//

import Foundation

/// Represents a chunk (hunk) of changes in a Git diff
public struct GitDiffChunk: Identifiable, Equatable {
    public let id = UUID()

    /// Starting line number in the old file
    public let oldStart: Int

    /// Number of lines in the old file for this chunk
    public let oldCount: Int

    /// Starting line number in the new file
    public let newStart: Int

    /// Number of lines in the new file for this chunk
    public let newCount: Int

    /// Optional function or section context (e.g., function name)
    public let context: String?

    /// All lines in this chunk
    public let lines: [GitDiffLine]

    /// The original hunk header line (e.g., @@ -1,4 +1,6 @@)
    public let headerLine: String

    public init(
        oldStart: Int,
        oldCount: Int,
        newStart: Int,
        newCount: Int,
        context: String? = nil,
        lines: [GitDiffLine] = [],
        headerLine: String
    ) {
        self.oldStart = oldStart
        self.oldCount = oldCount
        self.newStart = newStart
        self.newCount = newCount
        self.context = context
        self.lines = lines
        self.headerLine = headerLine
    }
}

// MARK: - Computed Properties

public extension GitDiffChunk {
    /// Lines that represent additions
    var addedLines: [GitDiffLine] {
        lines.filter { $0.type == .addition }
    }

    /// Lines that represent deletions
    var deletedLines: [GitDiffLine] {
        lines.filter { $0.type == .deletion }
    }

    /// Lines that represent context (unchanged)
    var contextLines: [GitDiffLine] {
        lines.filter { $0.type == .context }
    }

    /// Number of lines added in this chunk
    var additionsCount: Int {
        addedLines.count
    }

    /// Number of lines deleted in this chunk
    var deletionsCount: Int {
        deletedLines.count
    }

    /// Number of context lines in this chunk
    var contextCount: Int {
        contextLines.count
    }

    /// Returns true if this chunk contains any changes
    var hasChanges: Bool {
        additionsCount > 0 || deletionsCount > 0
    }

    /// Returns true if this chunk only contains additions
    var isAdditionOnly: Bool {
        additionsCount > 0 && deletionsCount == 0
    }

    /// Returns true if this chunk only contains deletions
    var isDeletionOnly: Bool {
        deletionsCount > 0 && additionsCount == 0
    }

    /// Returns true if this chunk contains both additions and deletions
    var isMixed: Bool {
        additionsCount > 0 && deletionsCount > 0
    }

    /// The ending line number in the old file
    var oldEnd: Int {
        oldStart + oldCount - 1
    }

    /// The ending line number in the new file
    var newEnd: Int {
        newStart + newCount - 1
    }

    /// Range of lines in the old file
    var oldRange: ClosedRange<Int> {
        oldStart ... oldEnd
    }

    /// Range of lines in the new file
    var newRange: ClosedRange<Int> {
        newStart ... newEnd
    }
}

// MARK: - Statistics

public extension GitDiffChunk {
    /// Statistics for this chunk
    var stats: GitDiffChunkStats {
        GitDiffChunkStats(
            additions: additionsCount,
            deletions: deletionsCount,
            context: contextCount,
            total: lines.count
        )
    }
}

/// Statistics for a diff chunk
public struct GitDiffChunkStats: Equatable {
    public let additions: Int
    public let deletions: Int
    public let context: Int
    public let total: Int

    public init(additions: Int, deletions: Int, context: Int, total: Int) {
        self.additions = additions
        self.deletions = deletions
        self.context = context
        self.total = total
    }

    /// Net change in lines (additions - deletions)
    public var netChange: Int {
        additions - deletions
    }

    /// Total number of changed lines (additions + deletions)
    public var totalChanges: Int {
        additions + deletions
    }

    /// Returns true if there are any changes
    public var hasChanges: Bool {
        totalChanges > 0
    }
}

// MARK: - Factory Methods

public extension GitDiffChunk {
    /// Parses a hunk header line and creates a chunk with the parsed information
    /// Expected format: @@ -oldStart,oldCount +newStart,newCount @@ [context]
    static func parseHeader(_ headerLine: String) -> GitDiffChunk? {
        let trimmed = headerLine.trimmingCharacters(in: .whitespaces)

        // Basic validation
        guard trimmed.hasPrefix("@@"), trimmed.contains("@@") else {
            return nil
        }

        // Extract the range information between @@ markers
        let components = trimmed.components(separatedBy: "@@")
        guard components.count >= 2 else {
            return nil
        }

        let rangeString = components[1].trimmingCharacters(in: .whitespaces)
        let context = components.count > 2 ? components[2].trimmingCharacters(in: .whitespaces) : nil

        // Parse the ranges: -oldStart,oldCount +newStart,newCount
        let ranges = rangeString.components(separatedBy: " ")
        guard ranges.count == 2 else {
            return nil
        }

        // Parse old range
        let oldRange = ranges[0]
        guard oldRange.hasPrefix("-") else {
            return nil
        }
        let oldParts = String(oldRange.dropFirst()).components(separatedBy: ",")
        guard let oldStart = Int(oldParts[0]) else {
            return nil
        }
        let oldCount = oldParts.count > 1 ? Int(oldParts[1]) ?? 1 : 1

        // Parse new range
        let newRange = ranges[1]
        guard newRange.hasPrefix("+") else {
            return nil
        }
        let newParts = String(newRange.dropFirst()).components(separatedBy: ",")
        guard let newStart = Int(newParts[0]) else {
            return nil
        }
        let newCount = newParts.count > 1 ? Int(newParts[1]) ?? 1 : 1

        return GitDiffChunk(
            oldStart: oldStart,
            oldCount: oldCount,
            newStart: newStart,
            newCount: newCount,
            context: context?.isEmpty == false ? context : nil,
            headerLine: headerLine
        )
    }

    /// Creates a new chunk with additional lines
    func withLines(_ newLines: [GitDiffLine]) -> GitDiffChunk {
        GitDiffChunk(
            oldStart: oldStart,
            oldCount: oldCount,
            newStart: newStart,
            newCount: newCount,
            context: context,
            lines: newLines,
            headerLine: headerLine
        )
    }
}
