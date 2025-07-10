//
// GitErrorTests.swift
// GitCthulhu
//
// Created by GitCthulhu Team on 2025-07-11.
//

import Foundation
@testable import GitCore
import Testing

struct GitErrorTests {
    @Test
    func gitErrorDescriptions() async throws {
        let repositoryError = GitError.failedToOpenRepository("test error")
        #expect(repositoryError.errorDescription == "Failed to open repository: test error")

        let pathError = GitError.invalidRepositoryPath
        #expect(pathError.errorDescription == "Invalid repository path")

        let fileError = GitError.fileNotFound("/path/to/file")
        #expect(fileError.errorDescription == "File not found: /path/to/file")
    }
}
