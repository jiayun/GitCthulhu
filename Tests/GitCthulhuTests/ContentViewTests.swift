import Testing
import SwiftUI
@testable import GitCthulhu

struct ContentViewTests {
    
    @Test func contentViewExists() async throws {
        let contentView = ContentView()
        #expect(contentView != nil)
    }
}