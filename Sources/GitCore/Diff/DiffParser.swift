//
// DiffParser.swift
// GitCthulhu
//
// Created by GitCthulhu Team on 2025-07-15.
//

import Foundation

/// Represents the complete diff content for a single file
/// 
/// This structure contains all the information needed to display a diff,
/// including the file path, hunks of changes, and metadata about the file.
public struct DiffContent {
    /// The path to the file being diffed
    public let filePath: String
    
    /// The old content of the file (currently not populated)
    public let oldContent: String
    
    /// The new content of the file (currently not populated)
    public let newContent: String
    
    /// Array of diff hunks containing the actual changes
    public let hunks: [DiffHunk]
    
    /// Whether this is a binary file
    public let isBinary: Bool
    
    /// Whether this is a new file being added
    public let isNewFile: Bool
    
    /// Whether this is a file being deleted
    public let isDeletedFile: Bool
    
    /// Statistics about the changes (additions, deletions, etc.)
    public let statistics: DiffStatistics
    
    public init(
        filePath: String,
        oldContent: String = "",
        newContent: String = "",
        hunks: [DiffHunk] = [],
        isBinary: Bool = false,
        isNewFile: Bool = false,
        isDeletedFile: Bool = false,
        statistics: DiffStatistics = DiffStatistics()
    ) {
        self.filePath = filePath
        self.oldContent = oldContent
        self.newContent = newContent
        self.hunks = hunks
        self.isBinary = isBinary
        self.isNewFile = isNewFile
        self.isDeletedFile = isDeletedFile
        self.statistics = statistics
    }
}

/// Represents a single hunk of changes in a diff
/// 
/// A hunk is a contiguous block of changes in a file, typically preceded by
/// a header like "@@ -1,5 +1,6 @@" that indicates the line ranges.
public struct DiffHunk {
    /// The starting line number in the old file
    public let oldStartLine: Int
    
    /// The number of lines in the old file for this hunk
    public let oldLineCount: Int
    
    /// The starting line number in the new file
    public let newStartLine: Int
    
    /// The number of lines in the new file for this hunk
    public let newLineCount: Int
    
    /// Optional context information from the hunk header
    public let context: String
    
    /// Array of individual lines in this hunk
    public let lines: [DiffLine]
    
    public init(
        oldStartLine: Int,
        oldLineCount: Int,
        newStartLine: Int,
        newLineCount: Int,
        context: String = "",
        lines: [DiffLine] = []
    ) {
        self.oldStartLine = oldStartLine
        self.oldLineCount = oldLineCount
        self.newStartLine = newStartLine
        self.newLineCount = newLineCount
        self.context = context
        self.lines = lines
    }
}

/// Represents a single line in a diff hunk
/// 
/// Each line can be a context line (unchanged), added line, removed line,
/// or a special indicator like "no newline at end of file".
public struct DiffLine {
    /// The type of this line (context, added, removed, etc.)
    public let type: DiffLineType
    
    /// The actual content of the line
    public let content: String
    
    /// Line number in the old file (nil for added lines)
    public let oldLineNumber: Int?
    
    /// Line number in the new file (nil for removed lines)
    public let newLineNumber: Int?
    
    public init(
        type: DiffLineType,
        content: String,
        oldLineNumber: Int? = nil,
        newLineNumber: Int? = nil
    ) {
        self.type = type
        self.content = content
        self.oldLineNumber = oldLineNumber
        self.newLineNumber = newLineNumber
    }
}

/// Represents the type of a diff line
/// 
/// This determines how the line should be displayed and colored in the diff viewer.
public enum DiffLineType {
    /// Context line (unchanged, appears in both old and new file)
    case context
    
    /// Added line (new content, appears only in new file)
    case added
    
    /// Removed line (old content, appears only in old file)
    case removed
    
    /// Special indicator for "no newline at end of file"
    case noNewlineAtEnd
}

/// Statistics about the changes in a diff
/// 
/// Provides summary information about the number of additions, deletions,
/// and total changes in a file.
public struct DiffStatistics {
    /// Number of lines added
    public let additions: Int
    
    /// Number of lines removed
    public let deletions: Int
    
    /// Total number of changed lines (additions + deletions)
    public let totalLines: Int
    
    public init(additions: Int = 0, deletions: Int = 0) {
        self.additions = additions
        self.deletions = deletions
        self.totalLines = additions + deletions
    }
    
    public var isEmpty: Bool {
        return additions == 0 && deletions == 0
    }
}

/// Parser for Git unified diff output
/// 
/// This class can parse the output from `git diff` and convert it into
/// structured DiffContent objects that can be displayed in a diff viewer.
/// 
/// ## Usage
/// ```swift
/// let parser = DiffParser()
/// let diffContents = parser.parse(gitDiffOutput)
/// ```
/// 
/// ## Supported Features
/// - Unified diff format parsing
/// - Multiple file diffs
/// - Binary file detection
/// - Hunk header parsing with context
/// - Line-by-line change tracking
/// - Statistics calculation
/// - "No newline at end of file" handling
public class DiffParser {
    
    /// Initialize a new diff parser
    public init() {}
    
    /// Parse Git diff output into structured DiffContent objects
    /// 
    /// - Parameter diffOutput: The raw output from `git diff`
    /// - Returns: Array of DiffContent objects, one for each file in the diff
    public func parse(_ diffOutput: String) -> [DiffContent] {
        let lines = diffOutput.components(separatedBy: .newlines)
        var diffContents: [DiffContent] = []
        var currentContent: DiffContent?
        var currentHunk: DiffHunk?
        var currentLines: [DiffLine] = []
        
        var oldLineNumber = 0
        var newLineNumber = 0
        
        for line in lines {
            if line.hasPrefix("diff --git") {
                // Finalize previous content
                if let content = currentContent {
                    diffContents.append(finalizeContent(content, currentHunk: currentHunk, currentLines: currentLines))
                }
                
                // Start new file diff
                currentContent = parseFileHeader(line)
                currentHunk = nil
                currentLines = []
                
            } else if line.hasPrefix("---") || line.hasPrefix("+++") {
                // File path information (skip for now)
                continue
                
            } else if line.hasPrefix("@@") {
                // Finalize previous hunk
                if let hunk = currentHunk {
                    let finalizedHunk = DiffHunk(
                        oldStartLine: hunk.oldStartLine,
                        oldLineCount: hunk.oldLineCount,
                        newStartLine: hunk.newStartLine,
                        newLineCount: hunk.newLineCount,
                        context: hunk.context,
                        lines: currentLines
                    )
                    if var content = currentContent {
                        content = DiffContent(
                            filePath: content.filePath,
                            oldContent: content.oldContent,
                            newContent: content.newContent,
                            hunks: content.hunks + [finalizedHunk],
                            isBinary: content.isBinary,
                            isNewFile: content.isNewFile,
                            isDeletedFile: content.isDeletedFile,
                            statistics: content.statistics
                        )
                        currentContent = content
                    }
                }
                
                // Start new hunk
                currentHunk = parseHunkHeader(line)
                currentLines = []
                
                if let hunk = currentHunk {
                    oldLineNumber = hunk.oldStartLine
                    newLineNumber = hunk.newStartLine
                }
                
            } else if line.hasPrefix("Binary files") {
                // Handle binary files
                if var content = currentContent {
                    content = DiffContent(
                        filePath: content.filePath,
                        oldContent: content.oldContent,
                        newContent: content.newContent,
                        hunks: content.hunks,
                        isBinary: true,
                        isNewFile: content.isNewFile,
                        isDeletedFile: content.isDeletedFile,
                        statistics: content.statistics
                    )
                    currentContent = content
                }
                
            } else if line.hasPrefix(" ") {
                // Context line
                let content = String(line.dropFirst())
                let diffLine = DiffLine(
                    type: .context,
                    content: content,
                    oldLineNumber: oldLineNumber,
                    newLineNumber: newLineNumber
                )
                currentLines.append(diffLine)
                oldLineNumber += 1
                newLineNumber += 1
                
            } else if line.hasPrefix("+") {
                // Added line
                let content = String(line.dropFirst())
                let diffLine = DiffLine(
                    type: .added,
                    content: content,
                    oldLineNumber: nil,
                    newLineNumber: newLineNumber
                )
                currentLines.append(diffLine)
                newLineNumber += 1
                
            } else if line.hasPrefix("-") {
                // Removed line
                let content = String(line.dropFirst())
                let diffLine = DiffLine(
                    type: .removed,
                    content: content,
                    oldLineNumber: oldLineNumber,
                    newLineNumber: nil
                )
                currentLines.append(diffLine)
                oldLineNumber += 1
                
            } else if line.hasPrefix("\\") {
                // No newline at end of file
                let diffLine = DiffLine(
                    type: .noNewlineAtEnd,
                    content: line,
                    oldLineNumber: nil,
                    newLineNumber: nil
                )
                currentLines.append(diffLine)
            }
        }
        
        // Finalize last content
        if let content = currentContent {
            diffContents.append(finalizeContent(content, currentHunk: currentHunk, currentLines: currentLines))
        }
        
        return diffContents
    }
    
    private func parseFileHeader(_ line: String) -> DiffContent {
        let components = line.components(separatedBy: " ")
        let filePath = components.count > 3 ? components[3] : "unknown"
        
        return DiffContent(
            filePath: extractFileName(filePath),
            oldContent: "",
            newContent: "",
            hunks: [],
            isBinary: false,
            isNewFile: false,
            isDeletedFile: false,
            statistics: DiffStatistics()
        )
    }
    
    private func parseHunkHeader(_ line: String) -> DiffHunk? {
        let pattern = #"@@\s*-(\d+)(?:,(\d+))?\s*\+(\d+)(?:,(\d+))?\s*@@(.*)?"#
        let regex = try? NSRegularExpression(pattern: pattern, options: [])
        
        guard let match = regex?.firstMatch(in: line, options: [], range: NSRange(location: 0, length: line.count)) else {
            return nil
        }
        
        let oldStartLine = Int(String(line[Range(match.range(at: 1), in: line)!])) ?? 0
        let oldLineCount = match.range(at: 2).location != NSNotFound ? 
            Int(String(line[Range(match.range(at: 2), in: line)!])) ?? 1 : 1
        let newStartLine = Int(String(line[Range(match.range(at: 3), in: line)!])) ?? 0
        let newLineCount = match.range(at: 4).location != NSNotFound ? 
            Int(String(line[Range(match.range(at: 4), in: line)!])) ?? 1 : 1
        let context = match.range(at: 5).location != NSNotFound ? 
            String(line[Range(match.range(at: 5), in: line)!]) : ""
        
        return DiffHunk(
            oldStartLine: oldStartLine,
            oldLineCount: oldLineCount,
            newStartLine: newStartLine,
            newLineCount: newLineCount,
            context: context.trimmingCharacters(in: .whitespaces),
            lines: []
        )
    }
    
    private func extractFileName(_ path: String) -> String {
        if path.hasPrefix("a/") {
            return String(path.dropFirst(2))
        } else if path.hasPrefix("b/") {
            return String(path.dropFirst(2))
        }
        return path
    }
    
    private func finalizeContent(_ content: DiffContent, currentHunk: DiffHunk?, currentLines: [DiffLine]) -> DiffContent {
        var finalContent = content
        
        // Add current hunk if exists
        if let hunk = currentHunk {
            let finalizedHunk = DiffHunk(
                oldStartLine: hunk.oldStartLine,
                oldLineCount: hunk.oldLineCount,
                newStartLine: hunk.newStartLine,
                newLineCount: hunk.newLineCount,
                context: hunk.context,
                lines: currentLines
            )
            finalContent = DiffContent(
                filePath: finalContent.filePath,
                oldContent: finalContent.oldContent,
                newContent: finalContent.newContent,
                hunks: finalContent.hunks + [finalizedHunk],
                isBinary: finalContent.isBinary,
                isNewFile: finalContent.isNewFile,
                isDeletedFile: finalContent.isDeletedFile,
                statistics: finalContent.statistics
            )
        }
        
        // Calculate statistics
        let statistics = calculateStatistics(finalContent.hunks)
        
        return DiffContent(
            filePath: finalContent.filePath,
            oldContent: finalContent.oldContent,
            newContent: finalContent.newContent,
            hunks: finalContent.hunks,
            isBinary: finalContent.isBinary,
            isNewFile: finalContent.isNewFile,
            isDeletedFile: finalContent.isDeletedFile,
            statistics: statistics
        )
    }
    
    private func calculateStatistics(_ hunks: [DiffHunk]) -> DiffStatistics {
        var additions = 0
        var deletions = 0
        
        for hunk in hunks {
            for line in hunk.lines {
                switch line.type {
                case .added:
                    additions += 1
                case .removed:
                    deletions += 1
                case .context, .noNewlineAtEnd:
                    break
                }
            }
        }
        
        return DiffStatistics(additions: additions, deletions: deletions)
    }
}

extension String {
    subscript(range: NSRange) -> String {
        let start = self.index(self.startIndex, offsetBy: range.location)
        let end = self.index(start, offsetBy: range.length)
        return String(self[start..<end])
    }
}