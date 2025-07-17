//
// GitSecurityAuditTests.swift
// GitCthulhu
//
// Created by GitCthulhu Team on 2025-07-12.
//

import Foundation
@testable import GitCore
import Testing

struct GitSecurityAuditTests {
    // MARK: - Security Audit Tests

    @Test("Security audit - secure configuration")
    func securityAuditSecureConfiguration() async throws {
        let config = GitSecurityConfig.shared
        config.resetToDefaults()

        let auditResult = config.performSecurityAudit()

        #expect(auditResult.securityLevel == .high)
        #expect(auditResult.issues.isEmpty)
        #expect(auditResult.isSecure == true)
    }

    @Test("Security audit - insecure configuration")
    func securityAuditInsecureConfiguration() async throws {
        let config = GitSecurityConfig.shared
        config.resetToDefaults()
        config.resetToDefaults()

        // Make configuration insecure
        config.allowHTTPProtocol = true
        config.allowLocalFileAccess = true
        config.strictAuthorValidation = false
        config.allowEmptyCommitMessages = true
        config.maxCommitMessageLength = 15000

        let auditResult = config.performSecurityAudit()

        #expect(auditResult.securityLevel == .low)
        #expect(!auditResult.issues.isEmpty)
        #expect(auditResult.isSecure == false)
        #expect(!auditResult.recommendations.isEmpty)
    }

    @Test("Security audit - medium security")
    func securityAuditMediumSecurity() async throws {
        let config = GitSecurityConfig.shared
        config.resetToDefaults()

        // Make configuration slightly insecure
        config.allowHTTPProtocol = true

        let auditResult = config.performSecurityAudit()

        #expect(auditResult.securityLevel == .medium)
        #expect(auditResult.issues.count == 1)
        #expect(!auditResult.isSecure)
    }

    @Test("Security audit issues description")
    func securityAuditIssuesDescription() async throws {
        let config = GitSecurityConfig.shared
        config.resetToDefaults()
        config.allowHTTPProtocol = true
        config.allowLocalFileAccess = true

        let auditResult = config.performSecurityAudit()

        for issue in auditResult.issues {
            #expect(!issue.description.isEmpty)
        }

        for recommendation in auditResult.recommendations {
            #expect(!recommendation.isEmpty)
        }
    }

    // MARK: - Edge Cases and Integration Tests

    @Test("Whitespace handling in validation")
    func whitespaceHandlingInValidation() async throws {
        let config = GitSecurityConfig.shared
        config.resetToDefaults()

        let inputWithWhitespace = "  test input  "
        let sanitized = try config.validateInput(inputWithWhitespace, type: .general)

        #expect(sanitized == "test input") // Should be trimmed
    }

    @Test("Case sensitivity in protocol validation")
    func caseSensitivityInProtocolValidation() async throws {
        let config = GitSecurityConfig.shared
        config.resetToDefaults()

        let mixedCaseURLs = [
            "HTTPS://github.com/test/repo.git",
            "Git@github.com:test/repo.git",
            "SSH://git@github.com/test/repo.git"
        ]

        for url in mixedCaseURLs {
            #expect(config.isProtocolAllowed(url))
        }
    }

    @Test("Concurrent access safety")
    func concurrentAccessSafety() async throws {
        let config = GitSecurityConfig.shared

        // Test concurrent reads and writes
        await withTaskGroup(of: Void.self) { group in
            for _ in 0 ..< 10 {
                group.addTask {
                    config.resetToDefaults()
                    _ = config.isProtocolAllowed("https://example.com")
                    config.applyStrictProfile()
                    _ = config.performSecurityAudit()
                }
            }
        }

        #expect(true) // If we get here, no crashes occurred
    }
}
