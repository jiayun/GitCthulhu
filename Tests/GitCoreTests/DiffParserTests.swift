//
// DiffParserTests.swift
// GitCthulhu
//
// Created by GitCthulhu Team on 2025-07-15.
//

import Testing
import Foundation
@testable import GitCore

struct DiffParserTests {
    
    // MARK: - Basic Parsing Tests
    
    @Test("Parse simple unified diff")
    func testParseSimpleUnifiedDiff() {
        let diffOutput = """
        diff --git a/test.txt b/test.txt
        index 1234567..abcdefg 100644
        --- a/test.txt
        +++ b/test.txt
        @@ -1,3 +1,4 @@
         line 1
        -line 2
        +line 2 modified
        +line 3 added
         line 4
        """
        
        let parser = DiffParser()
        let results = parser.parse(diffOutput)
        
        #expect(results.count == 1)
        
        let diff = results[0]
        #expect(diff.filePath == "test.txt")
        #expect(diff.isBinary == false)
        #expect(diff.isNewFile == false)
        #expect(diff.isDeletedFile == false)
        #expect(diff.hunks.count == 1)
        
        let hunk = diff.hunks[0]
        #expect(hunk.oldStartLine == 1)
        #expect(hunk.oldLineCount == 3)
        #expect(hunk.newStartLine == 1)
        #expect(hunk.newLineCount == 4)
        #expect(hunk.lines.count == 4)
        
        // Check line types
        #expect(hunk.lines[0].type == .context)
        #expect(hunk.lines[1].type == .removed)
        #expect(hunk.lines[2].type == .added)
        #expect(hunk.lines[3].type == .added)
        
        // Check line content
        #expect(hunk.lines[0].content == "line 1")
        #expect(hunk.lines[1].content == "line 2")
        #expect(hunk.lines[2].content == "line 2 modified")
        #expect(hunk.lines[3].content == "line 3 added")
        
        // Check line numbers
        #expect(hunk.lines[0].oldLineNumber == 1)
        #expect(hunk.lines[0].newLineNumber == 1)
        #expect(hunk.lines[1].oldLineNumber == 2)
        #expect(hunk.lines[1].newLineNumber == nil)
        #expect(hunk.lines[2].oldLineNumber == nil)
        #expect(hunk.lines[2].newLineNumber == 2)
        #expect(hunk.lines[3].oldLineNumber == nil)
        #expect(hunk.lines[3].newLineNumber == 3)
    }
    
    @Test("Parse multiple hunks")
    func testParseMultipleHunks() {
        let diffOutput = """
        diff --git a/test.txt b/test.txt
        index 1234567..abcdefg 100644
        --- a/test.txt
        +++ b/test.txt
        @@ -1,3 +1,3 @@
         line 1
        -line 2
        +line 2 modified
         line 3
        @@ -10,2 +10,3 @@
         line 10
        +line 10.5
         line 11
        """
        
        let parser = DiffParser()
        let results = parser.parse(diffOutput)
        
        #expect(results.count == 1)
        
        let diff = results[0]
        #expect(diff.hunks.count == 2)
        
        let firstHunk = diff.hunks[0]
        #expect(firstHunk.oldStartLine == 1)
        #expect(firstHunk.oldLineCount == 3)
        #expect(firstHunk.newStartLine == 1)
        #expect(firstHunk.newLineCount == 3)
        #expect(firstHunk.lines.count == 3)
        
        let secondHunk = diff.hunks[1]
        #expect(secondHunk.oldStartLine == 10)
        #expect(secondHunk.oldLineCount == 2)
        #expect(secondHunk.newStartLine == 10)
        #expect(secondHunk.newLineCount == 3)
        #expect(secondHunk.lines.count == 3)
    }
    
    @Test("Parse binary file diff")
    func testParseBinaryFileDiff() {
        let diffOutput = """
        diff --git a/image.png b/image.png
        index 1234567..abcdefg 100644
        Binary files a/image.png and b/image.png differ
        """
        
        let parser = DiffParser()
        let results = parser.parse(diffOutput)
        
        #expect(results.count == 1)
        
        let diff = results[0]
        #expect(diff.filePath == "image.png")
        #expect(diff.isBinary == true)
        #expect(diff.hunks.count == 0)
    }
    
    @Test("Parse hunk with context information")
    func testParseHunkWithContext() {
        let diffOutput = """
        diff --git a/test.swift b/test.swift
        index 1234567..abcdefg 100644
        --- a/test.swift
        +++ b/test.swift
        @@ -1,5 +1,5 @@ func testFunction() {
         import Foundation
         
         func testFunction() {
        -    print("old")
        +    print("new")
         }
        """
        
        let parser = DiffParser()
        let results = parser.parse(diffOutput)
        
        #expect(results.count == 1)
        
        let diff = results[0]
        #expect(diff.hunks.count == 1)
        
        let hunk = diff.hunks[0]
        #expect(hunk.context == "func testFunction() {")
    }
    
    @Test("Parse empty diff")
    func testParseEmptyDiff() {
        let diffOutput = ""
        
        let parser = DiffParser()
        let results = parser.parse(diffOutput)
        
        #expect(results.count == 0)
    }
    
    @Test("Parse diff with no newline at end")
    func testParseDiffWithNoNewlineAtEnd() {
        let diffOutput = """
        diff --git a/test.txt b/test.txt
        index 1234567..abcdefg 100644
        --- a/test.txt
        +++ b/test.txt
        @@ -1,2 +1,2 @@
         line 1
        -line 2
        +line 2 modified
        \\ No newline at end of file
        """
        
        let parser = DiffParser()
        let results = parser.parse(diffOutput)
        
        #expect(results.count == 1)
        
        let diff = results[0]
        #expect(diff.hunks.count == 1)
        
        let hunk = diff.hunks[0]
        #expect(hunk.lines.count == 3)
        #expect(hunk.lines[2].type == .noNewlineAtEnd)
    }
    
    // MARK: - Statistics Tests
    
    @Test("Calculate diff statistics")
    func testCalculateDiffStatistics() {
        let diffOutput = """
        diff --git a/test.txt b/test.txt
        index 1234567..abcdefg 100644
        --- a/test.txt
        +++ b/test.txt
        @@ -1,3 +1,5 @@
         line 1
        -line 2
        +line 2 modified
        +line 3 added
        +line 4 added
         line 5
        """
        
        let parser = DiffParser()
        let results = parser.parse(diffOutput)
        
        #expect(results.count == 1)
        
        let diff = results[0]
        #expect(diff.statistics.additions == 3)
        #expect(diff.statistics.deletions == 1)
        #expect(diff.statistics.totalLines == 4)
        #expect(diff.statistics.isEmpty == false)
    }
    
    @Test("Statistics for empty diff")
    func testStatisticsForEmptyDiff() {
        let statistics = DiffStatistics()
        
        #expect(statistics.additions == 0)
        #expect(statistics.deletions == 0)
        #expect(statistics.totalLines == 0)
        #expect(statistics.isEmpty == true)
    }
    
    // MARK: - File Path Extraction Tests
    
    @Test("Extract file path from git diff header")
    func testExtractFilePathFromGitDiffHeader() {
        let diffOutput = """
        diff --git a/Sources/GitCore/DiffParser.swift b/Sources/GitCore/DiffParser.swift
        index 1234567..abcdefg 100644
        --- a/Sources/GitCore/DiffParser.swift
        +++ b/Sources/GitCore/DiffParser.swift
        @@ -1,3 +1,3 @@
         import Foundation
        -old line
        +new line
        """
        
        let parser = DiffParser()
        let results = parser.parse(diffOutput)
        
        #expect(results.count == 1)
        
        let diff = results[0]
        #expect(diff.filePath == "Sources/GitCore/DiffParser.swift")
    }
    
    // MARK: - Edge Cases
    
    @Test("Parse diff with only additions")
    func testParseDiffWithOnlyAdditions() {
        let diffOutput = """
        diff --git a/test.txt b/test.txt
        index 1234567..abcdefg 100644
        --- a/test.txt
        +++ b/test.txt
        @@ -1,1 +1,3 @@
         line 1
        +line 2
        +line 3
        """
        
        let parser = DiffParser()
        let results = parser.parse(diffOutput)
        
        #expect(results.count == 1)
        
        let diff = results[0]
        #expect(diff.statistics.additions == 2)
        #expect(diff.statistics.deletions == 0)
        
        let hunk = diff.hunks[0]
        #expect(hunk.lines.count == 3)
        #expect(hunk.lines[0].type == .context)
        #expect(hunk.lines[1].type == .added)
        #expect(hunk.lines[2].type == .added)
    }
    
    @Test("Parse diff with only deletions")
    func testParseDiffWithOnlyDeletions() {
        let diffOutput = """
        diff --git a/test.txt b/test.txt
        index 1234567..abcdefg 100644
        --- a/test.txt
        +++ b/test.txt
        @@ -1,3 +1,1 @@
         line 1
        -line 2
        -line 3
        """
        
        let parser = DiffParser()
        let results = parser.parse(diffOutput)
        
        #expect(results.count == 1)
        
        let diff = results[0]
        #expect(diff.statistics.additions == 0)
        #expect(diff.statistics.deletions == 2)
        
        let hunk = diff.hunks[0]
        #expect(hunk.lines.count == 3)
        #expect(hunk.lines[0].type == .context)
        #expect(hunk.lines[1].type == .removed)
        #expect(hunk.lines[2].type == .removed)
    }
    
    @Test("Parse diff with malformed hunk header")
    func testParseDiffWithMalformedHunkHeader() {
        let diffOutput = """
        diff --git a/test.txt b/test.txt
        index 1234567..abcdefg 100644
        --- a/test.txt
        +++ b/test.txt
        @@ invalid hunk header @@
         line 1
        +line 2
        """
        
        let parser = DiffParser()
        let results = parser.parse(diffOutput)
        
        #expect(results.count == 1)
        
        let diff = results[0]
        // Should handle malformed headers gracefully
        #expect(diff.hunks.count == 0)
    }
    
    // MARK: - Complex Scenarios
    
    @Test("Parse multiple files diff")
    func testParseMultipleFilesDiff() {
        let diffOutput = """
        diff --git a/file1.txt b/file1.txt
        index 1234567..abcdefg 100644
        --- a/file1.txt
        +++ b/file1.txt
        @@ -1,2 +1,2 @@
         line 1
        -old line
        +new line
        diff --git a/file2.txt b/file2.txt
        index 2345678..bcdefgh 100644
        --- a/file2.txt
        +++ b/file2.txt
        @@ -1,1 +1,2 @@
         line 1
        +line 2
        """
        
        let parser = DiffParser()
        let results = parser.parse(diffOutput)
        
        #expect(results.count == 2)
        
        let diff1 = results[0]
        #expect(diff1.filePath == "file1.txt")
        #expect(diff1.hunks.count == 1)
        #expect(diff1.statistics.additions == 1)
        #expect(diff1.statistics.deletions == 1)
        
        let diff2 = results[1]
        #expect(diff2.filePath == "file2.txt")
        #expect(diff2.hunks.count == 1)
        #expect(diff2.statistics.additions == 1)
        #expect(diff2.statistics.deletions == 0)
    }
    
    @Test("Parse diff with large line numbers")
    func testParseDiffWithLargeLineNumbers() {
        let diffOutput = """
        diff --git a/test.txt b/test.txt
        index 1234567..abcdefg 100644
        --- a/test.txt
        +++ b/test.txt
        @@ -1000,5 +1000,5 @@
         line 1000
        -line 1001
        +line 1001 modified
         line 1002
        """
        
        let parser = DiffParser()
        let results = parser.parse(diffOutput)
        
        #expect(results.count == 1)
        
        let diff = results[0]
        let hunk = diff.hunks[0]
        #expect(hunk.oldStartLine == 1000)
        #expect(hunk.newStartLine == 1000)
        #expect(hunk.lines[0].oldLineNumber == 1000)
        #expect(hunk.lines[0].newLineNumber == 1000)
    }
    
    // MARK: - Performance Tests
    
    @Test("Parse large diff performance")
    func testParseLargeDiffPerformance() {
        // Create a large diff with many hunks
        var diffOutput = """
        diff --git a/large_file.txt b/large_file.txt
        index 1234567..abcdefg 100644
        --- a/large_file.txt
        +++ b/large_file.txt
        """
        
        // Generate 100 hunks with 10 lines each
        for i in 0..<100 {
            let startLine = i * 10 + 1
            diffOutput += """
            
            @@ -\(startLine),10 +\(startLine),10 @@
            """
            
            for j in 0..<10 {
                if j == 5 {
                    diffOutput += """
                    
            -old line \(startLine + j)
            +new line \(startLine + j)
            """
                } else {
                    diffOutput += """
                    
             line \(startLine + j)
            """
                }
            }
        }
        
        let parser = DiffParser()
        let startTime = Date()
        let results = parser.parse(diffOutput)
        let endTime = Date()
        
        let duration = endTime.timeIntervalSince(startTime)
        #expect(duration < 1.0) // Should parse within 1 second
        
        #expect(results.count == 1)
        #expect(results[0].hunks.count == 100)
        #expect(results[0].statistics.additions == 100)
        #expect(results[0].statistics.deletions == 100)
    }
}