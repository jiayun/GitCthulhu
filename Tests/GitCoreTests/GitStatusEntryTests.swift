//
// GitStatusEntryTests.swift
// GitCthulhu
//
// Created by GitCthulhu Team on 2025-07-15.
//

import XCTest
@testable import GitCore

final class GitStatusEntryTests: XCTestCase {

    func testFromPorcelainLine_ModifiedFile() {
        let line = " M test.txt"
        let entry = GitStatusEntry.fromPorcelainLine(line)

        XCTAssertNotNil(entry)
        XCTAssertEqual(entry?.filePath, "test.txt")
        XCTAssertEqual(entry?.indexStatus, .unmodified)
        XCTAssertEqual(entry?.workingDirectoryStatus, .modified)
        XCTAssertEqual(entry?.displayStatus, .modified)
        XCTAssertFalse(entry?.isStaged ?? true)
        XCTAssertTrue(entry?.hasWorkingDirectoryChanges ?? false)
    }

    func testFromPorcelainLine_AddedFile() {
        let line = "A  new_file.txt"
        let entry = GitStatusEntry.fromPorcelainLine(line)

        XCTAssertNotNil(entry)
        XCTAssertEqual(entry?.filePath, "new_file.txt")
        XCTAssertEqual(entry?.indexStatus, .added)
        XCTAssertEqual(entry?.workingDirectoryStatus, .unmodified)
        XCTAssertEqual(entry?.displayStatus, .added)
        XCTAssertTrue(entry?.isStaged ?? false)
        XCTAssertFalse(entry?.hasWorkingDirectoryChanges ?? true)
    }

    func testFromPorcelainLine_UntrackedFile() {
        let line = "?? untracked.txt"
        let entry = GitStatusEntry.fromPorcelainLine(line)

        XCTAssertNotNil(entry)
        XCTAssertEqual(entry?.filePath, "untracked.txt")
        XCTAssertEqual(entry?.indexStatus, .unmodified)
        XCTAssertEqual(entry?.workingDirectoryStatus, .untracked)
        XCTAssertEqual(entry?.displayStatus, .untracked)
        XCTAssertTrue(entry?.isUntracked ?? false)
        XCTAssertFalse(entry?.isStaged ?? true)
    }

    func testFromPorcelainLine_DeletedFile() {
        let line = " D deleted.txt"
        let entry = GitStatusEntry.fromPorcelainLine(line)

        XCTAssertNotNil(entry)
        XCTAssertEqual(entry?.filePath, "deleted.txt")
        XCTAssertEqual(entry?.indexStatus, .unmodified)
        XCTAssertEqual(entry?.workingDirectoryStatus, .deleted)
        XCTAssertEqual(entry?.displayStatus, .deleted)
        XCTAssertFalse(entry?.isStaged ?? true)
        XCTAssertTrue(entry?.hasWorkingDirectoryChanges ?? false)
    }

    func testFromPorcelainLine_StagedAndModified() {
        let line = "MM both_changed.txt"
        let entry = GitStatusEntry.fromPorcelainLine(line)

        XCTAssertNotNil(entry)
        XCTAssertEqual(entry?.filePath, "both_changed.txt")
        XCTAssertEqual(entry?.indexStatus, .modified)
        XCTAssertEqual(entry?.workingDirectoryStatus, .modified)
        XCTAssertEqual(entry?.displayStatus, .modified)
        XCTAssertTrue(entry?.isStaged ?? false)
        XCTAssertTrue(entry?.hasWorkingDirectoryChanges ?? false)
    }

    func testFromPorcelainLine_RenamedFile() {
        let line = "R  old_name.txt -> new_name.txt"
        let entry = GitStatusEntry.fromPorcelainLine(line)

        XCTAssertNotNil(entry)
        XCTAssertEqual(entry?.filePath, "new_name.txt")
        XCTAssertEqual(entry?.originalFilePath, "old_name.txt")
        XCTAssertEqual(entry?.indexStatus, .renamed)
        XCTAssertEqual(entry?.workingDirectoryStatus, .unmodified)
        XCTAssertEqual(entry?.displayStatus, .renamed)
        XCTAssertTrue(entry?.isStaged ?? false)
    }

    func testFromPorcelainLine_UnmergedFile() {
        let line = "UU conflicted.txt"
        let entry = GitStatusEntry.fromPorcelainLine(line)

        XCTAssertNotNil(entry)
        XCTAssertEqual(entry?.filePath, "conflicted.txt")
        XCTAssertEqual(entry?.indexStatus, .unmerged)
        XCTAssertEqual(entry?.workingDirectoryStatus, .unmerged)
        XCTAssertEqual(entry?.displayStatus, .unmerged)
        XCTAssertTrue(entry?.hasConflicts ?? false)
    }

    func testFromPorcelainLine_InvalidLine() {
        let line = "X"
        let entry = GitStatusEntry.fromPorcelainLine(line)

        XCTAssertNil(entry)
    }

    func testFromPorcelainLine_EmptyLine() {
        let line = ""
        let entry = GitStatusEntry.fromPorcelainLine(line)

        XCTAssertNil(entry)
    }

    func testGitIndexStatus_FromStatusChar() {
        XCTAssertEqual(GitIndexStatus.fromStatusChar(" "), .unmodified)
        XCTAssertEqual(GitIndexStatus.fromStatusChar("A"), .added)
        XCTAssertEqual(GitIndexStatus.fromStatusChar("M"), .modified)
        XCTAssertEqual(GitIndexStatus.fromStatusChar("D"), .deleted)
        XCTAssertEqual(GitIndexStatus.fromStatusChar("R"), .renamed)
        XCTAssertEqual(GitIndexStatus.fromStatusChar("C"), .copied)
        XCTAssertEqual(GitIndexStatus.fromStatusChar("U"), .unmerged)
        XCTAssertEqual(GitIndexStatus.fromStatusChar("X"), .modified) // fallback
    }

    func testGitWorkingDirectoryStatus_FromStatusChar() {
        XCTAssertEqual(GitWorkingDirectoryStatus.fromStatusChar(" "), .unmodified)
        XCTAssertEqual(GitWorkingDirectoryStatus.fromStatusChar("M"), .modified)
        XCTAssertEqual(GitWorkingDirectoryStatus.fromStatusChar("D"), .deleted)
        XCTAssertEqual(GitWorkingDirectoryStatus.fromStatusChar("?"), .untracked)
        XCTAssertEqual(GitWorkingDirectoryStatus.fromStatusChar("!"), .ignored)
        XCTAssertEqual(GitWorkingDirectoryStatus.fromStatusChar("U"), .unmerged)
        XCTAssertEqual(GitWorkingDirectoryStatus.fromStatusChar("Z"), .modified) // fallback
    }

    func testDisplayStatus_Priority() {
        // Test priority: unmerged > staged > working directory
        let unmergedEntry = GitStatusEntry(
            filePath: "test.txt",
            indexStatus: .unmerged,
            workingDirectoryStatus: .modified
        )
        XCTAssertEqual(unmergedEntry.displayStatus, .unmerged)

        let stagedEntry = GitStatusEntry(
            filePath: "test.txt",
            indexStatus: .added,
            workingDirectoryStatus: .modified
        )
        XCTAssertEqual(stagedEntry.displayStatus, .added)

        let workingEntry = GitStatusEntry(
            filePath: "test.txt",
            indexStatus: .unmodified,
            workingDirectoryStatus: .modified
        )
        XCTAssertEqual(workingEntry.displayStatus, .modified)
    }

    func testEquatable() {
        let entry1 = GitStatusEntry(
            filePath: "test.txt",
            indexStatus: .added,
            workingDirectoryStatus: .unmodified
        )

        let entry2 = GitStatusEntry(
            filePath: "test.txt",
            indexStatus: .added,
            workingDirectoryStatus: .unmodified
        )

        let entry3 = GitStatusEntry(
            filePath: "different.txt",
            indexStatus: .added,
            workingDirectoryStatus: .unmodified
        )

        XCTAssertEqual(entry1, entry2)
        XCTAssertNotEqual(entry1, entry3)
    }

    func testHashable() {
        let entry1 = GitStatusEntry(
            filePath: "test.txt",
            indexStatus: .added,
            workingDirectoryStatus: .unmodified
        )

        let entry2 = GitStatusEntry(
            filePath: "test.txt",
            indexStatus: .added,
            workingDirectoryStatus: .unmodified
        )

        let set = Set([entry1, entry2])
        XCTAssertEqual(set.count, 1)
    }
}
