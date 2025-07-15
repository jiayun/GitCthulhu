//
// GitStatusEntry.swift
// GitCthulhu
//
// Created by GitCthulhu Team on 2025-07-15.
//

import Foundation

/// Represents a detailed entry in the Git status output
public struct GitStatusEntry: Equatable, Hashable {
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
        self.filePath = filePath
        self.indexStatus = indexStatus
        self.workingDirectoryStatus = workingDirectoryStatus
        self.originalFilePath = originalFilePath
    }

    /// Creates a GitStatusEntry from a porcelain status line
    public static func fromPorcelainLine(_ line: String) -> GitStatusEntry? {
        guard line.count >= 3 else { return nil }

        let indexChar = line[line.startIndex]
        let workingChar = line[line.index(line.startIndex, offsetBy: 1)]
        let filePath = String(line.dropFirst(3))

        // Handle special cases for untracked files
        if line.hasPrefix("??") {
            return GitStatusEntry(
                filePath: filePath,
                indexStatus: .unmodified,
                workingDirectoryStatus: .untracked,
                originalFilePath: nil
            )
        }

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
            return .unmodified
        case "A":
            return .added
        case "M":
            return .modified
        case "D":
            return .deleted
        case "R":
            return .renamed
        case "C":
            return .copied
        case "U":
            return .unmerged
        default:
            return .modified
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
            return .unmodified
        case "M":
            return .modified
        case "D":
            return .deleted
        case "?":
            return .untracked
        case "!":
            return .ignored
        case "U":
            return .unmerged
        default:
            return .modified
        }
    }
}
