//
// GitSecurityConfig.swift
// GitCthulhu
//
// Created by GitCthulhu Team on 2025-07-12.
//

import Foundation

/// Configuration class for Git security policies and validation rules
public class GitSecurityConfig {
    // MARK: - Singleton Pattern

    public static let shared = GitSecurityConfig()

    private init() {}

    // MARK: - Security Policy Configuration

    /// Maximum allowed length for commit messages
    public var maxCommitMessageLength: Int = 5000

    /// Maximum allowed length for author strings
    public var maxAuthorLength: Int = 255

    /// Maximum allowed length for branch names
    public var maxBranchNameLength: Int = 255

    /// Maximum allowed length for file paths
    public var maxFilePathLength: Int = 4096

    /// Maximum allowed length for general input validation
    public var maxInputLength: Int = 1000

    /// Allowed protocols for remote URLs
    public var allowedProtocols: Set<String> = ["https://", "git://", "ssh://", "git@"]

    /// Dangerous protocols that should be blocked
    public var dangerousProtocols: Set<String> = ["file://", "ftp://", "javascript:", "data:", "http://"]

    /// Suspicious argument patterns that should be blocked
    public var suspiciousPatterns: Set<String> = ["--exec", "--upload-pack", "--receive-pack"]

    /// Dangerous shell characters that should be blocked in arguments
    public var dangerousChars: CharacterSet = .init(charactersIn: ";|&$`<>")

    /// Control characters that should be blocked in inputs
    public var controlChars: CharacterSet = .init(charactersIn: "\0\r\n")

    /// Characters not allowed in branch names
    public var invalidBranchChars: CharacterSet = .init(charactersIn: " ~^:?*[\\")

    // MARK: - Permission Configuration

    /// Whether to allow local file protocol access
    public var allowLocalFileAccess: Bool = false

    /// Whether to allow HTTP (insecure) protocol
    public var allowHTTPProtocol: Bool = false

    /// Whether to enable strict author validation (email format required)
    public var strictAuthorValidation: Bool = true

    /// Whether to allow empty commit messages
    public var allowEmptyCommitMessages: Bool = false

    /// Whether to validate Git executable path
    public var validateGitPath: Bool = true

    /// Maximum depth for directory traversal detection
    public var maxDirectoryDepth: Int = 10

    // MARK: - Validation Methods

    /// Validates if a protocol is allowed
    public func isProtocolAllowed(_ protocolString: String) -> Bool {
        let lowercaseProtocol = protocolString.lowercased()

        // Validate protocol against dangerous patterns
        if dangerousProtocols.contains(where: { lowercaseProtocol.hasPrefix($0) }) {
            return false
        }

        // Special case for HTTP
        if lowercaseProtocol.hasPrefix("http://") {
            return allowHTTPProtocol
        }

        // Check if it's in allowed list
        return allowedProtocols.contains(where: { lowercaseProtocol.hasPrefix($0) })
    }

    /// Validates if an argument pattern is suspicious
    public func isSuspiciousPattern(_ argument: String) -> Bool {
        suspiciousPatterns.contains(where: { argument.hasPrefix($0) })
    }

    /// Validates if a string contains dangerous characters
    public func containsDangerousChars(_ input: String) -> Bool {
        input.rangeOfCharacter(from: dangerousChars) != nil
    }

    /// Validates if a string contains control characters
    public func containsControlChars(_ input: String) -> Bool {
        input.rangeOfCharacter(from: controlChars) != nil
    }

    /// Validates if a branch name contains invalid characters
    public func containsInvalidBranchChars(_ branchName: String) -> Bool {
        branchName.rangeOfCharacter(from: invalidBranchChars) != nil
    }

    /// Validates if a path is within allowed directory depth
    public func isPathDepthValid(_ path: String) -> Bool {
        let components = path.components(separatedBy: "/")
        let depth = components.filter { !$0.isEmpty && $0 != "." }.count
        return depth <= maxDirectoryDepth
    }

    // MARK: - Configuration Management

    /// Resets configuration to default values
    public func resetToDefaults() {
        maxCommitMessageLength = 5000
        maxAuthorLength = 255
        maxBranchNameLength = 255
        maxFilePathLength = 4096
        maxInputLength = 1000

        allowedProtocols = Set(["https://", "git://", "ssh://", "git@"])
        dangerousProtocols = Set(["file://", "ftp://", "javascript:", "data:", "http://"])
        suspiciousPatterns = Set(["--exec", "--upload-pack", "--receive-pack"])

        dangerousChars = CharacterSet(charactersIn: ";|&$`<>")
        controlChars = CharacterSet(charactersIn: "\0\r\n")
        invalidBranchChars = CharacterSet(charactersIn: " ~^:?*[\\")

        allowLocalFileAccess = false
        allowHTTPProtocol = false
        strictAuthorValidation = true
        allowEmptyCommitMessages = false
        validateGitPath = true
        maxDirectoryDepth = 10
    }

    /// Applies a strict security profile
    public func applyStrictProfile() {
        maxCommitMessageLength = 2000
        maxAuthorLength = 128
        maxBranchNameLength = 100
        maxFilePathLength = 1000
        maxInputLength = 500

        allowedProtocols = Set(["https://", "ssh://"]) // Only secure protocols
        dangerousProtocols.insert("git://") // Block insecure git protocol

        allowLocalFileAccess = false
        allowHTTPProtocol = false
        strictAuthorValidation = true
        allowEmptyCommitMessages = false
        validateGitPath = true
        maxDirectoryDepth = 5
    }

    /// Applies a permissive security profile (for development)
    public func applyPermissiveProfile() {
        maxCommitMessageLength = 10000
        maxAuthorLength = 512
        maxBranchNameLength = 500
        maxFilePathLength = 8192
        maxInputLength = 2000

        allowedProtocols.insert("http://")
        dangerousProtocols.remove("http://")

        allowLocalFileAccess = true
        allowHTTPProtocol = true
        strictAuthorValidation = false
        allowEmptyCommitMessages = true
        validateGitPath = false
        maxDirectoryDepth = 20
    }

    // MARK: - Validation Integration

    /// Validates input according to current security configuration
    public func validateInput(_ input: String, type: InputType) throws -> String {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)

        // Check control characters
        if containsControlChars(trimmed) {
            throw GitError.invalidRepositoryPath
        }

        // Check length based on type
        let maxLength: Int
        switch type {
        case .commitMessage:
            maxLength = maxCommitMessageLength
            if !allowEmptyCommitMessages, trimmed.isEmpty {
                throw GitError.commitFailed("Commit message cannot be empty")
            }
        case .author:
            maxLength = maxAuthorLength
        case .branchName:
            maxLength = maxBranchNameLength
            if containsInvalidBranchChars(trimmed) {
                throw GitError.invalidBranch("Branch name contains invalid characters")
            }
        case .filePath:
            maxLength = maxFilePathLength
            if !isPathDepthValid(trimmed) {
                throw GitError.fileNotFound("Path depth exceeds maximum allowed")
            }
        case .general:
            maxLength = maxInputLength
        }

        if trimmed.count > maxLength {
            throw GitError.invalidRepositoryPath
        }

        return trimmed
    }

    /// Input types for validation
    public enum InputType {
        case commitMessage
        case author
        case branchName
        case filePath
        case general
    }
}

// MARK: - Security Audit

/// Security audit functionality
public extension GitSecurityConfig {
    /// Performs a security audit of current configuration
    func performSecurityAudit() -> SecurityAuditResult {
        var issues: [SecurityIssue] = []
        var recommendations: [String] = []

        // Check for permissive settings
        if allowHTTPProtocol {
            issues.append(.insecureProtocol("HTTP protocol is allowed"))
            recommendations.append("Disable HTTP protocol and use HTTPS or SSH instead")
        }

        if allowLocalFileAccess {
            issues.append(.localFileAccess("Local file access is enabled"))
            recommendations.append("Disable local file access unless required for development")
        }

        if !strictAuthorValidation {
            issues.append(.weakValidation("Author validation is not strict"))
            recommendations.append("Enable strict author validation to ensure proper email format")
        }

        if allowEmptyCommitMessages {
            issues.append(.weakValidation("Empty commit messages are allowed"))
            recommendations.append("Require non-empty commit messages for better tracking")
        }

        if maxCommitMessageLength > 10000 {
            issues.append(.excessiveLimit("Commit message length limit is very high"))
            recommendations.append("Consider reducing commit message length limit")
        }

        if maxDirectoryDepth > 15 {
            issues.append(.excessiveLimit("Directory depth limit is very high"))
            recommendations.append("Consider reducing directory depth limit")
        }

        // Check for dangerous protocols in allowed list
        for protocolString in allowedProtocols {
            if dangerousProtocols.contains(protocolString), protocolString != "http://" {
                issues.append(.insecureProtocol("Dangerous protocol '\(protocolString)' is allowed"))
                recommendations.append("Remove '\(protocolString)' from allowed protocols")
            }
        }

        // Determine security level
        let securityLevel: SecurityLevel = if issues.isEmpty {
            .high
        } else if issues.count <= 2 {
            .medium
        } else {
            .low
        }

        return SecurityAuditResult(
            securityLevel: securityLevel,
            issues: issues,
            recommendations: recommendations
        )
    }

    /// Security audit result
    struct SecurityAuditResult {
        let securityLevel: SecurityLevel
        let issues: [SecurityIssue]
        let recommendations: [String]

        var isSecure: Bool {
            securityLevel == .high
        }
    }

    /// Security level assessment
    enum SecurityLevel {
        case high
        case medium
        case low

        var description: String {
            switch self {
            case .high: "High - Configuration is secure"
            case .medium: "Medium - Minor security concerns"
            case .low: "Low - Significant security issues"
            }
        }
    }

    /// Security issue types
    enum SecurityIssue {
        case insecureProtocol(String)
        case localFileAccess(String)
        case weakValidation(String)
        case excessiveLimit(String)

        var description: String {
            switch self {
            case let .insecureProtocol(details): "Insecure Protocol: \(details)"
            case let .localFileAccess(details): "Local File Access: \(details)"
            case let .weakValidation(details): "Weak Validation: \(details)"
            case let .excessiveLimit(details): "Excessive Limit: \(details)"
            }
        }
    }
}
