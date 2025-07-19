//
// GitDiffManagerTests.swift
// GitCthulhu
//
// Created by GitCthulhu Team on 2025-07-17.
//

@testable import GitCore
import XCTest

@MainActor
final class GitDiffManagerTests: XCTestCase {
    private var tempRepositoryPath: String!
    private var diffManager: GitDiffManager!
    private var mockCommandExecutor: MockGitCommandExecutor!

    override func setUp() async throws {
        try await super.setUp()

        // Create temporary directory for test repository
        tempRepositoryPath = NSTemporaryDirectory().appending("test-repo-\(UUID().uuidString)")
        try FileManager.default.createDirectory(
            atPath: tempRepositoryPath,
            withIntermediateDirectories: true,
            attributes: nil
        )

        // Initialize mock command executor
        mockCommandExecutor = MockGitCommandExecutor()

        // Create diff manager with mock executor
        diffManager = GitDiffManager(
            repositoryPath: tempRepositoryPath,
            commandExecutor: mockCommandExecutor
        )
    }

    override func tearDown() async throws {
        // Clean up temporary directory
        try? FileManager.default.removeItem(atPath: tempRepositoryPath)
        try await super.tearDown()
    }

    // MARK: - Basic Diff Tests

    func testGetDiffForSingleFile() async throws {
        // Given
        let filePath = "test.swift"
        let mockDiffOutput = """
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

        mockCommandExecutor.mockOutput = mockDiffOutput

        // When
        let diff = try await diffManager.getDiff(for: filePath, staged: false)

        // Then
        XCTAssertNotNil(diff)
        XCTAssertEqual(diff?.filePath, filePath)
        XCTAssertEqual(diff?.changeType, .modified)
        XCTAssertEqual(diff?.chunks.count, 1)
        XCTAssertEqual(diff?.additionsCount, 2)
        XCTAssertEqual(diff?.deletionsCount, 1)

        // Verify command was called correctly
        XCTAssertEqual(mockCommandExecutor.lastCommand, "git")
        XCTAssertTrue(mockCommandExecutor.lastArguments.contains("diff"))
        XCTAssertTrue(mockCommandExecutor.lastArguments.contains(filePath))
        XCTAssertFalse(mockCommandExecutor.lastArguments.contains("--cached"))
    }

    func testGetDiffForStagedFile() async throws {
        // Given
        let filePath = "staged.swift"
        let mockDiffOutput = """
        diff --git a/staged.swift b/staged.swift
        index 1234567..abcdefg 100644
        --- a/staged.swift
        +++ b/staged.swift
        @@ -1,2 +1,2 @@
        -let old = true
        +let new = false
        """

        mockCommandExecutor.mockOutput = mockDiffOutput

        // When
        let diff = try await diffManager.getDiff(for: filePath, staged: true)

        // Then
        XCTAssertNotNil(diff)
        XCTAssertEqual(diff?.filePath, filePath)

        // Verify staged flag was passed
        XCTAssertTrue(mockCommandExecutor.lastArguments.contains("--cached"))
    }

    func testGetDiffForNonExistentFile() async throws {
        // Given
        let filePath = "nonexistent.swift"
        mockCommandExecutor.mockOutput = ""

        // When
        let diff = try await diffManager.getDiff(for: filePath, staged: false)

        // Then
        XCTAssertNil(diff)
    }

    // MARK: - Multiple Files Tests

    func testGetAllDiffs() async throws {
        // Given
        let mockDiffOutput = """
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

        mockCommandExecutor.mockOutput = mockDiffOutput

        // When
        let diffs = try await diffManager.getAllDiffs(staged: false)

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

        // Verify current diffs were updated
        XCTAssertEqual(diffManager.currentDiffs.count, 2)
    }

    // MARK: - Binary File Tests

    func testBinaryFileDiff() async throws {
        // Given
        let mockDiffOutput = """
        diff --git a/image.png b/image.png
        index 1234567..abcdefg 100644
        Binary files a/image.png and b/image.png differ
        """

        mockCommandExecutor.mockOutput = mockDiffOutput

        // When
        let diffs = try await diffManager.getAllDiffs(staged: false)

        // Then
        XCTAssertEqual(diffs.count, 1)
        let diff = diffs.first
        XCTAssertNotNil(diff)
        XCTAssertEqual(diff?.filePath, "image.png")
        XCTAssertTrue(diff?.isBinary ?? false)
        XCTAssertEqual(diff?.chunks.count, 0)
    }

    // MARK: - New File Tests

    func testNewFileDiff() async throws {
        // Given
        let mockDiffOutput = """
        diff --git a/newfile.swift b/newfile.swift
        new file mode 100644
        index 0000000..1234567
        --- /dev/null
        +++ b/newfile.swift
        @@ -0,0 +1,3 @@
        +func newFunction() {
        +    // This is a new line
        +}
        """

        mockCommandExecutor.mockOutput = mockDiffOutput

        // When
        let diffs = try await diffManager.getAllDiffs(staged: false)

        // Then
        XCTAssertEqual(diffs.count, 1)
        let diff = diffs.first
        XCTAssertNotNil(diff)
        XCTAssertEqual(diff?.filePath, "newfile.swift")
        XCTAssertEqual(diff?.changeType, .added)
        XCTAssertTrue(diff?.isNew ?? false)
        XCTAssertEqual(diff?.additionsCount, 3)
        XCTAssertEqual(diff?.deletionsCount, 0)
    }

    // MARK: - Deleted File Tests

    func testDeletedFileDiff() async throws {
        // Given
        let mockDiffOutput = """
        diff --git a/deletedfile.swift b/deletedfile.swift
        deleted file mode 100644
        index 1234567..0000000
        --- a/deletedfile.swift
        +++ /dev/null
        @@ -1,3 +0,0 @@
        -func deletedFunction() {
        -    // This line was deleted
        -}
        """

        mockCommandExecutor.mockOutput = mockDiffOutput

        // When
        let diffs = try await diffManager.getAllDiffs(staged: false)

        // Then
        XCTAssertEqual(diffs.count, 1)
        let diff = diffs.first
        XCTAssertNotNil(diff)
        XCTAssertEqual(diff?.filePath, "deletedfile.swift")
        XCTAssertEqual(diff?.changeType, .deleted)
        XCTAssertTrue(diff?.isDeleted ?? false)
        XCTAssertEqual(diff?.additionsCount, 0)
        XCTAssertEqual(diff?.deletionsCount, 3)
    }

    // MARK: - Renamed File Tests

    func testRenamedFileDiff() async throws {
        // Given
        let mockDiffOutput = """
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

        mockCommandExecutor.mockOutput = mockDiffOutput

        // When
        let diffs = try await diffManager.getAllDiffs(staged: false)

        // Then
        XCTAssertEqual(diffs.count, 1)
        let diff = diffs.first
        XCTAssertNotNil(diff)
        XCTAssertEqual(diff?.filePath, "newname.swift")
        XCTAssertEqual(diff?.oldPath, "oldname.swift")
        XCTAssertEqual(diff?.changeType, .renamed)
        XCTAssertTrue(diff?.isRenamed ?? false)
    }

    // MARK: - Error Handling Tests

    func testCommandExecutionError() async {
        // Given
        mockCommandExecutor.shouldThrowError = true
        mockCommandExecutor.errorToThrow = GitError.unknown("git command failed")

        // When/Then
        do {
            _ = try await diffManager.getDiff(for: "test.swift", staged: false)
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertTrue(error is GitError)
            XCTAssertNotNil(diffManager.error)
        }
    }

    // MARK: - Convenience Methods Tests

    func testGetDiffForFileWithAutoDetection() async throws {
        // Given
        let filePath = "test.swift"

        // Mock unstaged diff first
        mockCommandExecutor.mockOutputs = [
            "", // No unstaged diff
            """
            diff --git a/test.swift b/test.swift
            index 1234567..abcdefg 100644
            --- a/test.swift
            +++ b/test.swift
            @@ -1,1 +1,2 @@
             let existing = true
            +let new = false
            """ // Staged diff
        ]

        // When
        let diff = try await diffManager.getDiffForFile(filePath)

        // Then
        XCTAssertNotNil(diff)
        XCTAssertEqual(diff?.filePath, filePath)

        // Should have called both unstaged and staged
        XCTAssertEqual(mockCommandExecutor.callCount, 2)
    }

    func testHasDiff() async {
        // Given
        let filePath = "test.swift"
        mockCommandExecutor.mockOutput = """
        diff --git a/test.swift b/test.swift
        index 1234567..abcdefg 100644
        --- a/test.swift
        +++ b/test.swift
        @@ -1,1 +1,2 @@
         let existing = true
        +let new = false
        """

        // When
        let hasDiff = await diffManager.hasDiff(for: filePath)

        // Then
        XCTAssertTrue(hasDiff)
    }

    func testHasNoDiff() async {
        // Given
        let filePath = "test.swift"
        mockCommandExecutor.mockOutput = ""

        // When
        let hasDiff = await diffManager.hasDiff(for: filePath)

        // Then
        XCTAssertFalse(hasDiff)
    }

    // MARK: - State Management Tests

    func testLoadingState() async {
        // Given
        mockCommandExecutor.shouldDelay = true
        mockCommandExecutor.delayDuration = 0.1
        mockCommandExecutor.mockOutput = ""

        // When
        let loadingTask = Task {
            try await diffManager.getAllDiffs(staged: false)
        }

        // Then
        // Check loading state is true during execution
        do {
            try await Task.sleep(nanoseconds: 50_000_000) // 0.05 seconds
            XCTAssertTrue(diffManager.isLoading)

            // Wait for completion
            _ = try await loadingTask.value
            XCTAssertFalse(diffManager.isLoading)
        } catch {
            XCTFail("Loading test failed: \(error)")
        }
    }

    func testErrorClearing() async throws {
        // Given
        mockCommandExecutor.shouldThrowError = true
        mockCommandExecutor.errorToThrow = GitError.unknown("test error")

        // When
        do {
            _ = try await diffManager.getDiff(for: "test.swift", staged: false)
        } catch {
            // Expected
        }

        // Then
        XCTAssertNotNil(diffManager.error)

        // Clear error
        diffManager.clearCurrentError()
        XCTAssertNil(diffManager.error)
    }
}

// MARK: - Mock Command Executor

class MockGitCommandExecutor: GitCommandExecutor {
    var mockOutput: String = ""
    var mockOutputs: [String] = []
    var shouldThrowError: Bool = false
    var errorToThrow: Error = GitError.unknown("Mock error")
    var shouldDelay: Bool = false
    var delayDuration: TimeInterval = 0.0

    var lastCommand: String = ""
    var lastArguments: [String] = []
    var lastWorkingDirectory: String = ""
    var callCount: Int = 0

    init() {
        super.init(repositoryURL: URL(fileURLWithPath: "/tmp/test"))
    }

    override func execute(_ arguments: [String]) async throws -> String {
        callCount += 1
        lastCommand = "git"
        lastArguments = arguments
        lastWorkingDirectory = "/tmp/test"

        if shouldDelay {
            try await Task.sleep(nanoseconds: UInt64(delayDuration * 1_000_000_000))
        }

        if shouldThrowError {
            throw errorToThrow
        }

        if !mockOutputs.isEmpty, callCount <= mockOutputs.count {
            return mockOutputs[callCount - 1]
        }

        return mockOutput
    }
}
