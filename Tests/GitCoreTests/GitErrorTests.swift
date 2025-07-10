import Testing
import Foundation
@testable import GitCore

struct GitErrorTests {
    
    @Test func gitErrorDescriptions() async throws {
        let repositoryError = GitError.failedToOpenRepository("test error")
        #expect(repositoryError.errorDescription == "Failed to open repository: test error")
        
        let pathError = GitError.invalidRepositoryPath
        #expect(pathError.errorDescription == "Invalid repository path")
        
        let fileError = GitError.fileNotFound("/path/to/file")
        #expect(fileError.errorDescription == "File not found: /path/to/file")
    }
}