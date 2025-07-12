//
// GitInputValidator.swift
// GitCthulhu
//
// Created by GitCthulhu Team on 2025-07-12.
//

import Foundation

/// Validates Git command inputs to prevent injection attacks and ensure data integrity
enum GitInputValidator {
    // MARK: - Argument Validation

    static func validateArguments(_ arguments: [String]) throws {
        for argument in arguments {
            try validateSingleArgument(argument)
        }
    }

    private static func validateSingleArgument(_ argument: String) throws {
        // Prevent null bytes and other control characters
        if argument.contains("\0") || argument.contains("\r") || argument.contains("\n") {
            throw GitError.invalidRepositoryPath
        }

        // Prevent command injection by checking for dangerous characters, but allow some git-specific characters
        let dangerousChars = CharacterSet(charactersIn: ";|&$`<>")
        if argument.rangeOfCharacter(from: dangerousChars) != nil {
            throw GitError.invalidRepositoryPath
        }

        // Validate that the argument doesn't start with suspicious patterns
        let suspiciousPatterns = ["--exec", "--upload-pack", "--receive-pack"]
        for pattern in suspiciousPatterns where argument.hasPrefix(pattern) {
            throw GitError.permissionDenied
        }
    }

    // MARK: - Branch Name Validation

    static func sanitizeBranchName(_ branchName: String) throws -> String {
        // Git branch name validation rules
        let invalidChars = CharacterSet(charactersIn: " ~^:?*[\\")
        if branchName.rangeOfCharacter(from: invalidChars) != nil {
            throw GitError.invalidBranch("Branch name contains invalid characters: \(branchName)")
        }

        if branchName.isEmpty || branchName.hasPrefix(".") || branchName.hasSuffix(".") ||
            branchName.hasPrefix("-") || branchName.contains("..") || branchName.contains("@{") {
            throw GitError.invalidBranch("Invalid branch name format: \(branchName)")
        }

        return branchName
    }

    // MARK: - File Path Validation

    static func sanitizeFilePath(_ filePath: String) throws -> String {
        // Prevent directory traversal
        if filePath.contains("../") || filePath.contains("..\\") || filePath.hasPrefix("/") {
            throw GitError.fileNotFound("Invalid file path: \(filePath)")
        }

        // Ensure path is within repository bounds
        let normalizedPath = (filePath as NSString).standardizingPath
        if normalizedPath != filePath {
            throw GitError.fileNotFound("Path normalization changed path, potential security issue")
        }

        return filePath
    }

    // MARK: - Commit Message Validation

    static func sanitizeCommitMessage(_ message: String) throws -> String {
        // Prevent null bytes and excessive length
        if message.contains("\0") {
            throw GitError.commitFailed("Commit message contains null bytes")
        }

        // Trim whitespace and ensure reasonable length
        let trimmed = message.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            throw GitError.commitFailed("Commit message cannot be empty")
        }

        if trimmed.count > 5000 {
            throw GitError.commitFailed("Commit message too long (max 5000 characters)")
        }

        return trimmed
    }

    // MARK: - Author Validation

    static func sanitizeAuthor(_ author: String) throws -> String {
        // Validate author format: "Name <email@domain.com>"
        let trimmed = author.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmed.isEmpty {
            throw GitError.commitFailed("Author cannot be empty")
        }

        // Check for null bytes and control characters
        if trimmed.contains("\0") || trimmed.contains("\r") || trimmed.contains("\n") {
            throw GitError.commitFailed("Author contains invalid characters")
        }

        // Basic email format validation if angle brackets are present
        if trimmed.contains("<"), trimmed.contains(">") {
            let emailPattern = #"^[^<>]*<[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}>$"#
            let regex = try NSRegularExpression(pattern: emailPattern)
            let range = NSRange(location: 0, length: trimmed.utf16.count)

            if regex.firstMatch(in: trimmed, options: [], range: range) == nil {
                throw GitError.commitFailed("Invalid author format. Expected: Name <email@domain.com>")
            }
        }

        if trimmed.count > 255 {
            throw GitError.commitFailed("Author too long (max 255 characters)")
        }

        return trimmed
    }

    // MARK: - Remote URL Validation

    static func validateRemoteURL(_ url: String) throws -> String {
        let trimmed = url.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmed.isEmpty {
            throw GitError.invalidRepositoryPath
        }

        // Check for null bytes and control characters
        if trimmed.contains("\0") || trimmed.contains("\r") || trimmed.contains("\n") {
            throw GitError.invalidRepositoryPath
        }

        // Allowed protocols
        let allowedProtocols = ["https://", "git://", "ssh://", "git@"]
        let hasValidProtocol = allowedProtocols.contains { trimmed.hasPrefix($0) }

        if !hasValidProtocol {
            throw GitError.invalidRepositoryPath
        }

        // Prevent local file access and dangerous protocols
        let dangerousProtocols = ["file://", "ftp://", "javascript:", "data:"]
        for dangerous in dangerousProtocols where trimmed.lowercased().hasPrefix(dangerous) {
            throw GitError.permissionDenied
        }

        return trimmed
    }

    // MARK: - Git Path Detection and Validation

    static func detectGitPath() throws -> String {
        // Try common Git installation paths
        let commonPaths = [
            "/usr/bin/git",
            "/usr/local/bin/git",
            "/opt/homebrew/bin/git",
            "/opt/local/bin/git"
        ]

        for path in commonPaths where FileManager.default.isExecutableFile(atPath: path) {
            return path
        }

        // Fallback to system PATH
        return "git"
    }

    static func validateGitPath(_ path: String) throws -> String {
        let trimmed = path.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmed.isEmpty {
            throw GitError.invalidRepositoryPath
        }

        // Prevent path traversal and dangerous paths
        if trimmed.contains("../") || trimmed.contains("..\\") ||
            trimmed.contains(";") || trimmed.contains("|") || trimmed.contains("&") {
            throw GitError.permissionDenied
        }

        // Must be an absolute path or just "git"
        if trimmed != "git", !trimmed.hasPrefix("/") {
            throw GitError.invalidRepositoryPath
        }

        return trimmed
    }

    // MARK: - Repository Path Validation

    static func validateRepositoryPath(_ path: String) throws -> String {
        let trimmed = path.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmed.isEmpty {
            throw GitError.invalidRepositoryPath
        }

        // Check for null bytes and control characters
        if trimmed.contains("\0") || trimmed.contains("\r") || trimmed.contains("\n") {
            throw GitError.invalidRepositoryPath
        }

        // Resolve and normalize the path
        let url = URL(fileURLWithPath: trimmed)
        let normalizedPath = url.standardizedFileURL.path

        // Ensure the path exists and is a directory
        var isDirectory: ObjCBool = false
        if !FileManager.default.fileExists(atPath: normalizedPath, isDirectory: &isDirectory) {
            throw GitError.invalidRepositoryPath
        }

        if !isDirectory.boolValue {
            throw GitError.invalidRepositoryPath
        }

        return normalizedPath
    }

    // MARK: - General Input Sanitization

    static func sanitizeInput(_ input: String, maxLength: Int = 1000) throws -> String {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)

        // Check for null bytes and control characters
        if trimmed.contains("\0") || trimmed.contains("\r") || trimmed.contains("\n") {
            throw GitError.invalidRepositoryPath
        }

        if trimmed.count > maxLength {
            throw GitError.invalidRepositoryPath
        }

        return trimmed
    }
}
