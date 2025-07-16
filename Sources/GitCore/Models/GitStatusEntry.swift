//
// GitStatusEntry.swift
// GitCthulhu
//
// Created by GitCthulhu Team on 2025-07-15.
//

import Foundation

/// Represents a detailed entry in the Git status output
public struct GitStatusEntry: Identifiable {
    /// Unique identifier for SwiftUI
    public let id: UUID

    /// The file path relative to the repository root
    public let filePath: String

    /// The status of the file in the index (staging area)
    public let indexStatus: GitIndexStatus

    /// The status of the file in the working directory
    public let workingDirectoryStatus: GitWorkingDirectoryStatus

    /// The original file path for renamed files
    public let originalFilePath: String?

    /// Combined status for UI display
    public var displayStatus: GitFileStatus {
        // Priority order: unmerged > staged > working directory
        if indexStatus == .unmerged || workingDirectoryStatus == .unmerged {
            return .unmerged
        }

        if indexStatus != .unmodified {
            switch indexStatus {
            case .added:
                return .added
            case .modified:
                return .modified
            case .deleted:
                return .deleted
            case .renamed:
                return .renamed
            case .copied:
                return .copied
            default:
                break
            }
        }

        switch workingDirectoryStatus {
        case .modified:
            return .modified
        case .deleted:
            return .deleted
        case .untracked:
            return .untracked
        case .ignored:
            return .ignored
        default:
            return .modified
        }
    }

    /// Whether the file is staged (in index)
    public var isStaged: Bool {
        indexStatus != .unmodified
    }

    /// Whether the file has working directory changes
    public var hasWorkingDirectoryChanges: Bool {
        workingDirectoryStatus != .unmodified && workingDirectoryStatus != .untracked
    }

    /// Whether the file is untracked
    public var isUntracked: Bool {
        workingDirectoryStatus == .untracked
    }

    /// Whether the file is ignored
    public var isIgnored: Bool {
        workingDirectoryStatus == .ignored
    }

    /// Whether the file has conflicts
    public var hasConflicts: Bool {
        indexStatus == .unmerged || workingDirectoryStatus == .unmerged
    }

    public init(
        filePath: String,
        indexStatus: GitIndexStatus,
        workingDirectoryStatus: GitWorkingDirectoryStatus,
        originalFilePath: String? = nil
    ) {
        self.id = UUID()
        self.filePath = filePath
        self.indexStatus = indexStatus
        self.workingDirectoryStatus = workingDirectoryStatus
        self.originalFilePath = originalFilePath
    }

    /// Creates a GitStatusEntry from a porcelain status line
    public static func fromPorcelainLine(_ line: String) -> GitStatusEntry? {
        guard line.count >= 3 else { return nil }

        // Handle special cases for untracked files first
        if line.hasPrefix("??") {
            let filePath = String(line.dropFirst(3))
            return GitStatusEntry(
                filePath: filePath,
                indexStatus: .unmodified,
                workingDirectoryStatus: .untracked,
                originalFilePath: nil
            )
        }

        // For standard porcelain format, expect at least 3 characters
        // Format: "XY filename" where X and Y are status chars
        let indexChar = line[line.startIndex]
        let workingChar = line[line.index(line.startIndex, offsetBy: 1)]

        // Find the first space after the status characters and extract filename from there
        let remainingLine = line.dropFirst(2)

        // Skip any spaces after the status characters
        let filePath = String(remainingLine.drop(while: { $0 == " " }))

        let indexStatus = GitIndexStatus.fromStatusChar(indexChar)
        let workingStatus = GitWorkingDirectoryStatus.fromStatusChar(workingChar)

        // Handle renamed files (format: "R  old_name -> new_name")
        var actualFilePath = filePath
        var originalFilePath: String?

        if indexStatus == .renamed, let arrowIndex = filePath.firstIndex(of: ">") {
            let beforeArrow = filePath[..<arrowIndex].trimmingCharacters(in: .whitespaces)
            let afterArrow = filePath[filePath.index(after: arrowIndex)...].trimmingCharacters(in: .whitespaces)

            if beforeArrow.hasSuffix(" -") {
                originalFilePath = String(beforeArrow.dropLast(2)).trimmingCharacters(in: .whitespaces)
                actualFilePath = afterArrow
            }
        }

        return GitStatusEntry(
            filePath: actualFilePath,
            indexStatus: indexStatus,
            workingDirectoryStatus: workingStatus,
            originalFilePath: originalFilePath
        )
    }
}

// MARK: - Equatable Implementation
extension GitStatusEntry: Equatable {
    public static func == (lhs: GitStatusEntry, rhs: GitStatusEntry) -> Bool {
        return lhs.filePath == rhs.filePath &&
               lhs.indexStatus == rhs.indexStatus &&
               lhs.workingDirectoryStatus == rhs.workingDirectoryStatus &&
               lhs.originalFilePath == rhs.originalFilePath
    }
}

// MARK: - Hashable Implementation
extension GitStatusEntry: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(filePath)
        hasher.combine(indexStatus)
        hasher.combine(workingDirectoryStatus)
        hasher.combine(originalFilePath)
    }
}

/// Represents the status of a file in the Git index (staging area)
public enum GitIndexStatus: String, CaseIterable {
    case unmodified = " "
    case added = "A"
    case modified = "M"
    case deleted = "D"
    case renamed = "R"
    case copied = "C"
    case unmerged = "U"

    static func fromStatusChar(_ char: Character) -> GitIndexStatus {
        switch char {
        case " ":
            .unmodified
        case "A":
            .added
        case "M":
            .modified
        case "D":
            .deleted
        case "R":
            .renamed
        case "C":
            .copied
        case "U":
            .unmerged
        default:
            .modified
        }
    }
}

/// Represents the status of a file in the working directory
public enum GitWorkingDirectoryStatus: String, CaseIterable {
    case unmodified = " "
    case modified = "M"
    case deleted = "D"
    case untracked = "?"
    case ignored = "!"
    case unmerged = "U"

    static func fromStatusChar(_ char: Character) -> GitWorkingDirectoryStatus {
        switch char {
        case " ":
            .unmodified
        case "M":
            .modified
        case "D":
            .deleted
        case "?":
            .untracked
        case "!":
            .ignored
        case "U":
            .unmerged
        default:
            .modified
        }
    }
}
