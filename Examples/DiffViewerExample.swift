//
// DiffViewerExample.swift
// GitCthulhu
//
// Created by GitCthulhu Team on 2025-07-15.
//

import SwiftUI
import GitCore
@testable import GitCthulhu

// MARK: - DiffViewer Usage Examples

/// Example of how to use the DiffViewer component in your SwiftUI application
struct DiffViewerExample: View {
    
    var body: some View {
        VStack {
            Text("DiffViewer Examples")
                .font(.title)
                .padding()
            
            TabView {
                // Example 1: Simple diff
                simpleDiffExample
                    .tabItem {
                        Label("Simple Diff", systemImage: "doc.text")
                    }
                
                // Example 2: Complex diff with multiple hunks
                complexDiffExample
                    .tabItem {
                        Label("Complex Diff", systemImage: "doc.text.below.ellipsis")
                    }
                
                // Example 3: Binary file diff
                binaryFileExample
                    .tabItem {
                        Label("Binary File", systemImage: "doc.binary")
                    }
                
                // Example 4: New file diff
                newFileExample
                    .tabItem {
                        Label("New File", systemImage: "doc.badge.plus")
                    }
            }
        }
        .frame(width: 1000, height: 700)
    }
    
    // MARK: - Simple Diff Example
    
    private var simpleDiffExample: some View {
        VStack {
            Text("Simple Diff Example")
                .font(.headline)
                .padding()
            
            DiffViewer(diffContent: createSimpleDiffContent())
        }
    }
    
    private func createSimpleDiffContent() -> DiffContent {
        return DiffContent(
            filePath: "Sources/GitCore/Example.swift",
            hunks: [
                DiffHunk(
                    oldStartLine: 1,
                    oldLineCount: 5,
                    newStartLine: 1,
                    newLineCount: 6,
                    context: "function example()",
                    lines: [
                        DiffLine(type: .context, content: "import Foundation", oldLineNumber: 1, newLineNumber: 1),
                        DiffLine(type: .context, content: "", oldLineNumber: 2, newLineNumber: 2),
                        DiffLine(type: .removed, content: "func oldFunction() {", oldLineNumber: 3, newLineNumber: nil),
                        DiffLine(type: .added, content: "func newFunction() {", oldLineNumber: nil, newLineNumber: 3),
                        DiffLine(type: .added, content: "    print(\"Hello, World!\")", oldLineNumber: nil, newLineNumber: 4),
                        DiffLine(type: .context, content: "}", oldLineNumber: 4, newLineNumber: 5)
                    ]
                )
            ],
            statistics: DiffStatistics(additions: 2, deletions: 1)
        )
    }
    
    // MARK: - Complex Diff Example
    
    private var complexDiffExample: some View {
        VStack {
            Text("Complex Diff with Multiple Hunks")
                .font(.headline)
                .padding()
            
            DiffViewer(diffContent: createComplexDiffContent())
        }
    }
    
    private func createComplexDiffContent() -> DiffContent {
        return DiffContent(
            filePath: "Sources/GitCore/ComplexFile.swift",
            hunks: [
                DiffHunk(
                    oldStartLine: 1,
                    oldLineCount: 10,
                    newStartLine: 1,
                    newLineCount: 12,
                    context: "class ComplexClass",
                    lines: [
                        DiffLine(type: .context, content: "import Foundation", oldLineNumber: 1, newLineNumber: 1),
                        DiffLine(type: .context, content: "", oldLineNumber: 2, newLineNumber: 2),
                        DiffLine(type: .context, content: "class ComplexClass {", oldLineNumber: 3, newLineNumber: 3),
                        DiffLine(type: .removed, content: "    private var oldProperty: String", oldLineNumber: 4, newLineNumber: nil),
                        DiffLine(type: .added, content: "    private var newProperty: String", oldLineNumber: nil, newLineNumber: 4),
                        DiffLine(type: .added, content: "    private var additionalProperty: Int", oldLineNumber: nil, newLineNumber: 5),
                        DiffLine(type: .context, content: "", oldLineNumber: 5, newLineNumber: 6),
                        DiffLine(type: .context, content: "    func method() {", oldLineNumber: 6, newLineNumber: 7),
                        DiffLine(type: .removed, content: "        print(\"old\")", oldLineNumber: 7, newLineNumber: nil),
                        DiffLine(type: .added, content: "        print(\"new\")", oldLineNumber: nil, newLineNumber: 8),
                        DiffLine(type: .context, content: "    }", oldLineNumber: 8, newLineNumber: 9),
                        DiffLine(type: .context, content: "}", oldLineNumber: 9, newLineNumber: 10)
                    ]
                ),
                DiffHunk(
                    oldStartLine: 20,
                    oldLineCount: 5,
                    newStartLine: 22,
                    newLineCount: 6,
                    context: "extension ComplexClass",
                    lines: [
                        DiffLine(type: .context, content: "extension ComplexClass {", oldLineNumber: 20, newLineNumber: 22),
                        DiffLine(type: .removed, content: "    // old comment", oldLineNumber: 21, newLineNumber: nil),
                        DiffLine(type: .added, content: "    // new comment", oldLineNumber: nil, newLineNumber: 23),
                        DiffLine(type: .added, content: "    // additional comment", oldLineNumber: nil, newLineNumber: 24),
                        DiffLine(type: .context, content: "}", oldLineNumber: 22, newLineNumber: 25)
                    ]
                )
            ],
            statistics: DiffStatistics(additions: 4, deletions: 2)
        )
    }
    
    // MARK: - Binary File Example
    
    private var binaryFileExample: some View {
        VStack {
            Text("Binary File Diff Example")
                .font(.headline)
                .padding()
            
            DiffViewer(diffContent: createBinaryFileDiffContent())
        }
    }
    
    private func createBinaryFileDiffContent() -> DiffContent {
        return DiffContent(
            filePath: "assets/images/logo.png",
            isBinary: true,
            statistics: DiffStatistics()
        )
    }
    
    // MARK: - New File Example
    
    private var newFileExample: some View {
        VStack {
            Text("New File Diff Example")
                .font(.headline)
                .padding()
            
            DiffViewer(diffContent: createNewFileDiffContent())
        }
    }
    
    private func createNewFileDiffContent() -> DiffContent {
        return DiffContent(
            filePath: "Sources/GitCore/NewFile.swift",
            hunks: [
                DiffHunk(
                    oldStartLine: 0,
                    oldLineCount: 0,
                    newStartLine: 1,
                    newLineCount: 15,
                    lines: [
                        DiffLine(type: .added, content: "//", oldLineNumber: nil, newLineNumber: 1),
                        DiffLine(type: .added, content: "// NewFile.swift", oldLineNumber: nil, newLineNumber: 2),
                        DiffLine(type: .added, content: "// GitCthulhu", oldLineNumber: nil, newLineNumber: 3),
                        DiffLine(type: .added, content: "//", oldLineNumber: nil, newLineNumber: 4),
                        DiffLine(type: .added, content: "", oldLineNumber: nil, newLineNumber: 5),
                        DiffLine(type: .added, content: "import Foundation", oldLineNumber: nil, newLineNumber: 6),
                        DiffLine(type: .added, content: "", oldLineNumber: nil, newLineNumber: 7),
                        DiffLine(type: .added, content: "public class NewFile {", oldLineNumber: nil, newLineNumber: 8),
                        DiffLine(type: .added, content: "    public init() {", oldLineNumber: nil, newLineNumber: 9),
                        DiffLine(type: .added, content: "        // Initialize new file", oldLineNumber: nil, newLineNumber: 10),
                        DiffLine(type: .added, content: "    }", oldLineNumber: nil, newLineNumber: 11),
                        DiffLine(type: .added, content: "", oldLineNumber: nil, newLineNumber: 12),
                        DiffLine(type: .added, content: "    public func doSomething() {", oldLineNumber: nil, newLineNumber: 13),
                        DiffLine(type: .added, content: "        print(\"New functionality\")", oldLineNumber: nil, newLineNumber: 14),
                        DiffLine(type: .added, content: "    }", oldLineNumber: nil, newLineNumber: 15),
                        DiffLine(type: .added, content: "}", oldLineNumber: nil, newLineNumber: 16)
                    ]
                )
            ],
            isNewFile: true,
            statistics: DiffStatistics(additions: 16, deletions: 0)
        )
    }
}

// MARK: - DiffParser Usage Examples

/// Example of how to use the DiffParser to parse Git diff output
struct DiffParserExample {
    
    /// Parse a simple Git diff output
    static func parseSimpleDiff() -> [DiffContent] {
        let diffOutput = """
        diff --git a/test.txt b/test.txt
        index 1234567..abcdefg 100644
        --- a/test.txt
        +++ b/test.txt
        @@ -1,3 +1,4 @@
         line 1
        -line 2
        +line 2 modified
        +line 3 added
         line 4
        """
        
        let parser = DiffParser()
        return parser.parse(diffOutput)
    }
    
    /// Parse a complex Git diff output with multiple files
    static func parseComplexDiff() -> [DiffContent] {
        let diffOutput = """
        diff --git a/file1.swift b/file1.swift
        index 1234567..abcdefg 100644
        --- a/file1.swift
        +++ b/file1.swift
        @@ -1,5 +1,6 @@
         import Foundation
         
         class TestClass {
        -    func oldMethod() {
        +    func newMethod() {
        +        print("Added functionality")
             }
         }
        diff --git a/file2.js b/file2.js
        index 2345678..bcdefgh 100644
        --- a/file2.js
        +++ b/file2.js
        @@ -1,3 +1,4 @@
         function test() {
        -    console.log("old");
        +    console.log("new");
        +    console.log("additional");
         }
        """
        
        let parser = DiffParser()
        return parser.parse(diffOutput)
    }
    
    /// Parse a binary file diff
    static func parseBinaryFileDiff() -> [DiffContent] {
        let diffOutput = """
        diff --git a/image.png b/image.png
        index 1234567..abcdefg 100644
        Binary files a/image.png and b/image.png differ
        """
        
        let parser = DiffParser()
        return parser.parse(diffOutput)
    }
}

// MARK: - SyntaxHighlighter Usage Examples

/// Example of how to use the SyntaxHighlighter for different programming languages
struct SyntaxHighlighterExample {
    
    /// Highlight Swift code
    static func highlightSwiftCode() -> NSAttributedString {
        let swiftCode = """
        import Foundation
        
        class ExampleClass {
            private let property: String
            
            init(property: String) {
                self.property = property
            }
            
            func method() -> String {
                return "Hello, \\(property)!"
            }
        }
        """
        
        return SyntaxHighlighter.highlight(
            content: swiftCode,
            language: "swift",
            lineType: .context
        )
    }
    
    /// Highlight JavaScript code
    static func highlightJavaScriptCode() -> NSAttributedString {
        let jsCode = """
        function greet(name) {
            const message = `Hello, ${name}!`;
            console.log(message);
            return message;
        }
        
        const result = greet("World");
        """
        
        return SyntaxHighlighter.highlight(
            content: jsCode,
            language: "javascript",
            lineType: .added
        )
    }
    
    /// Highlight Python code
    static func highlightPythonCode() -> NSAttributedString {
        let pythonCode = """
        def greet(name):
            message = f"Hello, {name}!"
            print(message)
            return message
        
        if __name__ == "__main__":
            result = greet("World")
        """
        
        return SyntaxHighlighter.highlight(
            content: pythonCode,
            language: "python",
            lineType: .removed
        )
    }
    
    /// Highlight JSON data
    static func highlightJSONData() -> NSAttributedString {
        let jsonData = """
        {
            "name": "John Doe",
            "age": 30,
            "isActive": true,
            "hobbies": ["reading", "coding", "gaming"],
            "address": {
                "street": "123 Main St",
                "city": "Anytown",
                "country": "USA"
            }
        }
        """
        
        return SyntaxHighlighter.highlight(
            content: jsonData,
            language: "json",
            lineType: .context
        )
    }
}

// MARK: - Integration with GitCommandExecutor

/// Example of how to integrate the DiffViewer with GitCommandExecutor
struct GitIntegrationExample {
    
    /// Get diff content from Git and display it in DiffViewer
    static func createDiffViewerFromGitOutput() async throws -> DiffViewer {
        // This would be used in a real application
        // let gitExecutor = GitCommandExecutor(repositoryURL: repositoryURL)
        // let diffOutput = try await gitExecutor.getDiff()
        
        // For demonstration, we'll use mock data
        let mockDiffOutput = """
        diff --git a/Sources/GitCore/Example.swift b/Sources/GitCore/Example.swift
        index 1234567..abcdefg 100644
        --- a/Sources/GitCore/Example.swift
        +++ b/Sources/GitCore/Example.swift
        @@ -1,8 +1,10 @@
         import Foundation
         
         class Example {
        -    func oldMethod() {
        -        print("old implementation")
        +    func newMethod() {
        +        print("new implementation")
        +        print("additional functionality")
             }
        +    
        +    func additionalMethod() {
        +        print("brand new method")
         }
        """
        
        let parser = DiffParser()
        let diffContents = parser.parse(mockDiffOutput)
        
        guard let diffContent = diffContents.first else {
            throw NSError(domain: "GitIntegrationExample", code: 1, userInfo: [NSLocalizedDescriptionKey: "No diff content found"])
        }
        
        return DiffViewer(diffContent: diffContent)
    }
}

#Preview {
    DiffViewerExample()
}