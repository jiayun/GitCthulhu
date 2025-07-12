//
// GitInputValidatorTests.swift
// GitCthulhu
//
// Created by GitCthulhu Team on 2025-07-12.
//

import Foundation
@testable import GitCore
import Testing

struct GitInputValidatorTests {
    // MARK: - Argument Validation Tests

    @Test("Valid arguments pass validation")
    func validArgumentsPassValidation() async throws {
        let validArgs = ["status", "--porcelain", "branch", "-a", "log", "--oneline"]

        // Should not throw
        try GitInputValidator.validateArguments(validArgs)
    }

    @Test("Arguments with null bytes are rejected")
    func argumentsWithNullBytesAreRejected() async throws {
        let invalidArgs = ["status\0malicious"]

        #expect(throws: GitError.self) {
            try GitInputValidator.validateArguments(invalidArgs)
        }
    }

    @Test("Arguments with dangerous characters are rejected")
    func argumentsWithDangerousCharactersAreRejected() async throws {
        let dangerousArgs = ["status; rm -rf /", "branch | cat", "log && evil"]

        for arg in dangerousArgs {
            #expect(throws: GitError.self) {
                try GitInputValidator.validateArguments([arg])
            }
        }
    }

    @Test("Arguments with suspicious patterns are rejected")
    func argumentsWithSuspiciousPatternsAreRejected() async throws {
        let suspiciousArgs = ["--exec=evil", "--upload-pack=malicious", "--receive-pack=bad"]

        for arg in suspiciousArgs {
            #expect(throws: GitError.self) {
                try GitInputValidator.validateArguments([arg])
            }
        }
    }

    // MARK: - Branch Name Validation Tests

    @Test("Valid branch names pass validation")
    func validBranchNamesPassValidation() async throws {
        let validNames = ["main", "feature/new-login", "hotfix-123", "dev_branch"]

        for name in validNames {
            let sanitized = try GitInputValidator.sanitizeBranchName(name)
            #expect(sanitized == name)
        }
    }

    @Test("Invalid branch names are rejected")
    func invalidBranchNamesAreRejected() async throws {
        let invalidNames = [
            "branch with spaces",
            "branch~with~tildes",
            "branch^with^carets",
            "branch:with:colons",
            "branch?with?questions",
            "branch*with*asterisks",
            "branch[with]brackets",
            "branch\\with\\backslashes",
            ".hidden-start",
            "hidden-end.",
            "-dash-start",
            "double..dots",
            "at@{curly}",
            ""
        ]

        for name in invalidNames {
            #expect(throws: GitError.self) {
                _ = try GitInputValidator.sanitizeBranchName(name)
            }
        }
    }

    // MARK: - File Path Validation Tests

    @Test("Valid file paths pass validation")
    func validFilePathsPassValidation() async throws {
        let validPaths = ["src/main.swift", "docs/README.md", "config.json"]

        for path in validPaths {
            let sanitized = try GitInputValidator.sanitizeFilePath(path)
            #expect(sanitized == path)
        }
    }

    @Test("Path traversal attempts are rejected")
    func pathTraversalAttemptsAreRejected() async throws {
        let maliciousPaths = ["../../../etc/passwd", "..\\windows\\system32", "/absolute/path"]

        for path in maliciousPaths {
            #expect(throws: GitError.self) {
                _ = try GitInputValidator.sanitizeFilePath(path)
            }
        }
    }

    // MARK: - Commit Message Validation Tests

    @Test("Valid commit messages pass validation")
    func validCommitMessagesPassValidation() async throws {
        let validMessages = [
            "Add new feature",
            "Fix bug in authentication\n\nDetailed explanation here",
            "Update documentation with examples"
        ]

        for message in validMessages {
            let sanitized = try GitInputValidator.sanitizeCommitMessage(message)
            #expect(!sanitized.isEmpty)
        }
    }

    @Test("Invalid commit messages are rejected")
    func invalidCommitMessagesAreRejected() async throws {
        let invalidMessages = [
            "",
            "   ",
            "\n\n\n",
            "Message with null byte\0",
            String(repeating: "a", count: 5001) // Too long
        ]

        for message in invalidMessages {
            #expect(throws: GitError.self) {
                _ = try GitInputValidator.sanitizeCommitMessage(message)
            }
        }
    }

    // MARK: - Author Validation Tests

    @Test("Valid authors pass validation")
    func validAuthorsPassValidation() async throws {
        let validAuthors = [
            "John Doe <john@example.com>",
            "Jane Smith <jane.smith@company.org>",
            "Developer",
            "Test User <test+dev@domain.co.uk>"
        ]

        for author in validAuthors {
            let sanitized = try GitInputValidator.sanitizeAuthor(author)
            #expect(!sanitized.isEmpty)
        }
    }

    @Test("Invalid authors are rejected")
    func invalidAuthorsAreRejected() async throws {
        let invalidAuthors = [
            "",
            "   ",
            "Author with null\0byte",
            "Author with\nNewline",
            "Author with\rReturn",
            "Invalid Email <not-an-email>",
            "Malformed <email@>",
            "<@domain.com>",
            String(repeating: "a", count: 256) // Too long
        ]

        for author in invalidAuthors {
            #expect(throws: GitError.self) {
                _ = try GitInputValidator.sanitizeAuthor(author)
            }
        }
    }

    // MARK: - Remote URL Validation Tests

    @Test("Valid remote URLs pass validation")
    func validRemoteURLsPassValidation() async throws {
        let validURLs = [
            "https://github.com/user/repo.git",
            "git://github.com/user/repo.git",
            "ssh://git@github.com/user/repo.git",
            "git@github.com:user/repo.git"
        ]

        for url in validURLs {
            let validated = try GitInputValidator.validateRemoteURL(url)
            #expect(validated == url)
        }
    }

    @Test("Invalid remote URLs are rejected")
    func invalidRemoteURLsAreRejected() async throws {
        let invalidURLs = [
            "",
            "   ",
            "http://insecure.com/repo.git", // http not allowed
            "file:///local/path",
            "ftp://ftp.example.com/repo",
            "javascript:alert('xss')",
            "data:text/plain,malicious",
            "url with null\0byte",
            "url with\nnewline"
        ]

        for url in invalidURLs {
            #expect(throws: GitError.self) {
                _ = try GitInputValidator.validateRemoteURL(url)
            }
        }
    }

    // MARK: - Git Path Validation Tests

    @Test("Git path detection")
    func gitPathDetection() async throws {
        // Should not throw and return a path
        let gitPath = try GitInputValidator.detectGitPath()
        #expect(!gitPath.isEmpty)
    }

    @Test("Valid git paths pass validation")
    func validGitPathsPassValidation() async throws {
        let validPaths = [
            "git",
            "/usr/bin/git",
            "/usr/local/bin/git",
            "/opt/homebrew/bin/git"
        ]

        for path in validPaths {
            let validated = try GitInputValidator.validateGitPath(path)
            #expect(validated == path)
        }
    }

    @Test("Invalid git paths are rejected")
    func invalidGitPathsAreRejected() async throws {
        let invalidPaths = [
            "",
            "   ",
            "../evil/git",
            "git; rm -rf /",
            "git | cat",
            "git && malicious",
            "relative/path/git"
        ]

        for path in invalidPaths {
            #expect(throws: GitError.self) {
                _ = try GitInputValidator.validateGitPath(path)
            }
        }
    }

    // MARK: - Repository Path Validation Tests

    @Test("Valid repository path validation")
    func validRepositoryPathValidation() async throws {
        // Use current directory which should exist
        let currentDir = FileManager.default.currentDirectoryPath

        let validated = try GitInputValidator.validateRepositoryPath(currentDir)
        #expect(!validated.isEmpty)
        #expect(validated.hasPrefix("/")) // Should be absolute
    }

    @Test("Invalid repository paths are rejected")
    func invalidRepositoryPathsAreRejected() async throws {
        let invalidPaths = [
            "",
            "   ",
            "/nonexistent/path/\(UUID().uuidString)",
            "path with null\0byte",
            "path with\nnewline"
        ]

        for path in invalidPaths {
            #expect(throws: GitError.self) {
                _ = try GitInputValidator.validateRepositoryPath(path)
            }
        }
    }

    // MARK: - General Input Sanitization Tests

    @Test("Valid inputs pass general sanitization")
    func validInputsPassGeneralSanitization() async throws {
        let validInputs = [
            "normal text",
            "text-with-dashes",
            "text_with_underscores",
            "text.with.dots",
            "123456789"
        ]

        for input in validInputs {
            let sanitized = try GitInputValidator.sanitizeInput(input)
            #expect(sanitized == input.trimmingCharacters(in: .whitespacesAndNewlines))
        }
    }

    @Test("Invalid inputs are rejected by general sanitization")
    func invalidInputsAreRejectedByGeneralSanitization() async throws {
        let invalidInputs = [
            "input with null\0byte",
            "input with\nnewline",
            "input with\rreturn",
            String(repeating: "a", count: 1001) // Too long
        ]

        for input in invalidInputs {
            #expect(throws: GitError.self) {
                _ = try GitInputValidator.sanitizeInput(input)
            }
        }
    }

    @Test("Custom max length validation")
    func customMaxLengthValidation() async throws {
        let input = "This is a test input"

        // Should pass with sufficient length
        let sanitized1 = try GitInputValidator.sanitizeInput(input, maxLength: 50)
        #expect(sanitized1 == input)

        // Should fail with insufficient length
        #expect(throws: GitError.self) {
            _ = try GitInputValidator.sanitizeInput(input, maxLength: 10)
        }
    }
}
