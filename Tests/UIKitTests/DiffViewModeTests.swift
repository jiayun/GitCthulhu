//
// DiffViewModeTests.swift
// GitCthulhu
//
// Created by GitCthulhu Team on 2025-07-18.
//

import UIKit
import XCTest

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
