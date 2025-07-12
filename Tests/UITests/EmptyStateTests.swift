//
// EmptyStateTests.swift
// GitCthulhu
//
// Created by GitCthulhu Team on 2025-07-11.
//

import SwiftUI
import Testing
@testable import UIKit

@MainActor
struct EmptyStateTests {
    @Test
    func emptyStateCreation() async throws {
        let emptyState = EmptyState(
            title: "Test Title",
            subtitle: "Test Subtitle",
            systemImage: "folder"
        )

        #expect(emptyState != nil)
    }
}
