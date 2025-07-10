@testable import GitCthulhu
import SwiftUI
import Testing

struct ContentViewTests {
    @Test func contentViewExists() async throws {
        let contentView = ContentView()
        #expect(contentView != nil)
    }
}
