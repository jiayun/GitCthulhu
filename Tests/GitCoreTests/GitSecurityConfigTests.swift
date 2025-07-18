//
// GitSecurityConfigTests.swift
// GitCthulhu
//
// Created by GitCthulhu Team on 2025-07-12.
//

import Foundation
@testable import GitCore
import Testing

@Suite(.serialized)
struct GitSecurityConfigTests {
    // MARK: - Initialization Tests

    @Test("Singleton instance")
    func singletonInstance() async throws {
        let config1 = GitSecurityConfig.shared
        let config2 = GitSecurityConfig.shared

        #expect(config1 === config2) // Should be the same instance
    }

    @Test("Default configuration values")
    func defaultConfigurationValues() async throws {
        let config = GitSecurityConfig.shared

        // Force a complete reset to ensure clean state
        config.resetToDefaults()

        // Verify length limits
        #expect(config.maxCommitMessageLength == 5000)
        #expect(config.maxAuthorLength == 255)
        #expect(config.maxBranchNameLength == 255)
        #expect(config.maxFilePathLength == 4096)
        #expect(config.maxInputLength == 1000)

        // Verify allowed protocols
        #expect(config.allowedProtocols.contains("https://"))
        #expect(config.allowedProtocols.contains("git://"))
        #expect(config.allowedProtocols.contains("ssh://"))
        #expect(config.allowedProtocols.contains("git@"))

        // Verify dangerous protocols
        #expect(config.dangerousProtocols.contains("file://"))
        #expect(config.dangerousProtocols.contains("ftp://"))
        #expect(config.dangerousProtocols.contains("javascript:"))
        #expect(config.dangerousProtocols.contains("data:"))
        #expect(config.dangerousProtocols.contains("http://"))

        #expect(config.allowLocalFileAccess == false)
        #expect(config.allowHTTPProtocol == false)
        #expect(config.strictAuthorValidation == true)
        #expect(config.allowEmptyCommitMessages == false)
        #expect(config.validateGitPath == true)
        #expect(config.maxDirectoryDepth == 10)
    }

    // MARK: - Protocol Validation Tests

    @Test("Protocol validation - allowed protocols")
    func protocolValidationAllowedProtocols() async throws {
        let config = GitSecurityConfig.shared
        config.resetToDefaults()

        let allowedURLs = [
            "https://github.com/user/repo.git",
            "git://github.com/user/repo.git",
            "ssh://git@github.com/user/repo.git",
            "git@github.com:user/repo.git"
        ]

        for url in allowedURLs {
            #expect(config.isProtocolAllowed(url) == true)
        }
    }

    @Test("Protocol validation - dangerous protocols")
    func protocolValidationDangerousProtocols() async throws {
        let config = GitSecurityConfig.shared
        config.resetToDefaults()

        let dangerousURLs = [
            "file:///local/path",
            "ftp://ftp.example.com/repo",
            "javascript:alert('xss')",
            "data:text/plain,malicious",
            "http://insecure.com/repo.git"
        ]

        for url in dangerousURLs {
            #expect(config.isProtocolAllowed(url) == false)
        }
    }

    @Test("Protocol validation - HTTP when allowed")
    func protocolValidationHTTPWhenAllowed() async throws {
        let config = GitSecurityConfig.shared
        config.resetToDefaults()
        config.allowHTTPProtocol = true

        #expect(config.isProtocolAllowed("http://example.com/repo.git") == true)

        config.allowHTTPProtocol = false
        #expect(config.isProtocolAllowed("http://example.com/repo.git") == false)
    }

    // MARK: - Character Validation Tests

    @Test("Dangerous character detection")
    func dangerousCharacterDetection() async throws {
        let config = GitSecurityConfig.shared
        config.resetToDefaults()

        let dangerousInputs = [
            "command; rm -rf /",
            "command | cat",
            "command & background",
            "command `backtick`",
            "command < input",
            "command > output"
        ]

        for input in dangerousInputs {
            #expect(config.containsDangerousChars(input) == true)
        }

        let safeInputs = [
            "normal command",
            "branch-name",
            "file_name.txt",
            "commit message"
        ]

        for input in safeInputs {
            #expect(config.containsDangerousChars(input) == false)
        }
    }

    @Test("Control character detection")
    func controlCharacterDetection() async throws {
        let config = GitSecurityConfig.shared
        config.resetToDefaults()

        let controlInputs = [
            "text with null\0byte",
            "text with\rcarriage return",
            "text with\nnewline"
        ]

        for input in controlInputs {
            #expect(config.containsControlChars(input) == true)
        }

        #expect(config.containsControlChars("normal text") == false)
    }

    @Test("Invalid branch character detection")
    func invalidBranchCharacterDetection() async throws {
        let config = GitSecurityConfig.shared
        config.resetToDefaults()

        let invalidBranchNames = [
            "branch with spaces",
            "branch~with~tildes",
            "branch^with^carets",
            "branch:with:colons",
            "branch?with?questions",
            "branch*with*asterisks",
            "branch[with]brackets",
            "branch\\with\\backslashes"
        ]

        for name in invalidBranchNames {
            #expect(config.containsInvalidBranchChars(name) == true)
        }

        let validBranchNames = [
            "valid-branch",
            "feature/new-login",
            "hotfix_123",
            "dev"
        ]

        for name in validBranchNames {
            #expect(config.containsInvalidBranchChars(name) == false)
        }
    }

    // MARK: - Suspicious Pattern Tests

    @Test("Suspicious pattern detection")
    func suspiciousPatternDetection() async throws {
        let config = GitSecurityConfig.shared
        config.resetToDefaults()

        let suspiciousArgs = [
            "--exec=evil",
            "--upload-pack=malicious",
            "--receive-pack=bad"
        ]

        for arg in suspiciousArgs {
            #expect(config.isSuspiciousPattern(arg) == true)
        }

        let normalArgs = [
            "--porcelain",
            "--oneline",
            "--all",
            "status"
        ]

        for arg in normalArgs {
            #expect(config.isSuspiciousPattern(arg) == false)
        }
    }

    // MARK: - Path Depth Validation Tests

    @Test("Path depth validation")
    func pathDepthValidation() async throws {
        let config = GitSecurityConfig.shared
        config.resetToDefaults()
        config.maxDirectoryDepth = 3

        // Valid paths
        let validPaths = [
            "file.txt",
            "dir/file.txt",
            "dir1/dir2/file.txt",
            "dir1/dir2/dir3/file.txt" // Exactly at limit
        ]

        for path in validPaths {
            #expect(config.isPathDepthValid(path) == true)
        }

        // Invalid paths (too deep)
        let invalidPaths = [
            "dir1/dir2/dir3/dir4/file.txt",
            "a/b/c/d/e/f/g/h/i/j/file.txt"
        ]

        for path in invalidPaths {
            #expect(config.isPathDepthValid(path) == false)
        }
    }

    // MARK: - Input Validation Tests

    @Test("Input validation by type")
    func inputValidationByType() async throws {
        let config = GitSecurityConfig.shared
        config.resetToDefaults()

        // Test commit message validation
        let validCommit = "Valid commit message"
        let sanitizedCommit = try config.validateInput(validCommit, type: .commitMessage)
        #expect(sanitizedCommit == validCommit)

        // Test empty commit message when not allowed
        #expect(throws: GitError.self) {
            _ = try config.validateInput("", type: .commitMessage)
        }

        // Test branch name validation
        let validBranch = "feature-branch"
        let sanitizedBranch = try config.validateInput(validBranch, type: .branchName)
        #expect(sanitizedBranch == validBranch)

        // Test invalid branch name
        #expect(throws: GitError.self) {
            _ = try config.validateInput("invalid branch", type: .branchName)
        }

        // Test file path validation
        let validPath = "src/main.swift"
        let sanitizedPath = try config.validateInput(validPath, type: .filePath)
        #expect(sanitizedPath == validPath)

        // Test author validation
        let validAuthor = "John Doe <john@example.com>"
        let sanitizedAuthor = try config.validateInput(validAuthor, type: .author)
        #expect(sanitizedAuthor == validAuthor)

        // Test general input validation
        let validInput = "general input"
        let sanitizedInput = try config.validateInput(validInput, type: .general)
        #expect(sanitizedInput == validInput)
    }

    @Test("Input validation length limits")
    func inputValidationLengthLimits() async throws {
        let config = GitSecurityConfig.shared
        config.resetToDefaults()

        // Store original value for cleanup
        let originalMaxLength = config.maxCommitMessageLength
        config.maxCommitMessageLength = 10

        defer {
            // Restore original value to avoid affecting other tests
            config.maxCommitMessageLength = originalMaxLength
        }

        // Should pass
        let shortMessage = "short"
        let sanitized = try config.validateInput(shortMessage, type: .commitMessage)
        #expect(sanitized == shortMessage)

        // Should fail (too long)
        let longMessage = "this message is way too long"
        #expect(throws: GitError.self) {
            _ = try config.validateInput(longMessage, type: .commitMessage)
        }
    }

    // MARK: - Security Profile Tests

    @Test("Strict security profile")
    func strictSecurityProfile() async throws {
        let config = GitSecurityConfig.shared
        config.resetToDefaults() // Start with clean state

        config.applyStrictProfile()

        #expect(config.maxCommitMessageLength == 2000)
        #expect(config.maxAuthorLength == 128)
        #expect(config.maxBranchNameLength == 100)
        #expect(config.maxDirectoryDepth == 5)

        #expect(config.allowedProtocols.contains("https://"))
        #expect(config.allowedProtocols.contains("ssh://"))
        #expect(!config.allowedProtocols.contains("git://")) // Should be removed in strict mode

        #expect(config.allowLocalFileAccess == false)
        #expect(config.allowHTTPProtocol == false)
        #expect(config.strictAuthorValidation == true)
        #expect(config.allowEmptyCommitMessages == false)

        // Reset to defaults after test to avoid affecting other tests
        config.resetToDefaults()
    }

    @Test("Permissive security profile")
    func permissiveSecurityProfile() async throws {
        let config = GitSecurityConfig.shared

        // Force complete reset and apply permissive profile
        config.resetToDefaults()
        config.applyPermissiveProfile()

        // Verify protocol sets are correctly configured for permissive mode
        #expect(
            config.allowedProtocols.contains("http://"),
            "HTTP should be in allowedProtocols for permissive mode"
        )
        #expect(
            !config.dangerousProtocols.contains("http://"),
            "HTTP should NOT be in dangerousProtocols for permissive mode"
        )

        // Verify the changes took effect immediately
        #expect(config.maxCommitMessageLength == 10000)
        #expect(config.maxAuthorLength == 512)
        #expect(config.maxBranchNameLength == 500)
        #expect(config.maxDirectoryDepth == 20)

        #expect(config.allowedProtocols.contains("http://"))
        #expect(!config.dangerousProtocols.contains("http://"))

        #expect(config.allowLocalFileAccess == true)
        #expect(config.allowHTTPProtocol == true)
        #expect(config.strictAuthorValidation == false)
        #expect(config.allowEmptyCommitMessages == true)
        #expect(config.validateGitPath == false)

        // Reset back to defaults after test to avoid affecting other tests
        config.resetToDefaults()
    }

    @Test("Reset to defaults")
    func resetToDefaults() async throws {
        let config = GitSecurityConfig.shared

        // Apply permissive profile first
        config.applyPermissiveProfile()
        #expect(config.allowHTTPProtocol == true)

        // Reset to defaults
        config.resetToDefaults()
        #expect(config.allowHTTPProtocol == false)
        #expect(config.maxCommitMessageLength == 5000)
        #expect(config.strictAuthorValidation == true)
    }
}
