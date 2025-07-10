import Testing
import SwiftUI
@testable import UIKit

struct EmptyStateTests {

    @Test func emptyStateCreation() async throws {
        let emptyState = EmptyState(
            title: "Test Title",
            subtitle: "Test Subtitle",
            systemImage: "folder"
        )

        #expect(emptyState != nil)
    }
}
