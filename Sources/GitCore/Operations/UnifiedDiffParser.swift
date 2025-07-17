//
// UnifiedDiffParser.swift
// GitCthulhu
//
// Created by GitCthulhu Team on 2025-07-17.
//

import Foundation

/// Parser for Git unified diff format
public class UnifiedDiffParser {
    private struct ParserState {
        var diffs: [GitDiff] = []
        var currentDiff: GitDiff?
        var currentChunk: GitDiffChunk?
        var chunkLines: [GitDiffLine] = []
        var oldLineNumber = 0
        var newLineNumber = 0
    }

    public init() {}

    /// Parse unified diff output into GitDiff objects
    public func parse(_ diffOutput: String) throws -> [GitDiff] {
        let lines = diffOutput.trimmingCharacters(in: .newlines).components(separatedBy: .newlines)
        guard !lines.isEmpty else { return [] }

        var state = ParserState()

        for line in lines {
            if line.isEmpty { continue }
            processLine(line, state: &state)
        }

        finalizeCurrentDiff(state: &state)

        return state.diffs
    }

    private func processLine(_ line: String, state: inout ParserState) {
        if line.hasPrefix("diff --git") {
            finalizeCurrentDiff(state: &state)
            startNewDiff(line: line, state: &state)
        } else if line.hasPrefix("index ") {
            updateDiffHeader(line: line, state: &state)
        } else if line.hasPrefix("--- ") || line.hasPrefix("+++ ") {
            updateDiffWithFileHeader(line: line, state: &state)
        } else if line.hasPrefix("@@ ") {
            finalizeCurrentChunk(state: &state)
            startNewChunk(line: line, state: &state)
        } else if line.hasPrefix("Binary files") {
            markDiffAsBinary(line: line, state: &state)
        } else if line.hasPrefix("new file mode") {
            markDiffAsNew(line: line, state: &state)
        } else if line.hasPrefix("deleted file mode") {
            markDiffAsDeleted(line: line, state: &state)
        } else if line.hasPrefix("rename from ") || line.hasPrefix("rename to ") {
            markDiffAsRenamed(line: line, state: &state)
        } else if !line.isEmpty, state.currentChunk != nil {
            parseAndAddDiffLine(line, state: &state)
        }
    }

    // MARK: - State Management

    private func startNewDiff(line: String, state: inout ParserState) {
        let paths = parseGitDiffHeader(line)
        state.currentDiff = GitDiff(
            filePath: paths.newPath,
            oldPath: paths.oldPath != paths.newPath ? paths.oldPath : nil,
            changeType: .modified,
            headerLines: [line]
        )
        state.currentChunk = nil
        state.chunkLines = []
    }

    private func finalizeCurrentChunk(state: inout ParserState) {
        guard var chunk = state.currentChunk else { return }

        chunk = chunk.withLines(state.chunkLines)
        state.currentDiff?.chunks.append(chunk)
        state.chunkLines = []
        state.currentChunk = nil
    }

    private func finalizeCurrentDiff(state: inout ParserState) {
        finalizeCurrentChunk(state: &state)
        if let diff = state.currentDiff {
            state.diffs.append(diff)
        }
        state.currentDiff = nil
    }

    private func startNewChunk(line: String, state: inout ParserState) {
        if let chunk = GitDiffChunk.parseHeader(line) {
            state.currentChunk = chunk
            state.oldLineNumber = chunk.oldStart
            state.newLineNumber = chunk.newStart
        }
    }

    // MARK: - Line Processing Methods

    private func updateDiffHeader(line: String, state: inout ParserState) {
        state.currentDiff?.headerLines.append(line)
    }

    private func updateDiffWithFileHeader(line: String, state: inout ParserState) {
        guard var diff = state.currentDiff else { return }

        if line.hasPrefix("--- /dev/null") {
            diff.changeType = .added
            diff.isNew = true
        } else if line.hasPrefix("+++ /dev/null") {
            diff.changeType = .deleted
            diff.isDeleted = true
        } else if line.hasPrefix("--- ") {
            let path = extractPathFromFileHeader(line)
            if diff.oldPath == nil, path != diff.filePath {
                diff.oldPath = path
            }
        }

        diff.headerLines.append(line)
        state.currentDiff = diff
    }

    private func markDiffAsBinary(line: String, state: inout ParserState) {
        state.currentDiff?.isBinary = true
        state.currentDiff?.headerLines.append(line)
    }

    private func markDiffAsNew(line: String, state: inout ParserState) {
        state.currentDiff?.changeType = .added
        state.currentDiff?.isNew = true
        if let mode = line.split(separator: " ").last {
            state.currentDiff?.newMode = String(mode)
        }
        state.currentDiff?.headerLines.append(line)
    }

    private func markDiffAsDeleted(line: String, state: inout ParserState) {
        state.currentDiff?.changeType = .deleted
        state.currentDiff?.isDeleted = true
        if let mode = line.split(separator: " ").last {
            state.currentDiff?.oldMode = String(mode)
        }
        state.currentDiff?.headerLines.append(line)
    }

    private func markDiffAsRenamed(line: String, state: inout ParserState) {
        state.currentDiff?.changeType = .renamed
        state.currentDiff?.isRenamed = true
        state.currentDiff?.headerLines.append(line)
    }

    private func parseAndAddDiffLine(_ line: String, state: inout ParserState) {
        let diffLine = parseDiffLine(line, oldLineNumber: &state.oldLineNumber, newLineNumber: &state.newLineNumber)
        state.chunkLines.append(diffLine)
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
            return GitDiffLine(type: .context, content: "", rawLine: line)
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
            return GitDiffLine(type: .noNewline, content: content, rawLine: line)

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
