//
// SyntaxHighlighter.swift
// GitCthulhu
//
// Created by GitCthulhu Team on 2025-07-15.
//

import SwiftUI
import GitCore

public struct SyntaxHighlightedText: View {
    let content: String
    let language: String
    let lineType: DiffLineType
    
    public init(content: String, language: String, lineType: DiffLineType = .context) {
        self.content = content
        self.language = language
        self.lineType = lineType
    }
    
    public var body: some View {
        if content.isEmpty {
            Text("")
                .font(.system(.body, design: .monospaced))
        } else {
            highlightedText
        }
    }
    
    private var highlightedText: some View {
        let attributedString = SyntaxHighlighter.highlight(
            content: content,
            language: language,
            lineType: lineType
        )
        
        return Text(AttributedString(attributedString))
            .font(.system(.body, design: .monospaced))
    }
}

public class SyntaxHighlighter {
    
    public static func highlight(
        content: String,
        language: String,
        lineType: DiffLineType = .context
    ) -> NSAttributedString {
        let highlighter = SyntaxHighlighter()
        return highlighter.performHighlighting(content: content, language: language, lineType: lineType)
    }
    
    private func performHighlighting(
        content: String,
        language: String,
        lineType: DiffLineType
    ) -> NSAttributedString {
        let attributedString = NSMutableAttributedString(string: content)
        let range = NSRange(location: 0, length: content.count)
        
        // Set base font
        attributedString.addAttribute(
            .font,
            value: NSFont.monospacedSystemFont(ofSize: NSFont.systemFontSize, weight: .regular),
            range: range
        )
        
        // Set base color based on line type
        let baseColor = baseTextColor(for: lineType)
        attributedString.addAttribute(.foregroundColor, value: baseColor, range: range)
        
        // Apply syntax highlighting based on language
        switch language {
        case "swift":
            highlightSwift(attributedString, content: content)
        case "javascript":
            highlightJavaScript(attributedString, content: content)
        case "typescript":
            highlightTypeScript(attributedString, content: content)
        case "python":
            highlightPython(attributedString, content: content)
        case "java":
            highlightJava(attributedString, content: content)
        case "cpp", "c":
            highlightCpp(attributedString, content: content)
        case "go":
            highlightGo(attributedString, content: content)
        case "rust":
            highlightRust(attributedString, content: content)
        case "json":
            highlightJSON(attributedString, content: content)
        case "yaml":
            highlightYAML(attributedString, content: content)
        case "xml", "html":
            highlightXML(attributedString, content: content)
        case "css":
            highlightCSS(attributedString, content: content)
        case "markdown":
            highlightMarkdown(attributedString, content: content)
        case "bash":
            highlightBash(attributedString, content: content)
        default:
            // No additional highlighting for plaintext
            break
        }
        
        return attributedString
    }
    
    // MARK: - Base Colors
    
    private func baseTextColor(for lineType: DiffLineType) -> NSColor {
        switch lineType {
        case .added:
            return NSColor.systemGreen.blended(withFraction: 0.3, of: NSColor.textColor) ?? NSColor.textColor
        case .removed:
            return NSColor.systemRed.blended(withFraction: 0.3, of: NSColor.textColor) ?? NSColor.textColor
        case .context:
            return NSColor.textColor
        case .noNewlineAtEnd:
            return NSColor.systemOrange
        }
    }
    
    // MARK: - Swift Highlighting
    
    private func highlightSwift(_ attributedString: NSMutableAttributedString, content: String) {
        let keywords = [
            "import", "class", "struct", "enum", "protocol", "extension", "func", "var", "let",
            "if", "else", "switch", "case", "default", "for", "while", "do", "try", "catch",
            "throw", "throws", "rethrows", "return", "break", "continue", "fallthrough",
            "public", "private", "internal", "fileprivate", "open", "static", "final",
            "override", "required", "convenience", "weak", "unowned", "lazy", "inout",
            "associatedtype", "typealias", "init", "deinit", "subscript", "willSet", "didSet",
            "get", "set", "mutating", "nonmutating", "async", "await", "actor", "some", "any"
        ]
        
        highlightKeywords(attributedString, keywords: keywords, color: .systemPurple)
        highlightStrings(attributedString, content: content)
        highlightComments(attributedString, content: content, style: .cStyle)
        highlightNumbers(attributedString, content: content)
        highlightTypes(attributedString, content: content)
    }
    
    // MARK: - JavaScript Highlighting
    
    private func highlightJavaScript(_ attributedString: NSMutableAttributedString, content: String) {
        let keywords = [
            "var", "let", "const", "function", "return", "if", "else", "for", "while", "do",
            "switch", "case", "default", "break", "continue", "try", "catch", "finally",
            "throw", "new", "this", "super", "class", "extends", "import", "export",
            "from", "default", "async", "await", "yield", "typeof", "instanceof"
        ]
        
        highlightKeywords(attributedString, keywords: keywords, color: .systemBlue)
        highlightStrings(attributedString, content: content)
        highlightComments(attributedString, content: content, style: .cStyle)
        highlightNumbers(attributedString, content: content)
    }
    
    // MARK: - TypeScript Highlighting
    
    private func highlightTypeScript(_ attributedString: NSMutableAttributedString, content: String) {
        let keywords = [
            "var", "let", "const", "function", "return", "if", "else", "for", "while", "do",
            "switch", "case", "default", "break", "continue", "try", "catch", "finally",
            "throw", "new", "this", "super", "class", "extends", "import", "export",
            "from", "default", "async", "await", "yield", "typeof", "instanceof",
            "interface", "type", "enum", "namespace", "module", "declare", "public",
            "private", "protected", "readonly", "static", "abstract", "implements"
        ]
        
        highlightKeywords(attributedString, keywords: keywords, color: .systemBlue)
        highlightStrings(attributedString, content: content)
        highlightComments(attributedString, content: content, style: .cStyle)
        highlightNumbers(attributedString, content: content)
        highlightTypes(attributedString, content: content)
    }
    
    // MARK: - Python Highlighting
    
    private func highlightPython(_ attributedString: NSMutableAttributedString, content: String) {
        let keywords = [
            "def", "class", "if", "elif", "else", "for", "while", "try", "except", "finally",
            "with", "as", "import", "from", "return", "yield", "break", "continue", "pass",
            "lambda", "and", "or", "not", "is", "in", "global", "nonlocal", "assert",
            "async", "await", "True", "False", "None"
        ]
        
        highlightKeywords(attributedString, keywords: keywords, color: .systemBlue)
        highlightStrings(attributedString, content: content)
        highlightComments(attributedString, content: content, style: .python)
        highlightNumbers(attributedString, content: content)
    }
    
    // MARK: - Java Highlighting
    
    private func highlightJava(_ attributedString: NSMutableAttributedString, content: String) {
        let keywords = [
            "public", "private", "protected", "static", "final", "abstract", "class", "interface",
            "extends", "implements", "import", "package", "void", "return", "if", "else",
            "for", "while", "do", "switch", "case", "default", "break", "continue",
            "try", "catch", "finally", "throw", "throws", "new", "this", "super",
            "boolean", "byte", "short", "int", "long", "float", "double", "char",
            "true", "false", "null", "enum", "synchronized", "volatile", "transient"
        ]
        
        highlightKeywords(attributedString, keywords: keywords, color: .systemBlue)
        highlightStrings(attributedString, content: content)
        highlightComments(attributedString, content: content, style: .cStyle)
        highlightNumbers(attributedString, content: content)
        highlightTypes(attributedString, content: content)
    }
    
    // MARK: - C/C++ Highlighting
    
    private func highlightCpp(_ attributedString: NSMutableAttributedString, content: String) {
        let keywords = [
            "auto", "break", "case", "char", "const", "continue", "default", "do", "double",
            "else", "enum", "extern", "float", "for", "goto", "if", "int", "long",
            "register", "return", "short", "signed", "sizeof", "static", "struct",
            "switch", "typedef", "union", "unsigned", "void", "volatile", "while",
            "class", "private", "protected", "public", "virtual", "inline", "template",
            "typename", "namespace", "using", "try", "catch", "throw", "new", "delete",
            "this", "friend", "operator", "bool", "true", "false", "nullptr"
        ]
        
        highlightKeywords(attributedString, keywords: keywords, color: .systemBlue)
        highlightStrings(attributedString, content: content)
        highlightComments(attributedString, content: content, style: .cStyle)
        highlightNumbers(attributedString, content: content)
        highlightPreprocessor(attributedString, content: content)
    }
    
    // MARK: - Go Highlighting
    
    private func highlightGo(_ attributedString: NSMutableAttributedString, content: String) {
        let keywords = [
            "break", "case", "chan", "const", "continue", "default", "defer", "else",
            "fallthrough", "for", "func", "go", "goto", "if", "import", "interface",
            "map", "package", "range", "return", "select", "struct", "switch", "type",
            "var", "bool", "byte", "complex64", "complex128", "error", "float32",
            "float64", "int", "int8", "int16", "int32", "int64", "rune", "string",
            "uint", "uint8", "uint16", "uint32", "uint64", "uintptr", "true", "false",
            "iota", "nil", "append", "cap", "close", "complex", "copy", "delete",
            "imag", "len", "make", "new", "panic", "print", "println", "real", "recover"
        ]
        
        highlightKeywords(attributedString, keywords: keywords, color: .systemBlue)
        highlightStrings(attributedString, content: content)
        highlightComments(attributedString, content: content, style: .cStyle)
        highlightNumbers(attributedString, content: content)
    }
    
    // MARK: - Rust Highlighting
    
    private func highlightRust(_ attributedString: NSMutableAttributedString, content: String) {
        let keywords = [
            "as", "break", "const", "continue", "crate", "else", "enum", "extern", "false",
            "fn", "for", "if", "impl", "in", "let", "loop", "match", "mod", "move",
            "mut", "pub", "ref", "return", "self", "Self", "static", "struct", "super",
            "trait", "true", "type", "unsafe", "use", "where", "while", "async", "await",
            "dyn", "abstract", "become", "box", "do", "final", "macro", "override",
            "priv", "typeof", "unsized", "virtual", "yield", "try", "union"
        ]
        
        highlightKeywords(attributedString, keywords: keywords, color: .systemBlue)
        highlightStrings(attributedString, content: content)
        highlightComments(attributedString, content: content, style: .cStyle)
        highlightNumbers(attributedString, content: content)
    }
    
    // MARK: - JSON Highlighting
    
    private func highlightJSON(_ attributedString: NSMutableAttributedString, content: String) {
        highlightJSONKeys(attributedString, content: content)
        highlightJSONStrings(attributedString, content: content)
        highlightJSONValues(attributedString, content: content)
        highlightNumbers(attributedString, content: content)
    }
    
    // MARK: - YAML Highlighting
    
    private func highlightYAML(_ attributedString: NSMutableAttributedString, content: String) {
        highlightYAMLKeys(attributedString, content: content)
        highlightStrings(attributedString, content: content)
        highlightComments(attributedString, content: content, style: .hash)
        highlightNumbers(attributedString, content: content)
    }
    
    // MARK: - XML/HTML Highlighting
    
    private func highlightXML(_ attributedString: NSMutableAttributedString, content: String) {
        highlightXMLTags(attributedString, content: content)
        highlightXMLAttributes(attributedString, content: content)
        highlightStrings(attributedString, content: content)
        highlightComments(attributedString, content: content, style: .xml)
    }
    
    // MARK: - CSS Highlighting
    
    private func highlightCSS(_ attributedString: NSMutableAttributedString, content: String) {
        highlightCSSSelectors(attributedString, content: content)
        highlightCSSProperties(attributedString, content: content)
        highlightStrings(attributedString, content: content)
        highlightComments(attributedString, content: content, style: .cStyle)
        highlightNumbers(attributedString, content: content)
    }
    
    // MARK: - Markdown Highlighting
    
    private func highlightMarkdown(_ attributedString: NSMutableAttributedString, content: String) {
        highlightMarkdownHeaders(attributedString, content: content)
        highlightMarkdownBold(attributedString, content: content)
        highlightMarkdownItalic(attributedString, content: content)
        highlightMarkdownCode(attributedString, content: content)
        highlightMarkdownLinks(attributedString, content: content)
    }
    
    // MARK: - Bash Highlighting
    
    private func highlightBash(_ attributedString: NSMutableAttributedString, content: String) {
        let keywords = [
            "if", "then", "else", "elif", "fi", "case", "esac", "for", "while", "until",
            "do", "done", "function", "return", "exit", "break", "continue", "local",
            "export", "readonly", "declare", "typeset", "let", "eval", "exec", "source",
            "alias", "unalias", "history", "jobs", "bg", "fg", "wait", "kill", "trap",
            "shift", "getopts", "read", "echo", "printf", "test", "true", "false"
        ]
        
        highlightKeywords(attributedString, keywords: keywords, color: .systemBlue)
        highlightStrings(attributedString, content: content)
        highlightComments(attributedString, content: content, style: .hash)
        highlightBashVariables(attributedString, content: content)
    }
    
    // MARK: - Generic Highlighting Helpers
    
    private func highlightKeywords(_ attributedString: NSMutableAttributedString, keywords: [String], color: NSColor) {
        let content = attributedString.string
        
        for keyword in keywords {
            let pattern = "\\b\(NSRegularExpression.escapedPattern(for: keyword))\\b"
            highlightPattern(attributedString, pattern: pattern, color: color)
        }
    }
    
    private func highlightStrings(_ attributedString: NSMutableAttributedString, content: String) {
        // Double quotes
        highlightPattern(attributedString, pattern: "\"([^\"]*)\"", color: .systemRed)
        // Single quotes
        highlightPattern(attributedString, pattern: "'([^']*)'", color: .systemRed)
    }
    
    private func highlightNumbers(_ attributedString: NSMutableAttributedString, content: String) {
        // Integer and floating point numbers
        highlightPattern(attributedString, pattern: "\\b\\d+(\\.\\d+)?\\b", color: .systemOrange)
        // Hexadecimal numbers
        highlightPattern(attributedString, pattern: "\\b0[xX][0-9a-fA-F]+\\b", color: .systemOrange)
    }
    
    private func highlightComments(_ attributedString: NSMutableAttributedString, content: String, style: CommentStyle) {
        switch style {
        case .cStyle:
            // Single line comments
            highlightPattern(attributedString, pattern: "//.*$", color: .systemGreen, options: [.anchorsMatchLines])
            // Multi-line comments
            highlightPattern(attributedString, pattern: "/\\*[\\s\\S]*?\\*/", color: .systemGreen)
        case .python:
            highlightPattern(attributedString, pattern: "#.*$", color: .systemGreen, options: [.anchorsMatchLines])
        case .hash:
            highlightPattern(attributedString, pattern: "#.*$", color: .systemGreen, options: [.anchorsMatchLines])
        case .xml:
            highlightPattern(attributedString, pattern: "<!--[\\s\\S]*?-->", color: .systemGreen)
        }
    }
    
    private func highlightTypes(_ attributedString: NSMutableAttributedString, content: String) {
        // Capital-cased words (likely types)
        highlightPattern(attributedString, pattern: "\\b[A-Z][a-zA-Z0-9_]*\\b", color: .systemTeal)
    }
    
    private func highlightPreprocessor(_ attributedString: NSMutableAttributedString, content: String) {
        highlightPattern(attributedString, pattern: "^\\s*#.*$", color: .systemYellow, options: [.anchorsMatchLines])
    }
    
    // MARK: - Specialized Highlighting
    
    private func highlightJSONKeys(_ attributedString: NSMutableAttributedString, content: String) {
        highlightPattern(attributedString, pattern: "\"([^\"]+)\"\\s*:", color: .systemBlue)
    }
    
    private func highlightJSONStrings(_ attributedString: NSMutableAttributedString, content: String) {
        highlightPattern(attributedString, pattern: ":\\s*\"([^\"]+)\"", color: .systemRed)
    }
    
    private func highlightJSONValues(_ attributedString: NSMutableAttributedString, content: String) {
        highlightPattern(attributedString, pattern: "\\b(true|false|null)\\b", color: .systemPurple)
    }
    
    private func highlightYAMLKeys(_ attributedString: NSMutableAttributedString, content: String) {
        highlightPattern(attributedString, pattern: "^\\s*[a-zA-Z_][a-zA-Z0-9_]*\\s*:", color: .systemBlue, options: [.anchorsMatchLines])
    }
    
    private func highlightXMLTags(_ attributedString: NSMutableAttributedString, content: String) {
        highlightPattern(attributedString, pattern: "<[^>]+>", color: .systemBlue)
    }
    
    private func highlightXMLAttributes(_ attributedString: NSMutableAttributedString, content: String) {
        highlightPattern(attributedString, pattern: "\\s[a-zA-Z_][a-zA-Z0-9_]*=", color: .systemTeal)
    }
    
    private func highlightCSSSelectors(_ attributedString: NSMutableAttributedString, content: String) {
        highlightPattern(attributedString, pattern: "^\\s*[.#]?[a-zA-Z_][a-zA-Z0-9_-]*\\s*\\{", color: .systemBlue, options: [.anchorsMatchLines])
    }
    
    private func highlightCSSProperties(_ attributedString: NSMutableAttributedString, content: String) {
        highlightPattern(attributedString, pattern: "\\s*[a-zA-Z-]+\\s*:", color: .systemTeal)
    }
    
    private func highlightMarkdownHeaders(_ attributedString: NSMutableAttributedString, content: String) {
        highlightPattern(attributedString, pattern: "^#+\\s+.*$", color: .systemBlue, options: [.anchorsMatchLines])
    }
    
    private func highlightMarkdownBold(_ attributedString: NSMutableAttributedString, content: String) {
        highlightPattern(attributedString, pattern: "\\*\\*([^*]+)\\*\\*", color: .systemOrange)
    }
    
    private func highlightMarkdownItalic(_ attributedString: NSMutableAttributedString, content: String) {
        highlightPattern(attributedString, pattern: "\\*([^*]+)\\*", color: .systemOrange)
    }
    
    private func highlightMarkdownCode(_ attributedString: NSMutableAttributedString, content: String) {
        highlightPattern(attributedString, pattern: "`([^`]+)`", color: .systemRed)
    }
    
    private func highlightMarkdownLinks(_ attributedString: NSMutableAttributedString, content: String) {
        highlightPattern(attributedString, pattern: "\\[([^\\]]+)\\]\\([^\\)]+\\)", color: .systemBlue)
    }
    
    private func highlightBashVariables(_ attributedString: NSMutableAttributedString, content: String) {
        highlightPattern(attributedString, pattern: "\\$[a-zA-Z_][a-zA-Z0-9_]*", color: .systemTeal)
        highlightPattern(attributedString, pattern: "\\$\\{[^}]+\\}", color: .systemTeal)
    }
    
    // MARK: - Pattern Highlighting
    
    private func highlightPattern(
        _ attributedString: NSMutableAttributedString,
        pattern: String,
        color: NSColor,
        options: NSRegularExpression.Options = []
    ) {
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: options)
            let range = NSRange(location: 0, length: attributedString.length)
            
            regex.enumerateMatches(in: attributedString.string, options: [], range: range) { match, _, _ in
                guard let match = match else { return }
                attributedString.addAttribute(.foregroundColor, value: color, range: match.range)
            }
        } catch {
            // Pattern compilation failed, skip highlighting
        }
    }
    
    // MARK: - Supporting Types
    
    private enum CommentStyle {
        case cStyle
        case python
        case hash
        case xml
    }
}

#Preview {
    VStack {
        SyntaxHighlightedText(
            content: "func example() -> String {",
            language: "swift",
            lineType: .added
        )
        
        SyntaxHighlightedText(
            content: "    return \"Hello, World!\"",
            language: "swift",
            lineType: .context
        )
        
        SyntaxHighlightedText(
            content: "}",
            language: "swift",
            lineType: .removed
        )
    }
    .frame(width: 400, height: 200)
}