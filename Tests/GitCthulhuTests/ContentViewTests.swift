//
// ContentViewTests.swift
// GitCthulhu
//
// Created by GitCthulhu Team on 2025-07-11.
//

@testable import GitCthulhu
import SwiftUI
import Testing

struct ContentViewTests {
    @Test
    func contentViewExists() async throws {
        let contentView = ContentView()
        #expect(contentView != nil)
    }
}
