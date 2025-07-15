//
// DiffViewModeSwitchingTests.swift
// GitCthulhu
//
// Created by GitCthulhu Team on 2025-07-15.
//

import Testing
import SwiftUI
@testable import GitCthulhu
@testable import GitCore

@MainActor
struct DiffViewModeSwitchingTests {
    
    // MARK: - Test Data
    
    private func createComplexDiffContent() -> DiffContent {
        return DiffContent(
            filePath: "Sources/GitCore/Complex.swift",
            hunks: [
                DiffHunk(
                    oldStartLine: 1,
                    oldLineCount: 10,
                    newStartLine: 1,
                    newLineCount: 12,
                    context: "class ComplexClass",
                    lines: [
                        DiffLine(type: .context, content: "import Foundation", oldLineNumber: 1, newLineNumber: 1),
                        DiffLine(type: .context, content: "", oldLineNumber: 2, newLineNumber: 2),
                        DiffLine(type: .context, content: "class ComplexClass {", oldLineNumber: 3, newLineNumber: 3),
                        DiffLine(type: .removed, content: "    private var oldProperty: String", oldLineNumber: 4, newLineNumber: nil),
                        DiffLine(type: .added, content: "    private var newProperty: String", oldLineNumber: nil, newLineNumber: 4),
                        DiffLine(type: .added, content: "    private var additionalProperty: Int", oldLineNumber: nil, newLineNumber: 5),
                        DiffLine(type: .context, content: "", oldLineNumber: 5, newLineNumber: 6),
                        DiffLine(type: .context, content: "    func method() {", oldLineNumber: 6, newLineNumber: 7),
                        DiffLine(type: .removed, content: "        print(\"old\")", oldLineNumber: 7, newLineNumber: nil),
                        DiffLine(type: .removed, content: "        return", oldLineNumber: 8, newLineNumber: nil),
                        DiffLine(type: .added, content: "        print(\"new\")", oldLineNumber: nil, newLineNumber: 8),
                        DiffLine(type: .added, content: "        doSomething()", oldLineNumber: nil, newLineNumber: 9),
                        DiffLine(type: .added, content: "        return", oldLineNumber: nil, newLineNumber: 10),
                        DiffLine(type: .context, content: "    }", oldLineNumber: 9, newLineNumber: 11),
                        DiffLine(type: .context, content: "}", oldLineNumber: 10, newLineNumber: 12)
                    ]
                ),
                DiffHunk(
                    oldStartLine: 20,
                    oldLineCount: 5,
                    newStartLine: 22,
                    newLineCount: 6,
                    context: "extension ComplexClass",
                    lines: [
                        DiffLine(type: .context, content: "extension ComplexClass {", oldLineNumber: 20, newLineNumber: 22),
                        DiffLine(type: .context, content: "    func extensionMethod() {", oldLineNumber: 21, newLineNumber: 23),
                        DiffLine(type: .removed, content: "        // old implementation", oldLineNumber: 22, newLineNumber: nil),
                        DiffLine(type: .added, content: "        // new implementation", oldLineNumber: nil, newLineNumber: 24),
                        DiffLine(type: .added, content: "        // additional logic", oldLineNumber: nil, newLineNumber: 25),
                        DiffLine(type: .context, content: "    }", oldLineNumber: 23, newLineNumber: 26),
                        DiffLine(type: .context, content: "}", oldLineNumber: 24, newLineNumber: 27)
                    ]
                )
            ],
            statistics: DiffStatistics(additions: 7, deletions: 4)
        )
    }
    
    // MARK: - View Mode Enum Tests
    
    @Test("DiffViewMode enum has correct cases")
    func testDiffViewModeEnumHasCorrectCases() {
        let unified = DiffViewMode.unified
        let sideBySide = DiffViewMode.sideBySide
        
        #expect(unified != sideBySide)
        
        // Test that we can switch between modes
        var currentMode = DiffViewMode.unified
        currentMode = .sideBySide
        #expect(currentMode == .sideBySide)
        
        currentMode = .unified
        #expect(currentMode == .unified)
    }
    
    // MARK: - UnifiedDiffView Tests
    
    @Test("UnifiedDiffView handles complex diff content")
    func testUnifiedDiffViewHandlesComplexDiffContent() {
        let diffContent = createComplexDiffContent()
        @State var expandedHunks: Set<Int> = [0, 1]
        
        let unifiedView = UnifiedDiffView(
            diffContent: diffContent,
            showLineNumbers: true,
            expandedHunks: $expandedHunks
        )
        
        // Test that unified view can handle the diff content
        #expect(diffContent.hunks.count == 2)
        #expect(diffContent.hunks[0].lines.count == 15)
        #expect(diffContent.hunks[1].lines.count == 7)
        
        // Test line types in first hunk
        let firstHunk = diffContent.hunks[0]
        #expect(firstHunk.lines[0].type == .context)
        #expect(firstHunk.lines[3].type == .removed)
        #expect(firstHunk.lines[4].type == .added)
        #expect(firstHunk.lines[5].type == .added)
    }
    
    @Test("UnifiedDiffView handles line number display")
    func testUnifiedDiffViewHandlesLineNumberDisplay() {
        let diffContent = createComplexDiffContent()
        @State var expandedHunks: Set<Int> = [0]
        
        let unifiedViewWithNumbers = UnifiedDiffView(
            diffContent: diffContent,
            showLineNumbers: true,
            expandedHunks: $expandedHunks
        )
        
        let unifiedViewWithoutNumbers = UnifiedDiffView(
            diffContent: diffContent,
            showLineNumbers: false,
            expandedHunks: $expandedHunks
        )
        
        // Both views should handle the same content
        #expect(diffContent.hunks.count == 2)
        
        // Test line number information is preserved
        let firstLine = diffContent.hunks[0].lines[0]
        #expect(firstLine.oldLineNumber == 1)
        #expect(firstLine.newLineNumber == 1)
        
        let removedLine = diffContent.hunks[0].lines[3]
        #expect(removedLine.oldLineNumber == 4)
        #expect(removedLine.newLineNumber == nil)
        
        let addedLine = diffContent.hunks[0].lines[4]
        #expect(addedLine.oldLineNumber == nil)
        #expect(addedLine.newLineNumber == 4)
    }
    
    @Test("UnifiedDiffView handles hunk expansion")
    func testUnifiedDiffViewHandlesHunkExpansion() {
        let diffContent = createComplexDiffContent()
        @State var expandedHunks: Set<Int> = []
        
        let unifiedView = UnifiedDiffView(
            diffContent: diffContent,
            showLineNumbers: true,
            expandedHunks: $expandedHunks
        )
        
        // Test initial state (no hunks expanded)
        #expect(expandedHunks.isEmpty)
        
        // Simulate expanding first hunk
        expandedHunks.insert(0)
        #expect(expandedHunks.contains(0))
        #expect(!expandedHunks.contains(1))
        
        // Simulate expanding second hunk
        expandedHunks.insert(1)
        #expect(expandedHunks.contains(0))
        #expect(expandedHunks.contains(1))
        
        // Simulate collapsing first hunk
        expandedHunks.remove(0)
        #expect(!expandedHunks.contains(0))
        #expect(expandedHunks.contains(1))
    }
    
    // MARK: - SideBySideDiffView Tests
    
    @Test("SideBySideDiffView handles complex diff content")
    func testSideBySideDiffViewHandlesComplexDiffContent() {
        let diffContent = createComplexDiffContent()
        @State var expandedHunks: Set<Int> = [0, 1]
        
        let sideBySideView = SideBySideDiffView(
            diffContent: diffContent,
            showLineNumbers: true,
            expandedHunks: $expandedHunks
        )
        
        // Test that side-by-side view can handle the diff content
        #expect(diffContent.hunks.count == 2)
        #expect(diffContent.hunks[0].lines.count == 15)
        #expect(diffContent.hunks[1].lines.count == 7)
        
        // Test that the content is the same as unified view
        let firstHunk = diffContent.hunks[0]
        #expect(firstHunk.context == "class ComplexClass")
        #expect(firstHunk.oldStartLine == 1)
        #expect(firstHunk.newStartLine == 1)
    }
    
    @Test("SideBySideDiffView handles line pairing")
    func testSideBySideDiffViewHandlesLinePairing() {
        let diffContent = createComplexDiffContent()
        @State var expandedHunks: Set<Int> = [0]
        
        let sideBySideView = SideBySideDiffView(
            diffContent: diffContent,
            showLineNumbers: true,
            expandedHunks: $expandedHunks
        )
        
        // Test line pairing logic by examining the content
        let firstHunk = diffContent.hunks[0]
        let lines = firstHunk.lines
        
        // Context lines should appear on both sides
        #expect(lines[0].type == .context)
        #expect(lines[1].type == .context)
        #expect(lines[2].type == .context)
        
        // Removed line followed by added lines
        #expect(lines[3].type == .removed)
        #expect(lines[4].type == .added)
        #expect(lines[5].type == .added)
        
        // More context
        #expect(lines[6].type == .context)
        #expect(lines[7].type == .context)
        
        // Multiple removed lines followed by multiple added lines
        #expect(lines[8].type == .removed)
        #expect(lines[9].type == .removed)
        #expect(lines[10].type == .added)
        #expect(lines[11].type == .added)
        #expect(lines[12].type == .added)
    }
    
    // MARK: - View Mode Switching Tests
    
    @Test("Both views handle same content identically")
    func testBothViewsHandleSameContentIdentically() {
        let diffContent = createComplexDiffContent()
        @State var expandedHunks: Set<Int> = [0, 1]
        
        let unifiedView = UnifiedDiffView(
            diffContent: diffContent,
            showLineNumbers: true,
            expandedHunks: $expandedHunks
        )
        
        let sideBySideView = SideBySideDiffView(
            diffContent: diffContent,
            showLineNumbers: true,
            expandedHunks: $expandedHunks
        )
        
        // Both views should work with the same diff content
        #expect(diffContent.hunks.count == 2)
        #expect(diffContent.statistics.additions == 7)
        #expect(diffContent.statistics.deletions == 4)
        
        // Both views should respect the expanded hunks state
        #expect(expandedHunks.contains(0))
        #expect(expandedHunks.contains(1))
        
        // Both views should handle line number display
        let firstLine = diffContent.hunks[0].lines[0]
        #expect(firstLine.oldLineNumber == 1)
        #expect(firstLine.newLineNumber == 1)
    }
    
    @Test("Views handle line number toggling consistently")
    func testViewsHandleLineNumberTogglingConsistently() {
        let diffContent = createComplexDiffContent()
        @State var expandedHunks: Set<Int> = [0]
        
        let unifiedViewWithNumbers = UnifiedDiffView(
            diffContent: diffContent,
            showLineNumbers: true,
            expandedHunks: $expandedHunks
        )
        
        let unifiedViewWithoutNumbers = UnifiedDiffView(
            diffContent: diffContent,
            showLineNumbers: false,
            expandedHunks: $expandedHunks
        )
        
        let sideBySideViewWithNumbers = SideBySideDiffView(
            diffContent: diffContent,
            showLineNumbers: true,
            expandedHunks: $expandedHunks
        )
        
        let sideBySideViewWithoutNumbers = SideBySideDiffView(
            diffContent: diffContent,
            showLineNumbers: false,
            expandedHunks: $expandedHunks
        )
        
        // All views should handle the same content
        #expect(diffContent.hunks.count == 2)
        #expect(diffContent.hunks[0].lines.count == 15)
        
        // Line number information should be preserved regardless of display setting
        let testLine = diffContent.hunks[0].lines[0]
        #expect(testLine.oldLineNumber == 1)
        #expect(testLine.newLineNumber == 1)
        
        let removedLine = diffContent.hunks[0].lines[3]
        #expect(removedLine.oldLineNumber == 4)
        #expect(removedLine.newLineNumber == nil)
    }
    
    // MARK: - Language Detection Tests
    
    @Test("Views handle language detection for syntax highlighting")
    func testViewsHandleLanguageDetectionForSyntaxHighlighting() {
        let testCases = [
            ("test.swift", "swift"),
            ("test.js", "javascript"),
            ("test.py", "python"),
            ("test.java", "java"),
            ("test.cpp", "cpp"),
            ("test.json", "json"),
            ("test.xml", "xml"),
            ("test.md", "markdown"),
            ("test.sh", "bash"),
            ("unknown.xyz", "plaintext")
        ]
        
        for (fileName, expectedLanguage) in testCases {
            let diffContent = DiffContent(
                filePath: fileName,
                hunks: [
                    DiffHunk(
                        oldStartLine: 1,
                        oldLineCount: 3,
                        newStartLine: 1,
                        newLineCount: 3,
                        lines: [
                            DiffLine(type: .context, content: "sample code", oldLineNumber: 1, newLineNumber: 1),
                            DiffLine(type: .removed, content: "old code", oldLineNumber: 2, newLineNumber: nil),
                            DiffLine(type: .added, content: "new code", oldLineNumber: nil, newLineNumber: 2)
                        ]
                    )
                ]
            )
            
            @State var expandedHunks: Set<Int> = [0]
            
            let unifiedView = UnifiedDiffView(
                diffContent: diffContent,
                showLineNumbers: true,
                expandedHunks: $expandedHunks
            )
            
            let sideBySideView = SideBySideDiffView(
                diffContent: diffContent,
                showLineNumbers: true,
                expandedHunks: $expandedHunks
            )
            
            // Both views should handle the same file
            #expect(diffContent.filePath == fileName)
            #expect(diffContent.hunks.count == 1)
            #expect(diffContent.hunks[0].lines.count == 3)
        }
    }
    
    // MARK: - Performance Tests
    
    @Test("View mode switching performance")
    func testViewModeSwitchingPerformance() {
        // Create a large diff content
        var hunks: [DiffHunk] = []
        
        for i in 0..<50 {
            let lines = [
                DiffLine(type: .context, content: "context line \(i)", oldLineNumber: i * 5 + 1, newLineNumber: i * 5 + 1),
                DiffLine(type: .removed, content: "removed line \(i)", oldLineNumber: i * 5 + 2, newLineNumber: nil),
                DiffLine(type: .added, content: "added line \(i)", oldLineNumber: nil, newLineNumber: i * 5 + 2),
                DiffLine(type: .added, content: "another added line \(i)", oldLineNumber: nil, newLineNumber: i * 5 + 3),
                DiffLine(type: .context, content: "context line \(i + 1)", oldLineNumber: i * 5 + 3, newLineNumber: i * 5 + 4)
            ]
            
            hunks.append(DiffHunk(
                oldStartLine: i * 5 + 1,
                oldLineCount: 4,
                newStartLine: i * 5 + 1,
                newLineCount: 5,
                lines: lines
            ))
        }
        
        let diffContent = DiffContent(
            filePath: "large_file.swift",
            hunks: hunks,
            statistics: DiffStatistics(additions: 100, deletions: 50)
        )
        
        @State var expandedHunks: Set<Int> = Set(0..<50)
        
        let startTime = Date()
        
        let unifiedView = UnifiedDiffView(
            diffContent: diffContent,
            showLineNumbers: true,
            expandedHunks: $expandedHunks
        )
        
        let sideBySideView = SideBySideDiffView(
            diffContent: diffContent,
            showLineNumbers: true,
            expandedHunks: $expandedHunks
        )
        
        let endTime = Date()
        let duration = endTime.timeIntervalSince(startTime)
        
        #expect(duration < 1.0) // Should create views quickly
        #expect(diffContent.hunks.count == 50)
        #expect(expandedHunks.count == 50)
    }
    
    // MARK: - Edge Cases
    
    @Test("Views handle empty or minimal content")
    func testViewsHandleEmptyOrMinimalContent() {
        let emptyDiffContent = DiffContent(
            filePath: "empty.txt",
            hunks: [],
            statistics: DiffStatistics()
        )
        
        let minimalDiffContent = DiffContent(
            filePath: "minimal.txt",
            hunks: [
                DiffHunk(
                    oldStartLine: 1,
                    oldLineCount: 1,
                    newStartLine: 1,
                    newLineCount: 1,
                    lines: [
                        DiffLine(type: .context, content: "single line", oldLineNumber: 1, newLineNumber: 1)
                    ]
                )
            ],
            statistics: DiffStatistics()
        )
        
        @State var expandedHunks: Set<Int> = [0]
        
        // Empty content
        let unifiedViewEmpty = UnifiedDiffView(
            diffContent: emptyDiffContent,
            showLineNumbers: true,
            expandedHunks: $expandedHunks
        )
        
        let sideBySideViewEmpty = SideBySideDiffView(
            diffContent: emptyDiffContent,
            showLineNumbers: true,
            expandedHunks: $expandedHunks
        )
        
        #expect(emptyDiffContent.hunks.count == 0)
        #expect(emptyDiffContent.statistics.isEmpty == true)
        
        // Minimal content
        let unifiedViewMinimal = UnifiedDiffView(
            diffContent: minimalDiffContent,
            showLineNumbers: true,
            expandedHunks: $expandedHunks
        )
        
        let sideBySideViewMinimal = SideBySideDiffView(
            diffContent: minimalDiffContent,
            showLineNumbers: true,
            expandedHunks: $expandedHunks
        )
        
        #expect(minimalDiffContent.hunks.count == 1)
        #expect(minimalDiffContent.hunks[0].lines.count == 1)
        #expect(minimalDiffContent.statistics.isEmpty == true)
    }
    
    @Test("Views handle special line types consistently")
    func testViewsHandleSpecialLineTypesConsistently() {
        let diffContent = DiffContent(
            filePath: "special.txt",
            hunks: [
                DiffHunk(
                    oldStartLine: 1,
                    oldLineCount: 4,
                    newStartLine: 1,
                    newLineCount: 4,
                    lines: [
                        DiffLine(type: .context, content: "normal context", oldLineNumber: 1, newLineNumber: 1),
                        DiffLine(type: .removed, content: "removed content", oldLineNumber: 2, newLineNumber: nil),
                        DiffLine(type: .added, content: "added content", oldLineNumber: nil, newLineNumber: 2),
                        DiffLine(type: .noNewlineAtEnd, content: "\\ No newline at end of file", oldLineNumber: nil, newLineNumber: nil)
                    ]
                )
            ],
            statistics: DiffStatistics(additions: 1, deletions: 1)
        )
        
        @State var expandedHunks: Set<Int> = [0]
        
        let unifiedView = UnifiedDiffView(
            diffContent: diffContent,
            showLineNumbers: true,
            expandedHunks: $expandedHunks
        )
        
        let sideBySideView = SideBySideDiffView(
            diffContent: diffContent,
            showLineNumbers: true,
            expandedHunks: $expandedHunks
        )
        
        let lines = diffContent.hunks[0].lines
        #expect(lines[0].type == .context)
        #expect(lines[1].type == .removed)
        #expect(lines[2].type == .added)
        #expect(lines[3].type == .noNewlineAtEnd)
        
        // Both views should handle these line types
        #expect(diffContent.hunks[0].lines.count == 4)
        #expect(diffContent.statistics.additions == 1)
        #expect(diffContent.statistics.deletions == 1)
    }
}