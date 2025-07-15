//
// SyntaxHighlighterTests.swift
// GitCthulhu
//
// Created by GitCthulhu Team on 2025-07-15.
//

import Testing
import Foundation
import AppKit
@testable import UIKit
@testable import GitCore

struct SyntaxHighlighterTests {
    
    // MARK: - Basic Highlighting Tests
    
    @Test("Highlight Swift keywords")
    func testHighlightSwiftKeywords() {
        let content = "import Foundation\nclass TestClass {\n    func testMethod() {\n        let value = 42\n        return value\n    }\n}"
        
        let result = SyntaxHighlighter.highlight(content: content, language: "swift")
        
        #expect(result.length == content.count)
        
        // Check that keywords are highlighted
        let attributedContent = result.string
        #expect(attributedContent.contains("import"))
        #expect(attributedContent.contains("class"))
        #expect(attributedContent.contains("func"))
        #expect(attributedContent.contains("let"))
        #expect(attributedContent.contains("return"))
    }
    
    @Test("Highlight Swift strings")
    func testHighlightSwiftStrings() {
        let content = "let message = \"Hello, World!\"\nlet path = '/usr/bin/swift'"
        
        let result = SyntaxHighlighter.highlight(content: content, language: "swift")
        
        #expect(result.length == content.count)
        
        // Check for string highlighting by examining attributes
        var foundStringHighlighting = false
        result.enumerateAttribute(.foregroundColor, in: NSRange(location: 0, length: result.length)) { value, range, _ in
            if let color = value as? NSColor, color == NSColor.systemRed {
                let substring = (content as NSString).substring(with: range)
                if substring.contains("\"Hello, World!\"") || substring.contains("'/usr/bin/swift'") {
                    foundStringHighlighting = true
                }
            }
        }
        
        #expect(foundStringHighlighting)
    }
    
    @Test("Highlight Swift numbers")
    func testHighlightSwiftNumbers() {
        let content = "let integer = 42\nlet float = 3.14\nlet hex = 0xFF"
        
        let result = SyntaxHighlighter.highlight(content: content, language: "swift")
        
        #expect(result.length == content.count)
        
        // Check for number highlighting
        var foundNumberHighlighting = false
        result.enumerateAttribute(.foregroundColor, in: NSRange(location: 0, length: result.length)) { value, range, _ in
            if let color = value as? NSColor, color == NSColor.systemOrange {
                let substring = (content as NSString).substring(with: range)
                if substring.contains("42") || substring.contains("3.14") || substring.contains("0xFF") {
                    foundNumberHighlighting = true
                }
            }
        }
        
        #expect(foundNumberHighlighting)
    }
    
    @Test("Highlight Swift comments")
    func testHighlightSwiftComments() {
        let content = "// Single line comment\n/* Multi-line\n   comment */\nlet value = 42"
        
        let result = SyntaxHighlighter.highlight(content: content, language: "swift")
        
        #expect(result.length == content.count)
        
        // Check for comment highlighting
        var foundCommentHighlighting = false
        result.enumerateAttribute(.foregroundColor, in: NSRange(location: 0, length: result.length)) { value, range, _ in
            if let color = value as? NSColor, color == NSColor.systemGreen {
                let substring = (content as NSString).substring(with: range)
                if substring.contains("Single line comment") || substring.contains("Multi-line") {
                    foundCommentHighlighting = true
                }
            }
        }
        
        #expect(foundCommentHighlighting)
    }
    
    // MARK: - JavaScript Highlighting Tests
    
    @Test("Highlight JavaScript keywords")
    func testHighlightJavaScriptKeywords() {
        let content = "function test() {\n    const value = 42;\n    return value;\n}"
        
        let result = SyntaxHighlighter.highlight(content: content, language: "javascript")
        
        #expect(result.length == content.count)
        
        let attributedContent = result.string
        #expect(attributedContent.contains("function"))
        #expect(attributedContent.contains("const"))
        #expect(attributedContent.contains("return"))
    }
    
    @Test("Highlight JavaScript strings and numbers")
    func testHighlightJavaScriptStringsAndNumbers() {
        let content = "const message = 'Hello, World!';\nconst number = 123.45;"
        
        let result = SyntaxHighlighter.highlight(content: content, language: "javascript")
        
        #expect(result.length == content.count)
        
        // Check for string and number highlighting
        var foundStringHighlighting = false
        var foundNumberHighlighting = false
        
        result.enumerateAttribute(.foregroundColor, in: NSRange(location: 0, length: result.length)) { value, range, _ in
            if let color = value as? NSColor {
                let substring = (content as NSString).substring(with: range)
                if color == NSColor.systemRed && substring.contains("'Hello, World!'") {
                    foundStringHighlighting = true
                }
                if color == NSColor.systemOrange && substring.contains("123.45") {
                    foundNumberHighlighting = true
                }
            }
        }
        
        #expect(foundStringHighlighting)
        #expect(foundNumberHighlighting)
    }
    
    // MARK: - Python Highlighting Tests
    
    @Test("Highlight Python keywords")
    func testHighlightPythonKeywords() {
        let content = "def test_function():\n    if True:\n        return None"
        
        let result = SyntaxHighlighter.highlight(content: content, language: "python")
        
        #expect(result.length == content.count)
        
        let attributedContent = result.string
        #expect(attributedContent.contains("def"))
        #expect(attributedContent.contains("if"))
        #expect(attributedContent.contains("return"))
        #expect(attributedContent.contains("True"))
        #expect(attributedContent.contains("None"))
    }
    
    @Test("Highlight Python comments")
    func testHighlightPythonComments() {
        let content = "# This is a comment\ndef function():\n    pass  # Another comment"
        
        let result = SyntaxHighlighter.highlight(content: content, language: "python")
        
        #expect(result.length == content.count)
        
        // Check for comment highlighting
        var foundCommentHighlighting = false
        result.enumerateAttribute(.foregroundColor, in: NSRange(location: 0, length: result.length)) { value, range, _ in
            if let color = value as? NSColor, color == NSColor.systemGreen {
                let substring = (content as NSString).substring(with: range)
                if substring.contains("This is a comment") || substring.contains("Another comment") {
                    foundCommentHighlighting = true
                }
            }
        }
        
        #expect(foundCommentHighlighting)
    }
    
    // MARK: - JSON Highlighting Tests
    
    @Test("Highlight JSON structure")
    func testHighlightJSONStructure() {
        let content = "{\n  \"name\": \"John\",\n  \"age\": 30,\n  \"isActive\": true,\n  \"value\": null\n}"
        
        let result = SyntaxHighlighter.highlight(content: content, language: "json")
        
        #expect(result.length == content.count)
        
        // Check for JSON key highlighting (should be blue)
        var foundKeyHighlighting = false
        var foundValueHighlighting = false
        var foundBooleanHighlighting = false
        
        result.enumerateAttribute(.foregroundColor, in: NSRange(location: 0, length: result.length)) { value, range, _ in
            if let color = value as? NSColor {
                let substring = (content as NSString).substring(with: range)
                if color == NSColor.systemBlue && (substring.contains("\"name\"") || substring.contains("\"age\"")) {
                    foundKeyHighlighting = true
                }
                if color == NSColor.systemRed && substring.contains("\"John\"") {
                    foundValueHighlighting = true
                }
                if color == NSColor.systemPurple && (substring.contains("true") || substring.contains("null")) {
                    foundBooleanHighlighting = true
                }
            }
        }
        
        #expect(foundKeyHighlighting)
        #expect(foundValueHighlighting)
        #expect(foundBooleanHighlighting)
    }
    
    // MARK: - XML/HTML Highlighting Tests
    
    @Test("Highlight XML tags")
    func testHighlightXMLTags() {
        let content = "<root>\n  <item id=\"1\">value</item>\n  <!-- comment -->\n</root>"
        
        let result = SyntaxHighlighter.highlight(content: content, language: "xml")
        
        #expect(result.length == content.count)
        
        // Check for tag highlighting
        var foundTagHighlighting = false
        var foundCommentHighlighting = false
        
        result.enumerateAttribute(.foregroundColor, in: NSRange(location: 0, length: result.length)) { value, range, _ in
            if let color = value as? NSColor {
                let substring = (content as NSString).substring(with: range)
                if color == NSColor.systemBlue && (substring.contains("<root>") || substring.contains("<item")) {
                    foundTagHighlighting = true
                }
                if color == NSColor.systemGreen && substring.contains("comment") {
                    foundCommentHighlighting = true
                }
            }
        }
        
        #expect(foundTagHighlighting)
        #expect(foundCommentHighlighting)
    }
    
    // MARK: - Line Type Color Tests
    
    @Test("Apply different colors for different line types")
    func testApplyColorsForDifferentLineTypes() {
        let content = "let value = 42"
        
        let contextResult = SyntaxHighlighter.highlight(content: content, language: "swift", lineType: .context)
        let addedResult = SyntaxHighlighter.highlight(content: content, language: "swift", lineType: .added)
        let removedResult = SyntaxHighlighter.highlight(content: content, language: "swift", lineType: .removed)
        
        #expect(contextResult.length == content.count)
        #expect(addedResult.length == content.count)
        #expect(removedResult.length == content.count)
        
        // Check that different line types have different base colors
        var contextBaseColor: NSColor?
        var addedBaseColor: NSColor?
        var removedBaseColor: NSColor?
        
        contextResult.enumerateAttribute(.foregroundColor, in: NSRange(location: 0, length: 1)) { value, _, _ in
            contextBaseColor = value as? NSColor
        }
        
        addedResult.enumerateAttribute(.foregroundColor, in: NSRange(location: 0, length: 1)) { value, _, _ in
            addedBaseColor = value as? NSColor
        }
        
        removedResult.enumerateAttribute(.foregroundColor, in: NSRange(location: 0, length: 1)) { value, _, _ in
            removedBaseColor = value as? NSColor
        }
        
        #expect(contextBaseColor == NSColor.textColor)
        #expect(addedBaseColor != contextBaseColor)
        #expect(removedBaseColor != contextBaseColor)
        #expect(addedBaseColor != removedBaseColor)
    }
    
    // MARK: - Language Detection Tests
    
    @Test("Handle unknown language gracefully")
    func testHandleUnknownLanguageGracefully() {
        let content = "some random content"
        
        let result = SyntaxHighlighter.highlight(content: content, language: "unknown")
        
        #expect(result.length == content.count)
        #expect(result.string == content)
        
        // Should have basic formatting but no syntax highlighting
        var hasMonospaceFont = false
        result.enumerateAttribute(.font, in: NSRange(location: 0, length: result.length)) { value, _, _ in
            if let font = value as? NSFont {
                hasMonospaceFont = font.isFixedPitch
            }
        }
        
        #expect(hasMonospaceFont)
    }
    
    @Test("Handle empty content")
    func testHandleEmptyContent() {
        let content = ""
        
        let result = SyntaxHighlighter.highlight(content: content, language: "swift")
        
        #expect(result.length == 0)
        #expect(result.string == "")
    }
    
    // MARK: - Markdown Highlighting Tests
    
    @Test("Highlight Markdown syntax")
    func testHighlightMarkdownSyntax() {
        let content = "# Header\n**bold text**\n*italic text*\n`code`\n[link](url)"
        
        let result = SyntaxHighlighter.highlight(content: content, language: "markdown")
        
        #expect(result.length == content.count)
        
        // Check for markdown highlighting
        var foundHeaderHighlighting = false
        var foundBoldHighlighting = false
        var foundLinkHighlighting = false
        
        result.enumerateAttribute(.foregroundColor, in: NSRange(location: 0, length: result.length)) { value, range, _ in
            if let color = value as? NSColor {
                let substring = (content as NSString).substring(with: range)
                if color == NSColor.systemBlue && substring.contains("# Header") {
                    foundHeaderHighlighting = true
                }
                if color == NSColor.systemOrange && substring.contains("**bold text**") {
                    foundBoldHighlighting = true
                }
                if color == NSColor.systemBlue && substring.contains("[link](url)") {
                    foundLinkHighlighting = true
                }
            }
        }
        
        #expect(foundHeaderHighlighting)
        #expect(foundBoldHighlighting)
        #expect(foundLinkHighlighting)
    }
    
    // MARK: - CSS Highlighting Tests
    
    @Test("Highlight CSS syntax")
    func testHighlightCSSSyntax() {
        let content = ".class {\n  color: #FF0000;\n  font-size: 12px;\n}"
        
        let result = SyntaxHighlighter.highlight(content: content, language: "css")
        
        #expect(result.length == content.count)
        
        // Check for CSS highlighting
        var foundSelectorHighlighting = false
        var foundPropertyHighlighting = false
        
        result.enumerateAttribute(.foregroundColor, in: NSRange(location: 0, length: result.length)) { value, range, _ in
            if let color = value as? NSColor {
                let substring = (content as NSString).substring(with: range)
                if color == NSColor.systemBlue && substring.contains(".class") {
                    foundSelectorHighlighting = true
                }
                if color == NSColor.systemTeal && (substring.contains("color:") || substring.contains("font-size:")) {
                    foundPropertyHighlighting = true
                }
            }
        }
        
        #expect(foundSelectorHighlighting)
        #expect(foundPropertyHighlighting)
    }
    
    // MARK: - Performance Tests
    
    @Test("Highlight large content efficiently")
    func testHighlightLargeContentEfficiently() {
        // Create a large Swift file content
        var content = "import Foundation\n\n"
        for i in 0..<1000 {
            content += "func function\(i)() {\n    let value = \(i)\n    return value\n}\n\n"
        }
        
        let startTime = Date()
        let result = SyntaxHighlighter.highlight(content: content, language: "swift")
        let endTime = Date()
        
        let duration = endTime.timeIntervalSince(startTime)
        #expect(duration < 2.0) // Should complete within 2 seconds
        
        #expect(result.length == content.count)
        #expect(result.string == content)
    }
    
    // MARK: - Edge Cases
    
    @Test("Handle special characters in content")
    func testHandleSpecialCharactersInContent() {
        let content = "let emoji = \"😀🎉\"\nlet unicode = \"こんにちは\"\nlet symbols = \"@#$%^&*()\""
        
        let result = SyntaxHighlighter.highlight(content: content, language: "swift")
        
        #expect(result.length == content.count)
        #expect(result.string == content)
        
        // Should preserve all special characters
        #expect(result.string.contains("😀🎉"))
        #expect(result.string.contains("こんにちは"))
        #expect(result.string.contains("@#$%^&*()"))
    }
    
    @Test("Handle very long lines")
    func testHandleVeryLongLines() {
        let longString = String(repeating: "a", count: 10000)
        let content = "let longString = \"\(longString)\""
        
        let result = SyntaxHighlighter.highlight(content: content, language: "swift")
        
        #expect(result.length == content.count)
        #expect(result.string == content)
    }
}