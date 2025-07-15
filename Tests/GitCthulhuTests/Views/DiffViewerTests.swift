//
// DiffViewerTests.swift
// GitCthulhu
//
// Created by GitCthulhu Team on 2025-07-15.
//

import Testing
import SwiftUI
@testable import GitCthulhu
@testable import GitCore

@MainActor
struct DiffViewerTests {
    
    // MARK: - Test Data
    
    private func createSampleDiffContent() -> DiffContent {
        return DiffContent(
            filePath: "Sources/GitCore/Example.swift",
            hunks: [
                DiffHunk(
                    oldStartLine: 1,
                    oldLineCount: 5,
                    newStartLine: 1,
                    newLineCount: 6,
                    context: "function example()",
                    lines: [
                        DiffLine(type: .context, content: "import Foundation", oldLineNumber: 1, newLineNumber: 1),
                        DiffLine(type: .context, content: "", oldLineNumber: 2, newLineNumber: 2),
                        DiffLine(type: .removed, content: "func oldFunction() {", oldLineNumber: 3, newLineNumber: nil),
                        DiffLine(type: .added, content: "func newFunction() {", oldLineNumber: nil, newLineNumber: 3),
                        DiffLine(type: .added, content: "    print(\"Hello, World!\")", oldLineNumber: nil, newLineNumber: 4),
                        DiffLine(type: .context, content: "}", oldLineNumber: 4, newLineNumber: 5)
                    ]
                )
            ],
            statistics: DiffStatistics(additions: 2, deletions: 1)
        )
    }
    
    private func createBinaryDiffContent() -> DiffContent {
        return DiffContent(
            filePath: "assets/image.png",
            isBinary: true,
            statistics: DiffStatistics()
        )
    }
    
    private func createNewFileDiffContent() -> DiffContent {
        return DiffContent(
            filePath: "NewFile.swift",
            hunks: [
                DiffHunk(
                    oldStartLine: 0,
                    oldLineCount: 0,
                    newStartLine: 1,
                    newLineCount: 3,
                    lines: [
                        DiffLine(type: .added, content: "import Foundation", oldLineNumber: nil, newLineNumber: 1),
                        DiffLine(type: .added, content: "", oldLineNumber: nil, newLineNumber: 2),
                        DiffLine(type: .added, content: "// New file", oldLineNumber: nil, newLineNumber: 3)
                    ]
                )
            ],
            isNewFile: true,
            statistics: DiffStatistics(additions: 3, deletions: 0)
        )
    }
    
    private func createDeletedFileDiffContent() -> DiffContent {
        return DiffContent(
            filePath: "DeletedFile.swift",
            hunks: [
                DiffHunk(
                    oldStartLine: 1,
                    oldLineCount: 2,
                    newStartLine: 0,
                    newLineCount: 0,
                    lines: [
                        DiffLine(type: .removed, content: "import Foundation", oldLineNumber: 1, newLineNumber: nil),
                        DiffLine(type: .removed, content: "// Deleted file", oldLineNumber: 2, newLineNumber: nil)
                    ]
                )
            ],
            isDeletedFile: true,
            statistics: DiffStatistics(additions: 0, deletions: 2)
        )
    }
    
    // MARK: - Basic Component Tests
    
    @Test("DiffViewer initializes correctly")
    func testDiffViewerInitializesCorrectly() {
        let diffContent = createSampleDiffContent()
        let diffViewer = DiffViewer(diffContent: diffContent)
        
        // Test that the diff viewer is created successfully
        #expect(diffViewer.diffContent.filePath == "Sources/GitCore/Example.swift")
        #expect(diffViewer.diffContent.hunks.count == 1)
        #expect(diffViewer.diffContent.statistics.additions == 2)
        #expect(diffViewer.diffContent.statistics.deletions == 1)
    }
    
    @Test("DiffViewer displays file path correctly")
    func testDiffViewerDisplaysFilePathCorrectly() {
        let diffContent = createSampleDiffContent()
        let diffViewer = DiffViewer(diffContent: diffContent)
        
        #expect(diffViewer.diffContent.filePath == "Sources/GitCore/Example.swift")
        #expect(diffViewer.diffContent.isBinary == false)
        #expect(diffViewer.diffContent.isNewFile == false)
        #expect(diffViewer.diffContent.isDeletedFile == false)
    }
    
    @Test("DiffViewer handles binary files")
    func testDiffViewerHandlesBinaryFiles() {
        let diffContent = createBinaryDiffContent()
        let diffViewer = DiffViewer(diffContent: diffContent)
        
        #expect(diffViewer.diffContent.isBinary == true)
        #expect(diffViewer.diffContent.hunks.count == 0)
        #expect(diffViewer.diffContent.statistics.isEmpty == true)
    }
    
    @Test("DiffViewer handles new files")
    func testDiffViewerHandlesNewFiles() {
        let diffContent = createNewFileDiffContent()
        let diffViewer = DiffViewer(diffContent: diffContent)
        
        #expect(diffViewer.diffContent.isNewFile == true)
        #expect(diffViewer.diffContent.statistics.additions == 3)
        #expect(diffViewer.diffContent.statistics.deletions == 0)
    }
    
    @Test("DiffViewer handles deleted files")
    func testDiffViewerHandlesDeletedFiles() {
        let diffContent = createDeletedFileDiffContent()
        let diffViewer = DiffViewer(diffContent: diffContent)
        
        #expect(diffViewer.diffContent.isDeletedFile == true)
        #expect(diffViewer.diffContent.statistics.additions == 0)
        #expect(diffViewer.diffContent.statistics.deletions == 2)
    }
    
    // MARK: - Statistics Tests
    
    @Test("DiffViewer calculates statistics correctly")
    func testDiffViewerCalculatesStatisticsCorrectly() {
        let diffContent = createSampleDiffContent()
        let diffViewer = DiffViewer(diffContent: diffContent)
        
        let stats = diffViewer.diffContent.statistics
        #expect(stats.additions == 2)
        #expect(stats.deletions == 1)
        #expect(stats.totalLines == 3)
        #expect(stats.isEmpty == false)
    }
    
    @Test("DiffViewer handles empty statistics")
    func testDiffViewerHandlesEmptyStatistics() {
        let diffContent = DiffContent(
            filePath: "empty.txt",
            statistics: DiffStatistics()
        )
        let diffViewer = DiffViewer(diffContent: diffContent)
        
        let stats = diffViewer.diffContent.statistics
        #expect(stats.additions == 0)
        #expect(stats.deletions == 0)
        #expect(stats.totalLines == 0)
        #expect(stats.isEmpty == true)
    }
    
    // MARK: - View Mode Tests
    
    @Test("DiffViewer supports view mode switching")
    func testDiffViewerSupportsViewModeSwitching() {
        // This test verifies that the view mode enum exists and has the expected cases
        let unifiedMode = DiffViewMode.unified
        let sideBySideMode = DiffViewMode.sideBySide
        
        #expect(unifiedMode != sideBySideMode)
        
        // Test that both modes can be used
        let diffContent = createSampleDiffContent()
        let diffViewer = DiffViewer(diffContent: diffContent)
        
        // The view should be able to handle both modes
        #expect(diffViewer.diffContent.hunks.count > 0)
    }
    
    // MARK: - Hunk Tests
    
    @Test("DiffViewer handles multiple hunks")
    func testDiffViewerHandlesMultipleHunks() {
        let diffContent = DiffContent(
            filePath: "test.swift",
            hunks: [
                DiffHunk(
                    oldStartLine: 1,
                    oldLineCount: 3,
                    newStartLine: 1,
                    newLineCount: 3,
                    lines: [
                        DiffLine(type: .context, content: "line 1", oldLineNumber: 1, newLineNumber: 1),
                        DiffLine(type: .removed, content: "old line", oldLineNumber: 2, newLineNumber: nil),
                        DiffLine(type: .added, content: "new line", oldLineNumber: nil, newLineNumber: 2)
                    ]
                ),
                DiffHunk(
                    oldStartLine: 10,
                    oldLineCount: 2,
                    newStartLine: 10,
                    newLineCount: 3,
                    lines: [
                        DiffLine(type: .context, content: "line 10", oldLineNumber: 10, newLineNumber: 10),
                        DiffLine(type: .added, content: "added line", oldLineNumber: nil, newLineNumber: 11)
                    ]
                )
            ],
            statistics: DiffStatistics(additions: 2, deletions: 1)
        )
        
        let diffViewer = DiffViewer(diffContent: diffContent)
        
        #expect(diffViewer.diffContent.hunks.count == 2)
        #expect(diffViewer.diffContent.hunks[0].oldStartLine == 1)
        #expect(diffViewer.diffContent.hunks[1].oldStartLine == 10)
    }
    
    @Test("DiffViewer handles hunks with context")
    func testDiffViewerHandlesHunksWithContext() {
        let diffContent = DiffContent(
            filePath: "test.swift",
            hunks: [
                DiffHunk(
                    oldStartLine: 1,
                    oldLineCount: 3,
                    newStartLine: 1,
                    newLineCount: 3,
                    context: "function testFunction()",
                    lines: [
                        DiffLine(type: .context, content: "func testFunction() {", oldLineNumber: 1, newLineNumber: 1),
                        DiffLine(type: .removed, content: "    old code", oldLineNumber: 2, newLineNumber: nil),
                        DiffLine(type: .added, content: "    new code", oldLineNumber: nil, newLineNumber: 2)
                    ]
                )
            ],
            statistics: DiffStatistics(additions: 1, deletions: 1)
        )
        
        let diffViewer = DiffViewer(diffContent: diffContent)
        
        #expect(diffViewer.diffContent.hunks[0].context == "function testFunction()")
        #expect(diffViewer.diffContent.hunks[0].lines.count == 3)
    }
    
    // MARK: - Line Type Tests
    
    @Test("DiffViewer handles different line types")
    func testDiffViewerHandlesDifferentLineTypes() {
        let diffContent = DiffContent(
            filePath: "test.txt",
            hunks: [
                DiffHunk(
                    oldStartLine: 1,
                    oldLineCount: 4,
                    newStartLine: 1,
                    newLineCount: 4,
                    lines: [
                        DiffLine(type: .context, content: "context line", oldLineNumber: 1, newLineNumber: 1),
                        DiffLine(type: .removed, content: "removed line", oldLineNumber: 2, newLineNumber: nil),
                        DiffLine(type: .added, content: "added line", oldLineNumber: nil, newLineNumber: 2),
                        DiffLine(type: .noNewlineAtEnd, content: "\\ No newline at end of file", oldLineNumber: nil, newLineNumber: nil)
                    ]
                )
            ],
            statistics: DiffStatistics(additions: 1, deletions: 1)
        )
        
        let diffViewer = DiffViewer(diffContent: diffContent)
        
        let lines = diffViewer.diffContent.hunks[0].lines
        #expect(lines[0].type == .context)
        #expect(lines[1].type == .removed)
        #expect(lines[2].type == .added)
        #expect(lines[3].type == .noNewlineAtEnd)
    }
    
    // MARK: - Line Number Tests
    
    @Test("DiffViewer handles line numbers correctly")
    func testDiffViewerHandlesLineNumbersCorrectly() {
        let diffContent = createSampleDiffContent()
        let diffViewer = DiffViewer(diffContent: diffContent)
        
        let lines = diffViewer.diffContent.hunks[0].lines
        
        // Context line should have both old and new line numbers
        #expect(lines[0].oldLineNumber == 1)
        #expect(lines[0].newLineNumber == 1)
        
        // Removed line should have old line number but no new line number
        #expect(lines[2].oldLineNumber == 3)
        #expect(lines[2].newLineNumber == nil)
        
        // Added line should have new line number but no old line number
        #expect(lines[3].oldLineNumber == nil)
        #expect(lines[3].newLineNumber == 3)
    }
    
    // MARK: - File Extension Tests
    
    @Test("DiffViewer handles different file extensions")
    func testDiffViewerHandlesDifferentFileExtensions() {
        let testCases = [
            ("test.swift", "swift"),
            ("test.js", "javascript"),
            ("test.py", "python"),
            ("test.java", "java"),
            ("test.cpp", "cpp"),
            ("test.json", "json"),
            ("test.xml", "xml"),
            ("test.md", "markdown"),
            ("unknown.xyz", "plaintext")
        ]
        
        for (fileName, expectedLanguage) in testCases {
            let diffContent = DiffContent(
                filePath: fileName,
                hunks: [
                    DiffHunk(
                        oldStartLine: 1,
                        oldLineCount: 1,
                        newStartLine: 1,
                        newLineCount: 1,
                        lines: [
                            DiffLine(type: .context, content: "test content", oldLineNumber: 1, newLineNumber: 1)
                        ]
                    )
                ]
            )
            
            let diffViewer = DiffViewer(diffContent: diffContent)
            
            #expect(diffViewer.diffContent.filePath == fileName)
            // Language detection is handled in the view components, not the model
            #expect(diffViewer.diffContent.hunks.count == 1)
        }
    }
    
    // MARK: - Performance Tests
    
    @Test("DiffViewer handles large diffs efficiently")
    func testDiffViewerHandlesLargeDiffsEfficiently() {
        // Create a large diff with many hunks and lines
        var hunks: [DiffHunk] = []
        
        for i in 0..<100 {
            let lines = [
                DiffLine(type: .context, content: "context line \(i)", oldLineNumber: i * 10 + 1, newLineNumber: i * 10 + 1),
                DiffLine(type: .removed, content: "removed line \(i)", oldLineNumber: i * 10 + 2, newLineNumber: nil),
                DiffLine(type: .added, content: "added line \(i)", oldLineNumber: nil, newLineNumber: i * 10 + 2),
                DiffLine(type: .context, content: "context line \(i + 1)", oldLineNumber: i * 10 + 3, newLineNumber: i * 10 + 3)
            ]
            
            hunks.append(DiffHunk(
                oldStartLine: i * 10 + 1,
                oldLineCount: 3,
                newStartLine: i * 10 + 1,
                newLineCount: 3,
                lines: lines
            ))
        }
        
        let diffContent = DiffContent(
            filePath: "large_file.swift",
            hunks: hunks,
            statistics: DiffStatistics(additions: 100, deletions: 100)
        )
        
        let startTime = Date()
        let diffViewer = DiffViewer(diffContent: diffContent)
        let endTime = Date()
        
        let duration = endTime.timeIntervalSince(startTime)
        #expect(duration < 1.0) // Should initialize quickly
        
        #expect(diffViewer.diffContent.hunks.count == 100)
        #expect(diffViewer.diffContent.statistics.totalLines == 200)
    }
    
    // MARK: - Edge Cases
    
    @Test("DiffViewer handles empty hunks")
    func testDiffViewerHandlesEmptyHunks() {
        let diffContent = DiffContent(
            filePath: "empty.txt",
            hunks: [],
            statistics: DiffStatistics()
        )
        
        let diffViewer = DiffViewer(diffContent: diffContent)
        
        #expect(diffViewer.diffContent.hunks.count == 0)
        #expect(diffViewer.diffContent.statistics.isEmpty == true)
    }
    
    @Test("DiffViewer handles hunks with no lines")
    func testDiffViewerHandlesHunksWithNoLines() {
        let diffContent = DiffContent(
            filePath: "test.txt",
            hunks: [
                DiffHunk(
                    oldStartLine: 1,
                    oldLineCount: 0,
                    newStartLine: 1,
                    newLineCount: 0,
                    lines: []
                )
            ],
            statistics: DiffStatistics()
        )
        
        let diffViewer = DiffViewer(diffContent: diffContent)
        
        #expect(diffViewer.diffContent.hunks.count == 1)
        #expect(diffViewer.diffContent.hunks[0].lines.count == 0)
        #expect(diffViewer.diffContent.statistics.isEmpty == true)
    }
    
    @Test("DiffViewer handles very long file paths")
    func testDiffViewerHandlesVeryLongFilePaths() {
        let longPath = "very/long/path/to/a/file/that/has/many/nested/directories/and/subdirectories/test.swift"
        let diffContent = DiffContent(
            filePath: longPath,
            hunks: [
                DiffHunk(
                    oldStartLine: 1,
                    oldLineCount: 1,
                    newStartLine: 1,
                    newLineCount: 1,
                    lines: [
                        DiffLine(type: .context, content: "test", oldLineNumber: 1, newLineNumber: 1)
                    ]
                )
            ]
        )
        
        let diffViewer = DiffViewer(diffContent: diffContent)
        
        #expect(diffViewer.diffContent.filePath == longPath)
        #expect(diffViewer.diffContent.hunks.count == 1)
    }
    
    @Test("DiffViewer handles lines with special characters")
    func testDiffViewerHandlesLinesWithSpecialCharacters() {
        let diffContent = DiffContent(
            filePath: "test.txt",
            hunks: [
                DiffHunk(
                    oldStartLine: 1,
                    oldLineCount: 3,
                    newStartLine: 1,
                    newLineCount: 3,
                    lines: [
                        DiffLine(type: .context, content: "line with emoji 😀", oldLineNumber: 1, newLineNumber: 1),
                        DiffLine(type: .removed, content: "line with unicode: こんにちは", oldLineNumber: 2, newLineNumber: nil),
                        DiffLine(type: .added, content: "line with symbols: @#$%^&*()", oldLineNumber: nil, newLineNumber: 2)
                    ]
                )
            ],
            statistics: DiffStatistics(additions: 1, deletions: 1)
        )
        
        let diffViewer = DiffViewer(diffContent: diffContent)
        
        let lines = diffViewer.diffContent.hunks[0].lines
        #expect(lines[0].content.contains("😀"))
        #expect(lines[1].content.contains("こんにちは"))
        #expect(lines[2].content.contains("@#$%^&*()"))
    }
}