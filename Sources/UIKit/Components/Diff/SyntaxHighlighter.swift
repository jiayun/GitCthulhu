//
// SyntaxHighlighter.swift
// GitCthulhu
//
// Created by GitCthulhu Team on 2025-07-17.
//

import Foundation
import SwiftUI

/// Syntax highlighter for code in diffs
public class SyntaxHighlighter {
    public init() {}

    /// Highlight syntax for a given piece of code
    public func highlight(_ code: String, language: String) -> AttributedString {
        let highlightedCode = applyHighlighting(code, language: language)
        return highlightedCode
    }

    private static let languageMap: [String: String] = [
        "swift": "swift",
        "js": "javascript", "jsx": "javascript",
        "ts": "typescript", "tsx": "typescript",
        "py": "python",
        "java": "java",
        "kt": "kotlin", "kts": "kotlin",
        "cpp": "cpp", "cc": "cpp", "cxx": "cpp", "c++": "cpp",
        "c": "c",
        "h": "header", "hpp": "header", "hxx": "header",
        "rs": "rust",
        "go": "go",
        "rb": "ruby",
        "php": "php",
        "cs": "csharp",
        "html": "html", "htm": "html",
        "css": "css",
        "scss": "scss", "sass": "scss",
        "xml": "xml",
        "json": "json",
        "yaml": "yaml", "yml": "yaml",
        "toml": "toml",
        "md": "markdown", "markdown": "markdown",
        "sh": "shell", "bash": "shell",
        "sql": "sql",
        "dockerfile": "dockerfile",
        "makefile": "makefile"
    ]

    /// Detect programming language from file extension
    public func detectLanguage(from filePath: String) -> String {
        let fileExtension = URL(fileURLWithPath: filePath).pathExtension.lowercased()
        return Self.languageMap[fileExtension] ?? "text"
    }

    // MARK: - Private Methods

    private func applyHighlighting(_ code: String, language: String) -> AttributedString {
        var attributedString = AttributedString(code)

        // Apply base styling
        attributedString.font = .custom("SF Mono", size: 12)
        attributedString.foregroundColor = .primary

        // Apply language-specific highlighting
        switch language {
        case "swift":
            return highlightSwift(attributedString)
        case "javascript", "typescript":
            return highlightJavaScript(attributedString)
        case "python":
            return highlightPython(attributedString)
        case "java", "kotlin":
            return highlightJava(attributedString)
        case "json":
            return highlightJSON(attributedString)
        case "xml", "html":
            return highlightXML(attributedString)
        case "css", "scss":
            return highlightCSS(attributedString)
        case "shell":
            return highlightShell(attributedString)
        default:
            return highlightGeneric(attributedString)
        }
    }

    // MARK: - Language-Specific Highlighting

    private func highlightSwift(_ attributedString: AttributedString) -> AttributedString {
        var result = attributedString
        let content = String(attributedString.characters)

        // Swift keywords
        let swiftKeywords = [
            "class", "struct", "enum", "protocol", "extension", "func", "var", "let",
            "if", "else", "guard", "switch", "case", "default", "for", "while",
            "return", "break", "continue", "import", "public", "private", "internal",
            "fileprivate", "open", "static", "final", "override", "init", "deinit",
            "throws", "try", "catch", "async", "await", "actor", "isolated"
        ]

        // Highlight keywords
        for keyword in swiftKeywords {
            result = highlightPattern(result, pattern: "\\b\(keyword)\\b", color: .purple)
        }

        // Highlight strings
        result = highlightPattern(result, pattern: "\"[^\"]*\"", color: .red)

        // Highlight comments
        result = highlightPattern(result, pattern: "//.*$", color: .green, isMultiline: true)
        result = highlightPattern(result, pattern: "/\\*[\\s\\S]*?\\*/", color: .green)

        // Highlight numbers
        result = highlightPattern(result, pattern: "\\b\\d+(\\.\\d+)?\\b", color: .blue)

        // Highlight function calls
        result = highlightPattern(result, pattern: "\\w+(?=\\()", color: .cyan)

        return result
    }

    private func highlightJavaScript(_ attributedString: AttributedString) -> AttributedString {
        var result = attributedString

        let jsKeywords = [
            "function", "var", "let", "const", "if", "else", "for", "while",
            "return", "break", "continue", "switch", "case", "default",
            "try", "catch", "finally", "throw", "new", "this", "typeof",
            "instanceof", "in", "of", "class", "extends", "import", "export",
            "async", "await", "yield", "true", "false", "null", "undefined"
        ]

        for keyword in jsKeywords {
            result = highlightPattern(result, pattern: "\\b\(keyword)\\b", color: .purple)
        }

        result = highlightPattern(result, pattern: "\"[^\"]*\"|'[^']*'|`[^`]*`", color: .red)
        result = highlightPattern(result, pattern: "//.*$", color: .green, isMultiline: true)
        result = highlightPattern(result, pattern: "/\\*[\\s\\S]*?\\*/", color: .green)
        result = highlightPattern(result, pattern: "\\b\\d+(\\.\\d+)?\\b", color: .blue)

        return result
    }

    private func highlightPython(_ attributedString: AttributedString) -> AttributedString {
        var result = attributedString

        let pythonKeywords = [
            "def", "class", "if", "elif", "else", "for", "while", "try", "except",
            "finally", "with", "as", "import", "from", "return", "yield", "break",
            "continue", "pass", "raise", "assert", "global", "nonlocal", "lambda",
            "True", "False", "None", "and", "or", "not", "in", "is"
        ]

        for keyword in pythonKeywords {
            result = highlightPattern(result, pattern: "\\b\(keyword)\\b", color: .purple)
        }

        result = highlightPattern(
            result,
            pattern: "\"[^\"]*\"|'[^']*'|\"\"\"[\\s\\S]*?\"\"\"|'''[\\s\\S]*?'''",
            color: .red
        )
        result = highlightPattern(result, pattern: "#.*$", color: .green, isMultiline: true)
        result = highlightPattern(result, pattern: "\\b\\d+(\\.\\d+)?\\b", color: .blue)

        return result
    }

    private func highlightJava(_ attributedString: AttributedString) -> AttributedString {
        var result = attributedString

        let javaKeywords = [
            "public", "private", "protected", "static", "final", "abstract", "synchronized",
            "class", "interface", "enum", "extends", "implements", "package", "import",
            "if", "else", "for", "while", "do", "switch", "case", "default",
            "try", "catch", "finally", "throw", "throws", "return", "break", "continue",
            "new", "this", "super", "instanceof", "true", "false", "null"
        ]

        for keyword in javaKeywords {
            result = highlightPattern(result, pattern: "\\b\(keyword)\\b", color: .purple)
        }

        result = highlightPattern(result, pattern: "\"[^\"]*\"", color: .red)
        result = highlightPattern(result, pattern: "//.*$", color: .green, isMultiline: true)
        result = highlightPattern(result, pattern: "/\\*[\\s\\S]*?\\*/", color: .green)
        result = highlightPattern(result, pattern: "\\b\\d+(\\.\\d+)?[fFdDlL]?\\b", color: .blue)

        return result
    }

    private func highlightJSON(_ attributedString: AttributedString) -> AttributedString {
        var result = attributedString

        // Highlight strings (keys and values)
        result = highlightPattern(result, pattern: "\"[^\"]*\"", color: .red)

        // Highlight numbers
        result = highlightPattern(result, pattern: "\\b\\d+(\\.\\d+)?([eE][+-]?\\d+)?\\b", color: .blue)

        // Highlight boolean and null
        result = highlightPattern(result, pattern: "\\b(true|false|null)\\b", color: .purple)

        return result
    }

    private func highlightXML(_ attributedString: AttributedString) -> AttributedString {
        var result = attributedString

        // Highlight tags
        result = highlightPattern(result, pattern: "<[^>]*>", color: .blue)

        // Highlight attribute values
        result = highlightPattern(result, pattern: "=\"[^\"]*\"", color: .red)

        // Highlight comments
        result = highlightPattern(result, pattern: "<!--[\\s\\S]*?-->", color: .green)

        return result
    }

    private func highlightCSS(_ attributedString: AttributedString) -> AttributedString {
        var result = attributedString

        // Highlight selectors
        result = highlightPattern(result, pattern: "[.#]?[a-zA-Z][a-zA-Z0-9-_]*(?=\\s*{)", color: .blue)

        // Highlight properties
        result = highlightPattern(result, pattern: "[a-zA-Z-]+(?=\\s*:)", color: .purple)

        // Highlight values
        result = highlightPattern(result, pattern: ":[^;{}]*", color: .red)

        // Highlight comments
        result = highlightPattern(result, pattern: "/\\*[\\s\\S]*?\\*/", color: .green)

        return result
    }

    private func highlightShell(_ attributedString: AttributedString) -> AttributedString {
        var result = attributedString

        let shellKeywords = [
            "if", "then", "else", "elif", "fi", "for", "while", "do", "done",
            "case", "esac", "function", "return", "exit", "export", "local",
            "readonly", "declare", "typeset", "echo", "printf", "read"
        ]

        for keyword in shellKeywords {
            result = highlightPattern(result, pattern: "\\b\(keyword)\\b", color: .purple)
        }

        // Highlight strings
        result = highlightPattern(result, pattern: "\"[^\"]*\"|'[^']*'", color: .red)

        // Highlight comments
        result = highlightPattern(result, pattern: "#.*$", color: .green, isMultiline: true)

        // Highlight variables
        result = highlightPattern(result, pattern: "\\$\\w+|\\$\\{[^}]*\\}", color: .orange)

        return result
    }

    private func highlightGeneric(_ attributedString: AttributedString) -> AttributedString {
        var result = attributedString

        // Basic highlighting for unknown languages
        // Highlight quoted strings
        result = highlightPattern(result, pattern: "\"[^\"]*\"|'[^']*'", color: .red)

        // Highlight numbers
        result = highlightPattern(result, pattern: "\\b\\d+(\\.\\d+)?\\b", color: .blue)

        // Highlight common comment patterns
        result = highlightPattern(result, pattern: "//.*$|#.*$", color: .green, isMultiline: true)
        result = highlightPattern(result, pattern: "/\\*[\\s\\S]*?\\*/", color: .green)

        return result
    }

    // MARK: - Helper Methods

    private func highlightPattern(
        _ attributedString: AttributedString,
        pattern: String,
        color: Color,
        isMultiline: Bool = false
    ) -> AttributedString {
        var result = attributedString
        let content = String(attributedString.characters)

        do {
            var options: NSRegularExpression.Options = [.caseInsensitive]
            if isMultiline {
                options.insert(.anchorsMatchLines)
            }

            let regex = try NSRegularExpression(pattern: pattern, options: options)
            let range = NSRange(content.startIndex..., in: content)
            let matches = regex.matches(in: content, options: [], range: range)

            for match in matches.reversed() {
                if let swiftRange = Range(match.range, in: content) {
                    let attributedRange = AttributedString
                        .Index(swiftRange.lowerBound, within: result)! ..< AttributedString.Index(
                            swiftRange.upperBound,
                            within: result
                        )!
                    result[attributedRange].foregroundColor = color
                }
            }
        } catch {
            // If regex fails, return original string
            return result
        }

        return result
    }
}

// MARK: - Extensions for Colors

extension Color {
    static let cyan = Color(red: 0.0, green: 0.8, blue: 0.8)
    static let orange = Color(red: 1.0, green: 0.6, blue: 0.0)
}
