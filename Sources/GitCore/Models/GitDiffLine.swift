//
// GitDiffLine.swift
// GitCthulhu
//
// Created by GitCthulhu Team on 2025-07-17.
//

import Foundation

/// Represents a single line in a Git diff
public struct GitDiffLine: Identifiable, Equatable {
    public let id = UUID()

    /// The type of diff line (context, addition, deletion, etc.)
    public let type: GitDiffLineType

    /// Line number in the original file (nil for additions)
    public let oldLineNumber: Int?

    /// Line number in the new file (nil for deletions)
    public let newLineNumber: Int?

    /// The actual content of the line (without the +/- prefix)
    public let content: String

    /// Raw line from git diff (including +/- prefix)
    public let rawLine: String

    public init(
        type: GitDiffLineType,
        oldLineNumber: Int? = nil,
        newLineNumber: Int? = nil,
        content: String,
        rawLine: String
    ) {
        self.type = type
        self.oldLineNumber = oldLineNumber
        self.newLineNumber = newLineNumber
        self.content = content
        self.rawLine = rawLine
    }
}

/// Type of line in a Git diff
public enum GitDiffLineType: String, CaseIterable, Equatable {
    /// Context line (unchanged)
    case context = " "

    /// Added line
    case addition = "+"

    /// Deleted line
    case deletion = "-"

    /// No newline at end of file marker
    case noNewline = "\\"

    /// Header line (@@)
    case header = "@"

    /// File header line (+++ or ---)
    case fileHeader = "f"

    /// Git diff meta information
    case meta = "m"

    /// Returns the display symbol for this line type
    public var symbol: String {
        switch self {
        case .context:
            return " "
        case .addition:
            return "+"
        case .deletion:
            return "-"
        case .noNewline:
            return "\\"
        case .header:
            return "@"
        case .fileHeader:
            return "f"
        case .meta:
            return "m"
        }
    }

    /// Returns true if this line type represents actual file content
    public var isContentLine: Bool {
        switch self {
        case .context, .addition, .deletion:
            return true
        case .noNewline, .header, .fileHeader, .meta:
            return false
        }
    }

    /// Returns true if this line represents a change (addition or deletion)
    public var isChange: Bool {
        return self == .addition || self == .deletion
    }
}

// MARK: - Extensions

extension GitDiffLine {
    /// Returns true if this line is an addition
    public var isAddition: Bool {
        return type == .addition
    }

    /// Returns true if this line is a deletion
    public var isDeletion: Bool {
        return type == .deletion
    }

    /// Returns true if this line is context (unchanged)
    public var isContext: Bool {
        return type == .context
    }

    /// Returns the effective line number for display purposes
    public var displayLineNumber: Int? {
        return newLineNumber ?? oldLineNumber
    }

    /// Returns a trimmed version of the content (useful for display)
    public var trimmedContent: String {
        return content.trimmingCharacters(in: .whitespaces)
    }

    /// Returns true if this line contains only whitespace
    public var isWhitespaceOnly: Bool {
        return content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

// MARK: - Factory Methods

extension GitDiffLine {
    /// Creates a context line
    public static func context(
        oldLineNumber: Int,
        newLineNumber: Int,
        content: String
    ) -> GitDiffLine {
        return GitDiffLine(
            type: .context,
            oldLineNumber: oldLineNumber,
            newLineNumber: newLineNumber,
            content: content,
            rawLine: " \(content)"
        )
    }

    /// Creates an addition line
    public static func addition(
        newLineNumber: Int,
        content: String
    ) -> GitDiffLine {
        return GitDiffLine(
            type: .addition,
            oldLineNumber: nil,
            newLineNumber: newLineNumber,
            content: content,
            rawLine: "+\(content)"
        )
    }

    /// Creates a deletion line
    public static func deletion(
        oldLineNumber: Int,
        content: String
    ) -> GitDiffLine {
        return GitDiffLine(
            type: .deletion,
            oldLineNumber: oldLineNumber,
            newLineNumber: nil,
            content: content,
            rawLine: "-\(content)"
        )
    }

    /// Creates a header line
    public static func header(content: String) -> GitDiffLine {
        return GitDiffLine(
            type: .header,
            content: content,
            rawLine: content
        )
    }
}
