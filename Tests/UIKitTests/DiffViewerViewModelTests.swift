//
// DiffViewerViewModelTests.swift
// GitCthulhu
//
// Created by GitCthulhu Team on 2025-07-17.
//

@testable import GitCore
@testable import UIKit
import XCTest

@MainActor
final class DiffViewerViewModelTests: XCTestCase {
    private var tempRepositoryPath: String!
    private var viewModel: DiffViewerViewModel!

    override func setUp() async throws {
        try await super.setUp()

        // Create temporary directory for test repository
        tempRepositoryPath = NSTemporaryDirectory().appending("test-repo-\(UUID().uuidString)")
        try FileManager.default.createDirectory(
            atPath: tempRepositoryPath,
            withIntermediateDirectories: true,
            attributes: nil
        )

        // Create view model
        viewModel = DiffViewerViewModel(repositoryPath: tempRepositoryPath)
    }

    override func tearDown() async throws {
        // Clean up temporary directory
        try? FileManager.default.removeItem(atPath: tempRepositoryPath)
        try await super.tearDown()
    }

    // MARK: - Initialization Tests

    func testInitialState() {
        XCTAssertTrue(viewModel.diffs.isEmpty)
        XCTAssertNil(viewModel.selectedFilePath)
        XCTAssertEqual(viewModel.viewMode, .unified)
        XCTAssertFalse(viewModel.showWhitespace)
        XCTAssertTrue(viewModel.showLineNumbers)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.error)
        XCTAssertTrue(viewModel.searchQuery.isEmpty)
        XCTAssertFalse(viewModel.showStaged)
    }

    // MARK: - File Selection Tests

    func testSelectFile() {
        // Given
        let filePath = "test.swift"

        // When
        viewModel.selectFile(filePath)

        // Then
        XCTAssertEqual(viewModel.selectedFilePath, filePath)
    }

    func testSelectedDiff() {
        // Given
        let testDiff = createTestDiff(filePath: "test.swift")
        viewModel.diffs = [testDiff]

        // When
        viewModel.selectFile("test.swift")

        // Then
        XCTAssertNotNil(viewModel.selectedDiff)
        XCTAssertEqual(viewModel.selectedDiff?.filePath, "test.swift")
    }

    func testSelectedDiffWithNoMatch() {
        // Given
        let testDiff = createTestDiff(filePath: "other.swift")
        viewModel.diffs = [testDiff]

        // When
        viewModel.selectFile("nonexistent.swift")

        // Then
        XCTAssertNil(viewModel.selectedDiff)
    }

    // MARK: - Search Filtering Tests

    func testFilteredDiffsWithEmptyQuery() {
        // Given
        let diff1 = createTestDiff(filePath: "file1.swift")
        let diff2 = createTestDiff(filePath: "file2.js")
        viewModel.diffs = [diff1, diff2]
        viewModel.searchQuery = ""

        // When
        let filtered = viewModel.filteredDiffs

        // Then
        XCTAssertEqual(filtered.count, 2)
    }

    func testFilteredDiffsWithQuery() {
        // Given
        let diff1 = createTestDiff(filePath: "test.swift")
        let diff2 = createTestDiff(filePath: "example.js")
        let diff3 = createTestDiff(filePath: "another.swift")
        viewModel.diffs = [diff1, diff2, diff3]
        viewModel.searchQuery = "swift"

        // When
        let filtered = viewModel.filteredDiffs

        // Then
        XCTAssertEqual(filtered.count, 2)
        XCTAssertTrue(filtered.allSatisfy { $0.filePath.contains("swift") })
    }

    func testFilteredDiffsWithFileNameQuery() {
        // Given
        let diff1 = createTestDiff(filePath: "src/components/TestComponent.swift")
        let diff2 = createTestDiff(filePath: "src/views/ExampleView.swift")
        viewModel.diffs = [diff1, diff2]
        viewModel.searchQuery = "Test"

        // When
        let filtered = viewModel.filteredDiffs

        // Then
        XCTAssertEqual(filtered.count, 1)
        XCTAssertEqual(filtered[0].filePath, "src/components/TestComponent.swift")
    }

    // MARK: - Statistics Tests

    func testTotalStats() {
        // Given
        let diff1 = createTestDiff(filePath: "file1.swift", additions: 5, deletions: 2)
        let diff2 = createTestDiff(filePath: "file2.swift", additions: 3, deletions: 1)
        viewModel.diffs = [diff1, diff2]

        // When
        let stats = viewModel.totalStats

        // Then
        XCTAssertEqual(stats.additions, 8)
        XCTAssertEqual(stats.deletions, 3)
        XCTAssertEqual(stats.chunks, 2) // One chunk per diff
    }

    func testTotalStatsWithBinaryFile() {
        // Given
        let textDiff = createTestDiff(filePath: "file.swift", additions: 5, deletions: 2)
        let binaryDiff = createBinaryTestDiff(filePath: "image.png")
        viewModel.diffs = [textDiff, binaryDiff]

        // When
        let stats = viewModel.totalStats

        // Then
        XCTAssertEqual(stats.additions, 5)
        XCTAssertEqual(stats.deletions, 2)
        XCTAssertTrue(stats.isBinary)
    }

    // MARK: - Navigation Tests

    func testSelectNextFile() {
        // Given
        let diff1 = createTestDiff(filePath: "file1.swift")
        let diff2 = createTestDiff(filePath: "file2.swift")
        let diff3 = createTestDiff(filePath: "file3.swift")
        viewModel.diffs = [diff1, diff2, diff3]
        viewModel.selectedFilePath = "file1.swift"

        // When
        viewModel.selectNextFile()

        // Then
        XCTAssertEqual(viewModel.selectedFilePath, "file2.swift")
    }

    func testSelectNextFileAtEnd() {
        // Given
        let diff1 = createTestDiff(filePath: "file1.swift")
        let diff2 = createTestDiff(filePath: "file2.swift")
        viewModel.diffs = [diff1, diff2]
        viewModel.selectedFilePath = "file2.swift"

        // When
        viewModel.selectNextFile()

        // Then
        XCTAssertEqual(viewModel.selectedFilePath, "file2.swift") // Should not change
    }

    func testSelectPreviousFile() {
        // Given
        let diff1 = createTestDiff(filePath: "file1.swift")
        let diff2 = createTestDiff(filePath: "file2.swift")
        let diff3 = createTestDiff(filePath: "file3.swift")
        viewModel.diffs = [diff1, diff2, diff3]
        viewModel.selectedFilePath = "file2.swift"

        // When
        viewModel.selectPreviousFile()

        // Then
        XCTAssertEqual(viewModel.selectedFilePath, "file1.swift")
    }

    func testSelectPreviousFileAtBeginning() {
        // Given
        let diff1 = createTestDiff(filePath: "file1.swift")
        let diff2 = createTestDiff(filePath: "file2.swift")
        viewModel.diffs = [diff1, diff2]
        viewModel.selectedFilePath = "file1.swift"

        // When
        viewModel.selectPreviousFile()

        // Then
        XCTAssertEqual(viewModel.selectedFilePath, "file1.swift") // Should not change
    }

    func testCanNavigateNext() {
        // Given
        let diff1 = createTestDiff(filePath: "file1.swift")
        let diff2 = createTestDiff(filePath: "file2.swift")
        viewModel.diffs = [diff1, diff2]

        // When/Then
        viewModel.selectedFilePath = "file1.swift"
        XCTAssertTrue(viewModel.canNavigateNext)

        viewModel.selectedFilePath = "file2.swift"
        XCTAssertFalse(viewModel.canNavigateNext)
    }

    func testCanNavigatePrevious() {
        // Given
        let diff1 = createTestDiff(filePath: "file1.swift")
        let diff2 = createTestDiff(filePath: "file2.swift")
        viewModel.diffs = [diff1, diff2]

        // When/Then
        viewModel.selectedFilePath = "file1.swift"
        XCTAssertFalse(viewModel.canNavigatePrevious)

        viewModel.selectedFilePath = "file2.swift"
        XCTAssertTrue(viewModel.canNavigatePrevious)
    }

    // MARK: - View Mode Tests

    func testViewModeToggle() {
        // Given
        XCTAssertEqual(viewModel.viewMode, .unified)

        // When
        viewModel.viewMode = .sideBySide

        // Then
        XCTAssertEqual(viewModel.viewMode, .sideBySide)
    }

    // MARK: - Options Tests

    func testShowWhitespaceToggle() {
        // Given
        XCTAssertFalse(viewModel.showWhitespace)

        // When
        viewModel.showWhitespace = true

        // Then
        XCTAssertTrue(viewModel.showWhitespace)
    }

    func testShowLineNumbersToggle() {
        // Given
        XCTAssertTrue(viewModel.showLineNumbers)

        // When
        viewModel.showLineNumbers = false

        // Then
        XCTAssertFalse(viewModel.showLineNumbers)
    }

    func testShowStagedToggle() {
        // Given
        XCTAssertFalse(viewModel.showStaged)

        // When
        viewModel.showStaged = true

        // Then
        XCTAssertTrue(viewModel.showStaged)
    }

    // MARK: - Error Handling Tests

    func testClearError() {
        // Given
        viewModel.error = GitError.commandFailed("Test error")
        XCTAssertNotNil(viewModel.error)

        // When
        viewModel.clearError()

        // Then
        XCTAssertNil(viewModel.error)
    }

    // MARK: - Helper Methods

    private func createTestDiff(
        filePath: String,
        additions: Int = 1,
        deletions: Int = 1
    ) -> GitDiff {
        let additionLines = (0 ..< additions).map { index in
            GitDiffLine.addition(newLineNumber: index + 1, content: "Added line \(index + 1)")
        }

        let deletionLines = (0 ..< deletions).map { index in
            GitDiffLine.deletion(oldLineNumber: index + 1, content: "Deleted line \(index + 1)")
        }

        let chunk = GitDiffChunk(
            oldStart: 1,
            oldCount: deletions,
            newStart: 1,
            newCount: additions,
            lines: deletionLines + additionLines,
            headerLine: "@@ -1,\(deletions) +1,\(additions) @@"
        )

        return GitDiff(
            filePath: filePath,
            changeType: .modified,
            chunks: [chunk]
        )
    }

    private func createBinaryTestDiff(filePath: String) -> GitDiff {
        GitDiff.binaryFile(
            filePath: filePath,
            changeType: .modified
        )
    }
}

// MARK: - DiffViewMode Tests

final class DiffViewModeTests: XCTestCase {
    func testAllCases() {
        let modes = DiffViewMode.allCases
        XCTAssertEqual(modes.count, 2)
        XCTAssertTrue(modes.contains(.unified))
        XCTAssertTrue(modes.contains(.sideBySide))
    }

    func testDisplayNames() {
        XCTAssertEqual(DiffViewMode.unified.displayName, "Unified")
        XCTAssertEqual(DiffViewMode.sideBySide.displayName, "Side by Side")
    }

    func testIcons() {
        XCTAssertEqual(DiffViewMode.unified.icon, "list.bullet")
        XCTAssertEqual(DiffViewMode.sideBySide.icon, "rectangle.split.2x1")
    }

    func testIdentifiable() {
        XCTAssertEqual(DiffViewMode.unified.id, "unified")
        XCTAssertEqual(DiffViewMode.sideBySide.id, "sideBySide")
    }
}
