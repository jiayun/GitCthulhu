//
// FileListViewTests.swift
// GitCthulhu
//
// Created by GitCthulhu Team on 2025-07-15.
//

import GitCore
import SwiftUI
import Testing
import UIKit

@testable import GitCthulhu

struct FileListViewTests {
    
    @Test("FileStatusInfo should initialize correctly")
    func testFileStatusInfoInitialization() {
        // Given
        let fileName = "test.swift"
        let filePath = "Sources/GitCthulhu/test.swift"
        let status = GitFileStatus.modified
        let isStaged = true
        let isUnstaged = false
        let fileSize: Int64 = 1024
        let modificationDate = Date()
        
        // When
        let fileInfo = FileStatusInfo(
            fileName: fileName,
            filePath: filePath,
            status: status,
            isStaged: isStaged,
            isUnstaged: isUnstaged,
            fileSize: fileSize,
            modificationDate: modificationDate
        )
        
        // Then
        #expect(fileInfo.fileName == fileName)
        #expect(fileInfo.filePath == filePath)
        #expect(fileInfo.status == status)
        #expect(fileInfo.isStaged == isStaged)
        #expect(fileInfo.isUnstaged == isUnstaged)
        #expect(fileInfo.fileSize == fileSize)
        #expect(fileInfo.modificationDate == modificationDate)
        #expect(fileInfo.id == filePath)
    }
    
    @Test("FileStatusInfo should provide correct status descriptions")
    func testFileStatusDescriptions() {
        // Test staged file
        let stagedFile = FileStatusInfo(
            fileName: "test.swift",
            filePath: "test.swift",
            status: .added,
            isStaged: true,
            isUnstaged: false
        )
        #expect(stagedFile.statusDescription == "Staged")
        
        // Test staged and modified file
        let stagedAndModifiedFile = FileStatusInfo(
            fileName: "test.swift",
            filePath: "test.swift",
            status: .modified,
            isStaged: true,
            isUnstaged: true
        )
        #expect(stagedAndModifiedFile.statusDescription == "Staged & Modified")
        
        // Test unstaged file
        let unstagedFile = FileStatusInfo(
            fileName: "test.swift",
            filePath: "test.swift",
            status: .modified,
            isStaged: false,
            isUnstaged: true
        )
        #expect(unstagedFile.statusDescription == "Modified")
    }
    
    @Test("FileStatusInfo should provide correct group categories")
    func testFileGroupCategories() {
        // Test untracked file
        let untrackedFile = FileStatusInfo(
            fileName: "test.swift",
            filePath: "test.swift",
            status: .untracked
        )
        #expect(untrackedFile.groupCategory == .untracked)
        
        // Test staged file
        let stagedFile = FileStatusInfo(
            fileName: "test.swift",
            filePath: "test.swift",
            status: .added,
            isStaged: true
        )
        #expect(stagedFile.groupCategory == .staged)
        
        // Test modified file
        let modifiedFile = FileStatusInfo(
            fileName: "test.swift",
            filePath: "test.swift",
            status: .modified,
            isStaged: false,
            isUnstaged: true
        )
        #expect(modifiedFile.groupCategory == .modified)
        
        // Test staged modified file
        let stagedModifiedFile = FileStatusInfo(
            fileName: "test.swift",
            filePath: "test.swift",
            status: .modified,
            isStaged: true,
            isUnstaged: false
        )
        #expect(stagedModifiedFile.groupCategory == .staged)
        
        // Test conflicted file
        let conflictedFile = FileStatusInfo(
            fileName: "test.swift",
            filePath: "test.swift",
            status: .unmerged
        )
        #expect(conflictedFile.groupCategory == .conflicted)
    }
    
    @Test("FileStatusInfo should format file sizes correctly")
    func testFileFormattedSizes() {
        // Test small file
        let smallFile = FileStatusInfo(
            fileName: "test.swift",
            filePath: "test.swift",
            status: .modified,
            fileSize: 1024
        )
        #expect(smallFile.formattedFileSize?.contains("KB") == true)
        
        // Test large file
        let largeFile = FileStatusInfo(
            fileName: "test.swift",
            filePath: "test.swift",
            status: .modified,
            fileSize: 1024 * 1024 * 2
        )
        #expect(largeFile.formattedFileSize?.contains("MB") == true)
        
        // Test file without size
        let noSizeFile = FileStatusInfo(
            fileName: "test.swift",
            filePath: "test.swift",
            status: .modified,
            fileSize: nil
        )
        #expect(noSizeFile.formattedFileSize == nil)
    }
    
    @Test("FileGroupCategory should have correct priorities")
    func testFileGroupPriorities() {
        let categories = FileGroupCategory.allCases.sorted(by: { $0.priority < $1.priority })
        
        // Conflicted should have highest priority (lowest number)
        #expect(categories.first == .conflicted)
        #expect(FileGroupCategory.conflicted.priority == 0)
        
        // Ignored should have lowest priority (highest number)
        #expect(categories.last == .ignored)
        #expect(FileGroupCategory.ignored.priority == 5)
    }
    
    @Test("FileGroupCategory should have correct display names")
    func testFileGroupDisplayNames() {
        #expect(FileGroupCategory.staged.displayName == "Staged")
        #expect(FileGroupCategory.modified.displayName == "Modified")
        #expect(FileGroupCategory.untracked.displayName == "Untracked")
        #expect(FileGroupCategory.deleted.displayName == "Deleted")
        #expect(FileGroupCategory.conflicted.displayName == "Conflicted")
        #expect(FileGroupCategory.ignored.displayName == "Ignored")
    }
    
    @Test("FileGroupCategory should have correct symbol names")
    func testFileGroupSymbolNames() {
        #expect(FileGroupCategory.staged.symbolName == "checkmark.circle.fill")
        #expect(FileGroupCategory.modified.symbolName == "pencil.circle.fill")
        #expect(FileGroupCategory.untracked.symbolName == "questionmark.circle.fill")
        #expect(FileGroupCategory.deleted.symbolName == "minus.circle.fill")
        #expect(FileGroupCategory.conflicted.symbolName == "exclamationmark.triangle.fill")
        #expect(FileGroupCategory.ignored.symbolName == "eye.slash.fill")
    }
}