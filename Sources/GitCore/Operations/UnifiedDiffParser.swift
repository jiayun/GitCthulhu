//
// UnifiedDiffParser.swift
// GitCthulhu
//
// Created by GitCthulhu Team on 2025-07-17.
//

import Foundation

/// Parser for Git unified diff format
public class UnifiedDiffParser {
    public init() {}

    /// Parse unified diff output into GitDiff objects
    public func parse(_ diffOutput: String) throws -> [GitDiff] {
        let lines = diffOutput.components(separatedBy: .newlines)
        guard !lines.isEmpty else { return [] }

        var diffs: [GitDiff] = []
        var currentDiff: GitDiff?
        var currentChunk: GitDiffChunk?
        var chunkLines: [GitDiffLine] = []
        var headerLines: [String] = []
        var oldLineNumber = 0
        var newLineNumber = 0

        var index = 0
        while index < lines.count {
            let line = lines[index]

            if line.hasPrefix("diff --git") {
                // Save previous diff if exists
                if var diff = currentDiff {
                    if var chunk = currentChunk {
                        chunk = chunk.withLines(chunkLines)
                        diff = GitDiff(
                            filePath: diff.filePath,
                            oldPath: diff.oldPath,
                            changeType: diff.changeType,
                            chunks: diff.chunks + [chunk],
                            isBinary: diff.isBinary,
                            isNew: diff.isNew,
                            isDeleted: diff.isDeleted,
                            isRenamed: diff.isRenamed,
                            oldMode: diff.oldMode,
                            newMode: diff.newMode,
                            headerLines: diff.headerLines,
                            rawDiff: diff.rawDiff
                        )
                    }
                    diffs.append(diff)
                }

                // Start new diff
                let paths = parseGitDiffHeader(line)
                currentDiff = GitDiff(
                    filePath: paths.newPath,
                    oldPath: paths.oldPath != paths.newPath ? paths.oldPath : nil,
                    changeType: .modified,
                    headerLines: [line]
                )
                currentChunk = nil
                chunkLines = []
                headerLines = [line]

            } else if line.hasPrefix("index ") {
                // Git index information
                headerLines.append(line)

            } else if line.hasPrefix("--- ") || line.hasPrefix("+++ ") {
                // File headers
                headerLines.append(line)
                if var diff = currentDiff {
                    let updatedDiff = updateDiffWithFileHeader(diff, line: line)
                    currentDiff = updatedDiff
                }

            } else if line.hasPrefix("@@ ") {
                // Save previous chunk if exists
                if var chunk = currentChunk {
                    chunk = chunk.withLines(chunkLines)
                    if var diff = currentDiff {
                        currentDiff = GitDiff(
                            filePath: diff.filePath,
                            oldPath: diff.oldPath,
                            changeType: diff.changeType,
                            chunks: diff.chunks + [chunk],
                            isBinary: diff.isBinary,
                            isNew: diff.isNew,
                            isDeleted: diff.isDeleted,
                            isRenamed: diff.isRenamed,
                            oldMode: diff.oldMode,
                            newMode: diff.newMode,
                            headerLines: diff.headerLines,
                            rawDiff: diff.rawDiff
                        )
                    }
                }

                // Start new chunk
                if let chunk = GitDiffChunk.parseHeader(line) {
                    currentChunk = chunk
                    chunkLines = []
                    oldLineNumber = chunk.oldStart
                    newLineNumber = chunk.newStart
                }

            } else if line.hasPrefix("Binary files") {
                // Binary file
                if var diff = currentDiff {
                    currentDiff = GitDiff(
                        filePath: diff.filePath,
                        oldPath: diff.oldPath,
                        changeType: diff.changeType,
                        chunks: [],
                        isBinary: true,
                        isNew: diff.isNew,
                        isDeleted: diff.isDeleted,
                        isRenamed: diff.isRenamed,
                        oldMode: diff.oldMode,
                        newMode: diff.newMode,
                        headerLines: diff.headerLines + [line],
                        rawDiff: diff.rawDiff
                    )
                }

            } else if line.hasPrefix("new file mode") {
                // New file
                if var diff = currentDiff {
                    let mode = String(line.dropFirst("new file mode ".count))
                    currentDiff = GitDiff(
                        filePath: diff.filePath,
                        oldPath: diff.oldPath,
                        changeType: .added,
                        chunks: diff.chunks,
                        isBinary: diff.isBinary,
                        isNew: true,
                        isDeleted: diff.isDeleted,
                        isRenamed: diff.isRenamed,
                        oldMode: diff.oldMode,
                        newMode: mode,
                        headerLines: diff.headerLines + [line],
                        rawDiff: diff.rawDiff
                    )
                }

            } else if line.hasPrefix("deleted file mode") {
                // Deleted file
                if var diff = currentDiff {
                    let mode = String(line.dropFirst("deleted file mode ".count))
                    currentDiff = GitDiff(
                        filePath: diff.filePath,
                        oldPath: diff.oldPath,
                        changeType: .deleted,
                        chunks: diff.chunks,
                        isBinary: diff.isBinary,
                        isNew: diff.isNew,
                        isDeleted: true,
                        isRenamed: diff.isRenamed,
                        oldMode: mode,
                        newMode: diff.newMode,
                        headerLines: diff.headerLines + [line],
                        rawDiff: diff.rawDiff
                    )
                }

            } else if line.hasPrefix("rename from ") || line.hasPrefix("rename to ") {
                // Renamed file
                if var diff = currentDiff {
                    currentDiff = GitDiff(
                        filePath: diff.filePath,
                        oldPath: diff.oldPath,
                        changeType: .renamed,
                        chunks: diff.chunks,
                        isBinary: diff.isBinary,
                        isNew: diff.isNew,
                        isDeleted: diff.isDeleted,
                        isRenamed: true,
                        oldMode: diff.oldMode,
                        newMode: diff.newMode,
                        headerLines: diff.headerLines + [line],
                        rawDiff: diff.rawDiff
                    )
                }

            } else if !line.isEmpty, currentChunk != nil {
                // Content line
                let diffLine = parseDiffLine(line, oldLineNumber: &oldLineNumber, newLineNumber: &newLineNumber)
                chunkLines.append(diffLine)
            }

            index += 1
        }

        // Save last diff
        if var diff = currentDiff {
            if var chunk = currentChunk {
                chunk = chunk.withLines(chunkLines)
                diff = GitDiff(
                    filePath: diff.filePath,
                    oldPath: diff.oldPath,
                    changeType: diff.changeType,
                    chunks: diff.chunks + [chunk],
                    isBinary: diff.isBinary,
                    isNew: diff.isNew,
                    isDeleted: diff.isDeleted,
                    isRenamed: diff.isRenamed,
                    oldMode: diff.oldMode,
                    newMode: diff.newMode,
                    headerLines: diff.headerLines,
                    rawDiff: diff.rawDiff
                )
            }
            diffs.append(diff)
        }

        return diffs
    }

    // MARK: - Private Parsing Methods

    private func parseGitDiffHeader(_ line: String) -> (oldPath: String, newPath: String) {
        // Format: diff --git a/path b/path
        let components = line.components(separatedBy: " ")
        guard components.count >= 4 else {
            return ("", "")
        }

        let oldPath = String(components[2].dropFirst(2)) // Remove "a/"
        let newPath = String(components[3].dropFirst(2)) // Remove "b/"

        return (oldPath, newPath)
    }

    private func updateDiffWithFileHeader(_ diff: GitDiff, line: String) -> GitDiff {
        var changeType = diff.changeType
        var isNew = diff.isNew
        var isDeleted = diff.isDeleted
        var oldPath = diff.oldPath

        if line.hasPrefix("--- /dev/null") {
            changeType = .added
            isNew = true
        } else if line.hasPrefix("+++ /dev/null") {
            changeType = .deleted
            isDeleted = true
        } else if line.hasPrefix("--- ") {
            let path = extractPathFromFileHeader(line)
            if oldPath == nil, path != diff.filePath {
                oldPath = path
            }
        }

        return GitDiff(
            filePath: diff.filePath,
            oldPath: oldPath,
            changeType: changeType,
            chunks: diff.chunks,
            isBinary: diff.isBinary,
            isNew: isNew,
            isDeleted: isDeleted,
            isRenamed: diff.isRenamed,
            oldMode: diff.oldMode,
            newMode: diff.newMode,
            headerLines: diff.headerLines + [line],
            rawDiff: diff.rawDiff
        )
    }

    private func extractPathFromFileHeader(_ line: String) -> String {
        // Remove "--- " or "+++ " prefix and optional timestamp
        let prefixRemoved = String(line.dropFirst(4))
        let components = prefixRemoved.components(separatedBy: "\t")
        return components.first?.trimmingCharacters(in: .whitespaces) ?? ""
    }

    private func parseDiffLine(
        _ line: String,
        oldLineNumber: inout Int,
        newLineNumber: inout Int
    ) -> GitDiffLine {
        guard !line.isEmpty else {
            return GitDiffLine(
                type: .context,
                content: "",
                rawLine: line
            )
        }

        let prefix = String(line.prefix(1))
        let content = String(line.dropFirst())

        switch prefix {
        case " ":
            // Context line
            let diffLine = GitDiffLine(
                type: .context,
                oldLineNumber: oldLineNumber,
                newLineNumber: newLineNumber,
                content: content,
                rawLine: line
            )
            oldLineNumber += 1
            newLineNumber += 1
            return diffLine

        case "+":
            // Addition
            let diffLine = GitDiffLine(
                type: .addition,
                oldLineNumber: nil,
                newLineNumber: newLineNumber,
                content: content,
                rawLine: line
            )
            newLineNumber += 1
            return diffLine

        case "-":
            // Deletion
            let diffLine = GitDiffLine(
                type: .deletion,
                oldLineNumber: oldLineNumber,
                newLineNumber: nil,
                content: content,
                rawLine: line
            )
            oldLineNumber += 1
            return diffLine

        case "\\":
            // No newline marker
            return GitDiffLine(
                type: .noNewline,
                content: content,
                rawLine: line
            )

        default:
            // Treat as context by default
            let diffLine = GitDiffLine(
                type: .context,
                oldLineNumber: oldLineNumber,
                newLineNumber: newLineNumber,
                content: line,
                rawLine: line
            )
            oldLineNumber += 1
            newLineNumber += 1
            return diffLine
        }
    }
}

// MARK: - Error Types

public extension UnifiedDiffParser {
    enum ParseError: Error, LocalizedError {
        case invalidDiffFormat(String)
        case malformedChunkHeader(String)
        case unexpectedContent(String)

        public var errorDescription: String? {
            switch self {
            case let .invalidDiffFormat(details):
                "Invalid diff format: \(details)"
            case let .malformedChunkHeader(header):
                "Malformed chunk header: \(header)"
            case let .unexpectedContent(content):
                "Unexpected content: \(content)"
            }
        }
    }
}
