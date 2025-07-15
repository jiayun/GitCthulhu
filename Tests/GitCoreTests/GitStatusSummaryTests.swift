//
// GitStatusSummaryTests.swift
// GitCthulhu
//
// Created by GitCthulhu Team on 2025-07-15.
//

@testable import GitCore
import XCTest

final class GitStatusSummaryTests: XCTestCase {
    func testCleanRepository() {
        let summary = GitStatusSummary(
            stagedCount: 0,
            unstagedCount: 0,
            untrackedCount: 0,
            conflictedCount: 0,
            isClean: true
        )

        XCTAssertTrue(summary.isClean)
        XCTAssertFalse(summary.hasChanges)
        XCTAssertEqual(summary.totalChanges, 0)
        XCTAssertEqual(summary.statusMessage, "Working directory clean")
    }

    func testRepositoryWithChanges() {
        let summary = GitStatusSummary(
            stagedCount: 2,
            unstagedCount: 1,
            untrackedCount: 3,
            conflictedCount: 0,
            isClean: false
        )

        XCTAssertFalse(summary.isClean)
        XCTAssertTrue(summary.hasChanges)
        XCTAssertEqual(summary.totalChanges, 6)
        XCTAssertEqual(summary.statusMessage, "2 staged, 1 unstaged, 3 untracked")
    }

    func testRepositoryWithConflicts() {
        let summary = GitStatusSummary(
            stagedCount: 1,
            unstagedCount: 0,
            untrackedCount: 0,
            conflictedCount: 2,
            isClean: false
        )

        XCTAssertFalse(summary.isClean)
        XCTAssertTrue(summary.hasChanges)
        XCTAssertEqual(summary.totalChanges, 1)
        XCTAssertEqual(summary.statusMessage, "1 staged, 2 conflicted")
    }

    func testRepositoryWithOnlyStaged() {
        let summary = GitStatusSummary(
            stagedCount: 3,
            unstagedCount: 0,
            untrackedCount: 0,
            conflictedCount: 0,
            isClean: false
        )

        XCTAssertFalse(summary.isClean)
        XCTAssertTrue(summary.hasChanges)
        XCTAssertEqual(summary.totalChanges, 3)
        XCTAssertEqual(summary.statusMessage, "3 staged")
    }

    func testRepositoryWithOnlyUnstaged() {
        let summary = GitStatusSummary(
            stagedCount: 0,
            unstagedCount: 2,
            untrackedCount: 0,
            conflictedCount: 0,
            isClean: false
        )

        XCTAssertFalse(summary.isClean)
        XCTAssertTrue(summary.hasChanges)
        XCTAssertEqual(summary.totalChanges, 2)
        XCTAssertEqual(summary.statusMessage, "2 unstaged")
    }

    func testRepositoryWithOnlyUntracked() {
        let summary = GitStatusSummary(
            stagedCount: 0,
            unstagedCount: 0,
            untrackedCount: 1,
            conflictedCount: 0,
            isClean: false
        )

        XCTAssertFalse(summary.isClean)
        XCTAssertTrue(summary.hasChanges)
        XCTAssertEqual(summary.totalChanges, 1)
        XCTAssertEqual(summary.statusMessage, "1 untracked")
    }

    func testRepositoryWithOnlyConflicts() {
        let summary = GitStatusSummary(
            stagedCount: 0,
            unstagedCount: 0,
            untrackedCount: 0,
            conflictedCount: 1,
            isClean: false
        )

        XCTAssertFalse(summary.isClean)
        XCTAssertTrue(summary.hasChanges)
        XCTAssertEqual(summary.totalChanges, 0)
        XCTAssertEqual(summary.statusMessage, "1 conflicted")
    }

    func testStatusMessageOrder() {
        let summary = GitStatusSummary(
            stagedCount: 1,
            unstagedCount: 2,
            untrackedCount: 3,
            conflictedCount: 4,
            isClean: false
        )

        // Should be in order: staged, unstaged, untracked, conflicted
        XCTAssertEqual(summary.statusMessage, "1 staged, 2 unstaged, 3 untracked, 4 conflicted")
    }

    func testStatusMessageWithMixedCounts() {
        let summary = GitStatusSummary(
            stagedCount: 1,
            unstagedCount: 0,
            untrackedCount: 2,
            conflictedCount: 0,
            isClean: false
        )

        // Should only show non-zero counts
        XCTAssertEqual(summary.statusMessage, "1 staged, 2 untracked")
    }
}
