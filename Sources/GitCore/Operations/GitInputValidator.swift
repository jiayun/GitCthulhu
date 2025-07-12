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
}
