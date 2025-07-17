//
// UnifiedDiffParserTests.swift
// GitCthulhu
//
// Created by GitCthulhu Team on 2025-07-17.
//

@testable import GitCore
import XCTest

final class UnifiedDiffParserTests: XCTestCase {
    private var parser: UnifiedDiffParser!

    override func setUp() {
        super.setUp()
        parser = UnifiedDiffParser()
    }

    // MARK: - Basic Parsing Tests

    func testParseSimpleModifiedFile() throws {
        // Given
        let diffOutput = """
        diff --git a/test.swift b/test.swift
        index 1234567..abcdefg 100644
        --- a/test.swift
        +++ b/test.swift
        @@ -1,3 +1,4 @@
         func test() {
        -    let old = true
        +    let new = false
        +    let additional = true
         }
        """

        // When
        let diffs = try parser.parse(diffOutput)

        // Then
        XCTAssertEqual(diffs.count, 1)

        let diff = diffs[0]
        XCTAssertEqual(diff.filePath, "test.swift")
        XCTAssertEqual(diff.changeType, .modified)
        XCTAssertFalse(diff.isBinary)
        XCTAssertFalse(diff.isNew)
        XCTAssertFalse(diff.isDeleted)
        XCTAssertFalse(diff.isRenamed)

        XCTAssertEqual(diff.chunks.count, 1)
        let chunk = diff.chunks[0]
        XCTAssertEqual(chunk.oldStart, 1)
        XCTAssertEqual(chunk.oldCount, 3)
        XCTAssertEqual(chunk.newStart, 1)
        XCTAssertEqual(chunk.newCount, 4)
        XCTAssertEqual(chunk.lines.count, 4)

        // Verify line types
        XCTAssertEqual(chunk.lines[0].type, .context)
        XCTAssertEqual(chunk.lines[1].type, .deletion)
        XCTAssertEqual(chunk.lines[2].type, .addition)
        XCTAssertEqual(chunk.lines[3].type, .addition)

        // Verify line content
        XCTAssertEqual(chunk.lines[0].content, "func test() {")
        XCTAssertEqual(chunk.lines[1].content, "    let old = true")
        XCTAssertEqual(chunk.lines[2].content, "    let new = false")
        XCTAssertEqual(chunk.lines[3].content, "    let additional = true")
    }

    func testParseNewFile() throws {
        // Given
        let diffOutput = """
        diff --git a/newfile.swift b/newfile.swift
        new file mode 100644
        index 0000000..1234567
        --- /dev/null
        +++ b/newfile.swift
        @@ -0,0 +1,3 @@
        +func newFunction() {
        +    print("Hello World")
        +}
        """

        // When
        let diffs = try parser.parse(diffOutput)

        // Then
        XCTAssertEqual(diffs.count, 1)

        let diff = diffs[0]
        XCTAssertEqual(diff.filePath, "newfile.swift")
        XCTAssertEqual(diff.changeType, .added)
        XCTAssertTrue(diff.isNew)
        XCTAssertFalse(diff.isDeleted)
        XCTAssertFalse(diff.isRenamed)
        XCTAssertEqual(diff.newMode, "100644")

        XCTAssertEqual(diff.chunks.count, 1)
        let chunk = diff.chunks[0]
        XCTAssertEqual(chunk.oldStart, 0)
        XCTAssertEqual(chunk.oldCount, 0)
        XCTAssertEqual(chunk.newStart, 1)
        XCTAssertEqual(chunk.newCount, 3)

        // All lines should be additions
        XCTAssertTrue(chunk.lines.allSatisfy { $0.type == .addition })
        XCTAssertEqual(chunk.lines.count, 3)
    }

    func testParseDeletedFile() throws {
        // Given
        let diffOutput = """
        diff --git a/deletedfile.swift b/deletedfile.swift
        deleted file mode 100644
        index 1234567..0000000
        --- a/deletedfile.swift
        +++ /dev/null
        @@ -1,3 +0,0 @@
        -func deletedFunction() {
        -    print("Goodbye World")
        -}
        """

        // When
        let diffs = try parser.parse(diffOutput)

        // Then
        XCTAssertEqual(diffs.count, 1)

        let diff = diffs[0]
        XCTAssertEqual(diff.filePath, "deletedfile.swift")
        XCTAssertEqual(diff.changeType, .deleted)
        XCTAssertFalse(diff.isNew)
        XCTAssertTrue(diff.isDeleted)
        XCTAssertFalse(diff.isRenamed)
        XCTAssertEqual(diff.oldMode, "100644")

        XCTAssertEqual(diff.chunks.count, 1)
        let chunk = diff.chunks[0]
        XCTAssertEqual(chunk.oldStart, 1)
        XCTAssertEqual(chunk.oldCount, 3)
        XCTAssertEqual(chunk.newStart, 0)
        XCTAssertEqual(chunk.newCount, 0)

        // All lines should be deletions
        XCTAssertTrue(chunk.lines.allSatisfy { $0.type == .deletion })
        XCTAssertEqual(chunk.lines.count, 3)
    }

    func testParseRenamedFile() throws {
        // Given
        let diffOutput = """
        diff --git a/oldname.swift b/newname.swift
        similarity index 88%
        rename from oldname.swift
        rename to newname.swift
        index 1234567..abcdefg 100644
        --- a/oldname.swift
        +++ b/newname.swift
        @@ -1,3 +1,4 @@
         func example() {
             let value = true
        +    let newValue = false
         }
        """

        // When
        let diffs = try parser.parse(diffOutput)

        // Then
        XCTAssertEqual(diffs.count, 1)

        let diff = diffs[0]
        XCTAssertEqual(diff.filePath, "newname.swift")
        XCTAssertEqual(diff.oldPath, "oldname.swift")
        XCTAssertEqual(diff.changeType, .renamed)
        XCTAssertFalse(diff.isNew)
        XCTAssertFalse(diff.isDeleted)
        XCTAssertTrue(diff.isRenamed)
    }

    func testParseBinaryFile() throws {
        // Given
        let diffOutput = """
        diff --git a/image.png b/image.png
        index 1234567..abcdefg 100644
        Binary files a/image.png and b/image.png differ
        """

        // When
        let diffs = try parser.parse(diffOutput)

        // Then
        XCTAssertEqual(diffs.count, 1)

        let diff = diffs[0]
        XCTAssertEqual(diff.filePath, "image.png")
        XCTAssertTrue(diff.isBinary)
        XCTAssertEqual(diff.chunks.count, 0)
    }

    // MARK: - Multiple Files Tests

    func testParseMultipleFiles() throws {
        // Given
        let diffOutput = """
        diff --git a/file1.swift b/file1.swift
        index 1234567..abcdefg 100644
        --- a/file1.swift
        +++ b/file1.swift
        @@ -1,1 +1,2 @@
         let existing = true
        +let new = false

        diff --git a/file2.swift b/file2.swift
        index 2345678..bcdefgh 100644
        --- a/file2.swift
        +++ b/file2.swift
        @@ -1,2 +1,1 @@
        -let removed = true
         let remaining = false
        """

        // When
        let diffs = try parser.parse(diffOutput)

        // Then
        XCTAssertEqual(diffs.count, 2)

        let file1Diff = diffs.first { $0.filePath == "file1.swift" }
        XCTAssertNotNil(file1Diff)
        XCTAssertEqual(file1Diff?.additionsCount, 1)
        XCTAssertEqual(file1Diff?.deletionsCount, 0)

        let file2Diff = diffs.first { $0.filePath == "file2.swift" }
        XCTAssertNotNil(file2Diff)
        XCTAssertEqual(file2Diff?.additionsCount, 0)
        XCTAssertEqual(file2Diff?.deletionsCount, 1)
    }

    // MARK: - Complex Chunk Tests

    func testParseMultipleChunks() throws {
        // Given
        let diffOutput = """
        diff --git a/complex.swift b/complex.swift
        index 1234567..abcdefg 100644
        --- a/complex.swift
        +++ b/complex.swift
        @@ -1,3 +1,4 @@
         func first() {
        -    let old = true
        +    let new = false
         }
        @@ -10,2 +11,3 @@ func second() {
         func second() {
        +    let additional = true
             return value
        """

        // When
        let diffs = try parser.parse(diffOutput)

        // Then
        XCTAssertEqual(diffs.count, 1)

        let diff = diffs[0]
        XCTAssertEqual(diff.chunks.count, 2)

        let firstChunk = diff.chunks[0]
        XCTAssertEqual(firstChunk.oldStart, 1)
        XCTAssertEqual(firstChunk.newStart, 1)

        let secondChunk = diff.chunks[1]
        XCTAssertEqual(secondChunk.oldStart, 10)
        XCTAssertEqual(secondChunk.newStart, 11)
        XCTAssertEqual(secondChunk.context, "func second()")
    }

    // MARK: - Edge Cases

    func testParseEmptyDiff() throws {
        // Given
        let diffOutput = ""

        // When
        let diffs = try parser.parse(diffOutput)

        // Then
        XCTAssertEqual(diffs.count, 0)
    }

    func testParseOnlyHeaders() throws {
        // Given
        let diffOutput = """
        diff --git a/test.swift b/test.swift
        index 1234567..abcdefg 100644
        --- a/test.swift
        +++ b/test.swift
        """

        // When
        let diffs = try parser.parse(diffOutput)

        // Then
        XCTAssertEqual(diffs.count, 1)

        let diff = diffs[0]
        XCTAssertEqual(diff.filePath, "test.swift")
        XCTAssertEqual(diff.chunks.count, 0)
    }

    func testParseNoNewlineAtEndOfFile() throws {
        // Given
        let diffOutput = """
        diff --git a/test.swift b/test.swift
        index 1234567..abcdefg 100644
        --- a/test.swift
        +++ b/test.swift
        @@ -1,1 +1,1 @@
        -let value = true
        +let value = false
        \\ No newline at end of file
        """

        // When
        let diffs = try parser.parse(diffOutput)

        // Then
        XCTAssertEqual(diffs.count, 1)

        let diff = diffs[0]
        XCTAssertEqual(diff.chunks.count, 1)

        let chunk = diff.chunks[0]
        XCTAssertEqual(chunk.lines.count, 3)
        XCTAssertEqual(chunk.lines[2].type, .noNewline)
        XCTAssertEqual(chunk.lines[2].content, " No newline at end of file")
    }

    // MARK: - Line Number Tests

    func testLineNumbersCorrectlyAssigned() throws {
        // Given
        let diffOutput = """
        diff --git a/test.swift b/test.swift
        index 1234567..abcdefg 100644
        --- a/test.swift
        +++ b/test.swift
        @@ -5,4 +5,5 @@
         line 5
         line 6
        -line 7 old
        +line 7 new
        +line 8 added
         line 8
        """

        // When
        let diffs = try parser.parse(diffOutput)

        // Then
        XCTAssertEqual(diffs.count, 1)

        let diff = diffs[0]
        XCTAssertEqual(diff.chunks.count, 1)

        let chunk = diff.chunks[0]
        let lines = chunk.lines

        // Context lines
        XCTAssertEqual(lines[0].oldLineNumber, 5)
        XCTAssertEqual(lines[0].newLineNumber, 5)
        XCTAssertEqual(lines[1].oldLineNumber, 6)
        XCTAssertEqual(lines[1].newLineNumber, 6)

        // Deletion
        XCTAssertEqual(lines[2].oldLineNumber, 7)
        XCTAssertNil(lines[2].newLineNumber)

        // Addition
        XCTAssertNil(lines[3].oldLineNumber)
        XCTAssertEqual(lines[3].newLineNumber, 7)

        // Another addition
        XCTAssertNil(lines[4].oldLineNumber)
        XCTAssertEqual(lines[4].newLineNumber, 8)

        // Context line
        XCTAssertEqual(lines[5].oldLineNumber, 8)
        XCTAssertEqual(lines[5].newLineNumber, 9)
    }

    // MARK: - Performance Tests

    func testParsePerformanceWithLargeDiff() {
        // Given
        var largeDiffOutput = """
        diff --git a/large.swift b/large.swift
        index 1234567..abcdefg 100644
        --- a/large.swift
        +++ b/large.swift
        @@ -1,1000 +1,1001 @@
        """

        // Generate 1000 lines of diff
        for i in 1 ... 1000 {
            if i % 10 == 0 {
                largeDiffOutput += "\n-let old\(i) = true"
                largeDiffOutput += "\n+let new\(i) = false"
            } else {
                largeDiffOutput += "\n let line\(i) = value"
            }
        }
        largeDiffOutput += "\n+let additional = true"

        // When/Then
        measure {
            do {
                let diffs = try parser.parse(largeDiffOutput)
                XCTAssertEqual(diffs.count, 1)
                XCTAssertGreaterThan(diffs[0].chunks.count, 0)
            } catch {
                XCTFail("Parsing failed: \(error)")
            }
        }
    }
}
