//
// SyntaxHighlighterTests.swift
// GitCthulhu
//
// Created by GitCthulhu Team on 2025-07-17.
//

import SwiftUI
@testable import UIKit
import XCTest

final class SyntaxHighlighterTests: XCTestCase {
    private var highlighter: SyntaxHighlighter!

    override func setUp() {
        super.setUp()
        highlighter = SyntaxHighlighter()
    }

    // MARK: - Language Detection Tests

    func testDetectSwiftLanguage() {
        XCTAssertEqual(highlighter.detectLanguage(from: "test.swift"), "swift")
        XCTAssertEqual(highlighter.detectLanguage(from: "path/to/file.swift"), "swift")
        XCTAssertEqual(highlighter.detectLanguage(from: "/absolute/path/MyClass.swift"), "swift")
    }

    func testDetectJavaScriptLanguage() {
        XCTAssertEqual(highlighter.detectLanguage(from: "script.js"), "javascript")
        XCTAssertEqual(highlighter.detectLanguage(from: "component.jsx"), "javascript")
    }

    func testDetectTypeScriptLanguage() {
        XCTAssertEqual(highlighter.detectLanguage(from: "app.ts"), "typescript")
        XCTAssertEqual(highlighter.detectLanguage(from: "component.tsx"), "typescript")
    }

    func testDetectPythonLanguage() {
        XCTAssertEqual(highlighter.detectLanguage(from: "script.py"), "python")
    }

    func testDetectJavaLanguage() {
        XCTAssertEqual(highlighter.detectLanguage(from: "Main.java"), "java")
    }

    func testDetectKotlinLanguage() {
        XCTAssertEqual(highlighter.detectLanguage(from: "Main.kt"), "kotlin")
        XCTAssertEqual(highlighter.detectLanguage(from: "script.kts"), "kotlin")
    }

    func testDetectCppLanguage() {
        XCTAssertEqual(highlighter.detectLanguage(from: "main.cpp"), "cpp")
        XCTAssertEqual(highlighter.detectLanguage(from: "file.cc"), "cpp")
        XCTAssertEqual(highlighter.detectLanguage(from: "code.cxx"), "cpp")
        XCTAssertEqual(highlighter.detectLanguage(from: "program.c++"), "cpp")
    }

    func testDetectCLanguage() {
        XCTAssertEqual(highlighter.detectLanguage(from: "main.c"), "c")
    }

    func testDetectHeaderLanguage() {
        XCTAssertEqual(highlighter.detectLanguage(from: "header.h"), "header")
        XCTAssertEqual(highlighter.detectLanguage(from: "header.hpp"), "header")
        XCTAssertEqual(highlighter.detectLanguage(from: "header.hxx"), "header")
    }

    func testDetectRustLanguage() {
        XCTAssertEqual(highlighter.detectLanguage(from: "main.rs"), "rust")
    }

    func testDetectGoLanguage() {
        XCTAssertEqual(highlighter.detectLanguage(from: "main.go"), "go")
    }

    func testDetectMarkupLanguages() {
        XCTAssertEqual(highlighter.detectLanguage(from: "index.html"), "html")
        XCTAssertEqual(highlighter.detectLanguage(from: "page.htm"), "html")
        XCTAssertEqual(highlighter.detectLanguage(from: "styles.css"), "css")
        XCTAssertEqual(highlighter.detectLanguage(from: "styles.scss"), "scss")
        XCTAssertEqual(highlighter.detectLanguage(from: "styles.sass"), "scss")
        XCTAssertEqual(highlighter.detectLanguage(from: "data.xml"), "xml")
    }

    func testDetectConfigLanguages() {
        XCTAssertEqual(highlighter.detectLanguage(from: "config.json"), "json")
        XCTAssertEqual(highlighter.detectLanguage(from: "config.yaml"), "yaml")
        XCTAssertEqual(highlighter.detectLanguage(from: "config.yml"), "yaml")
        XCTAssertEqual(highlighter.detectLanguage(from: "config.toml"), "toml")
    }

    func testDetectScriptLanguages() {
        XCTAssertEqual(highlighter.detectLanguage(from: "script.sh"), "shell")
        XCTAssertEqual(highlighter.detectLanguage(from: "script.bash"), "shell")
        XCTAssertEqual(highlighter.detectLanguage(from: "query.sql"), "sql")
    }

    func testDetectDocumentationLanguages() {
        XCTAssertEqual(highlighter.detectLanguage(from: "README.md"), "markdown")
        XCTAssertEqual(highlighter.detectLanguage(from: "docs.markdown"), "markdown")
    }

    func testDetectUnknownLanguage() {
        XCTAssertEqual(highlighter.detectLanguage(from: "unknown.xyz"), "text")
        XCTAssertEqual(highlighter.detectLanguage(from: "noextension"), "text")
        XCTAssertEqual(highlighter.detectLanguage(from: ""), "text")
    }

    func testDetectCaseInsensitive() {
        XCTAssertEqual(highlighter.detectLanguage(from: "FILE.SWIFT"), "swift")
        XCTAssertEqual(highlighter.detectLanguage(from: "Script.JS"), "javascript")
        XCTAssertEqual(highlighter.detectLanguage(from: "Data.JSON"), "json")
    }

    // MARK: - Basic Highlighting Tests

    func testHighlightSwiftKeywords() {
        // Given
        let code = "func test() { let value = true }"

        // When
        let result = highlighter.highlight(code, language: "swift")

        // Then
        XCTAssertFalse(String(result.characters).isEmpty)
        XCTAssertEqual(String(result.characters), code)

        // Verify that the result contains the original text
        XCTAssertTrue(String(result.characters).contains("func"))
        XCTAssertTrue(String(result.characters).contains("let"))
        XCTAssertTrue(String(result.characters).contains("true"))
    }

    func testHighlightJavaScriptKeywords() {
        // Given
        let code = "function test() { const value = true; }"

        // When
        let result = highlighter.highlight(code, language: "javascript")

        // Then
        XCTAssertEqual(String(result.characters), code)
        XCTAssertTrue(String(result.characters).contains("function"))
        XCTAssertTrue(String(result.characters).contains("const"))
    }

    func testHighlightPythonKeywords() {
        // Given
        let code = "def test(): return True"

        // When
        let result = highlighter.highlight(code, language: "python")

        // Then
        XCTAssertEqual(String(result.characters), code)
        XCTAssertTrue(String(result.characters).contains("def"))
        XCTAssertTrue(String(result.characters).contains("return"))
        XCTAssertTrue(String(result.characters).contains("True"))
    }

    func testHighlightJavaKeywords() {
        // Given
        let code = "public class Test { private boolean value = true; }"

        // When
        let result = highlighter.highlight(code, language: "java")

        // Then
        XCTAssertEqual(String(result.characters), code)
        XCTAssertTrue(String(result.characters).contains("public"))
        XCTAssertTrue(String(result.characters).contains("class"))
        XCTAssertTrue(String(result.characters).contains("private"))
    }

    func testHighlightStrings() {
        // Given
        let code = "let message = \"Hello World\""

        // When
        let result = highlighter.highlight(code, language: "swift")

        // Then
        XCTAssertEqual(String(result.characters), code)
        XCTAssertTrue(String(result.characters).contains("\"Hello World\""))
    }

    func testHighlightComments() {
        // Given
        let code = "// This is a comment\nlet value = true"

        // When
        let result = highlighter.highlight(code, language: "swift")

        // Then
        XCTAssertEqual(String(result.characters), code)
        XCTAssertTrue(String(result.characters).contains("// This is a comment"))
    }

    func testHighlightNumbers() {
        // Given
        let code = "let count = 42\nlet price = 19.99"

        // When
        let result = highlighter.highlight(code, language: "swift")

        // Then
        XCTAssertEqual(String(result.characters), code)
        XCTAssertTrue(String(result.characters).contains("42"))
        XCTAssertTrue(String(result.characters).contains("19.99"))
    }

    // MARK: - JSON Highlighting Tests

    func testHighlightJSON() {
        // Given
        let code = """
        {
          "name": "test",
          "version": 1.0,
          "active": true,
          "data": null
        }
        """

        // When
        let result = highlighter.highlight(code, language: "json")

        // Then
        XCTAssertEqual(String(result.characters), code)
        XCTAssertTrue(String(result.characters).contains("\"name\""))
        XCTAssertTrue(String(result.characters).contains("true"))
        XCTAssertTrue(String(result.characters).contains("null"))
    }

    // MARK: - XML/HTML Highlighting Tests

    func testHighlightXML() {
        // Given
        let code = "<root><item value=\"test\">content</item></root>"

        // When
        let result = highlighter.highlight(code, language: "xml")

        // Then
        XCTAssertEqual(String(result.characters), code)
        XCTAssertTrue(String(result.characters).contains("<root>"))
        XCTAssertTrue(String(result.characters).contains("value=\"test\""))
    }

    // MARK: - Shell Highlighting Tests

    func testHighlightShell() {
        // Given
        let code = "#!/bin/bash\necho \"Hello $USER\"\nif [ -f file.txt ]; then\n  echo \"File exists\"\nfi"

        // When
        let result = highlighter.highlight(code, language: "shell")

        // Then
        XCTAssertEqual(String(result.characters), code)
        XCTAssertTrue(String(result.characters).contains("echo"))
        XCTAssertTrue(String(result.characters).contains("if"))
        XCTAssertTrue(String(result.characters).contains("$USER"))
    }

    // MARK: - Generic Highlighting Tests

    func testHighlightUnknownLanguage() {
        // Given
        let code = "Some random text with \"strings\" and 123 numbers"

        // When
        let result = highlighter.highlight(code, language: "unknown")

        // Then
        XCTAssertEqual(String(result.characters), code)
        XCTAssertTrue(String(result.characters).contains("\"strings\""))
        XCTAssertTrue(String(result.characters).contains("123"))
    }

    func testHighlightEmptyString() {
        // Given
        let code = ""

        // When
        let result = highlighter.highlight(code, language: "swift")

        // Then
        XCTAssertTrue(String(result.characters).isEmpty)
    }

    func testHighlightSingleCharacter() {
        // Given
        let code = "x"

        // When
        let result = highlighter.highlight(code, language: "swift")

        // Then
        XCTAssertEqual(String(result.characters), "x")
    }

    // MARK: - Complex Code Tests

    func testHighlightComplexSwiftCode() {
        // Given
        let code = """
        import Foundation

        class TestClass: NSObject {
            private let value: String = "test"

            func calculate() -> Int {
                // Calculate something
                return 42
            }
        }
        """

        // When
        let result = highlighter.highlight(code, language: "swift")

        // Then
        XCTAssertEqual(String(result.characters), code)
        XCTAssertTrue(String(result.characters).contains("import"))
        XCTAssertTrue(String(result.characters).contains("class"))
        XCTAssertTrue(String(result.characters).contains("private"))
        XCTAssertTrue(String(result.characters).contains("func"))
        XCTAssertTrue(String(result.characters).contains("// Calculate something"))
    }

    func testHighlightComplexJavaScriptCode() {
        // Given
        let code = """
        const users = [
          { name: "John", age: 30 },
          { name: "Jane", age: 25 }
        ];

        function getAdults() {
          return users.filter(user => user.age >= 18);
        }
        """

        // When
        let result = highlighter.highlight(code, language: "javascript")

        // Then
        XCTAssertEqual(String(result.characters), code)
        XCTAssertTrue(String(result.characters).contains("const"))
        XCTAssertTrue(String(result.characters).contains("function"))
        XCTAssertTrue(String(result.characters).contains("return"))
    }

    // MARK: - Performance Tests

    func testHighlightingPerformance() {
        // Given
        var largeCode = ""
        for i in 1 ... 1000 {
            largeCode += "func function\(i)() { let value\(i) = \"\(i)\" }\n"
        }

        // When/Then
        measure {
            _ = highlighter.highlight(largeCode, language: "swift")
        }
    }

    func testLanguageDetectionPerformance() {
        // Given
        let filePaths = (1 ... 1000).map { "file\($0).swift" }

        // When/Then
        measure {
            for path in filePaths {
                _ = highlighter.detectLanguage(from: path)
            }
        }
    }
}
