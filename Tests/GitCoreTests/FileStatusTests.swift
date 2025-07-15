//
// FileStatusTests.swift
// GitCthulhu
//
// Created by GitCthulhu Team on 2025-07-15.
//

import Foundation
@testable import GitCore
import Testing

struct FileStatusTests {
    
    // MARK: - GitFileStatus Tests
    
    @Test
    func gitFileStatusRawValues() async throws {
        #expect(GitFileStatus.unmodified.rawValue == "unmodified")
        #expect(GitFileStatus.modified.rawValue == "modified")
        #expect(GitFileStatus.added.rawValue == "added")
        #expect(GitFileStatus.deleted.rawValue == "deleted")
        #expect(GitFileStatus.renamed.rawValue == "renamed")
        #expect(GitFileStatus.copied.rawValue == "copied")
        #expect(GitFileStatus.untracked.rawValue == "untracked")
        #expect(GitFileStatus.ignored.rawValue == "ignored")
        #expect(GitFileStatus.typeChanged.rawValue == "typeChanged")
        #expect(GitFileStatus.conflicted.rawValue == "conflicted")
    }
    
    @Test
    func gitFileStatusDisplayNames() async throws {
        #expect(GitFileStatus.unmodified.displayName == "Unmodified")
        #expect(GitFileStatus.modified.displayName == "Modified")
        #expect(GitFileStatus.added.displayName == "Added")
        #expect(GitFileStatus.deleted.displayName == "Deleted")
        #expect(GitFileStatus.renamed.displayName == "Renamed")
        #expect(GitFileStatus.copied.displayName == "Copied")
        #expect(GitFileStatus.untracked.displayName == "Untracked")
        #expect(GitFileStatus.ignored.displayName == "Ignored")
        #expect(GitFileStatus.typeChanged.displayName == "Type Changed")
        #expect(GitFileStatus.conflicted.displayName == "Conflicted")
    }
    
    @Test
    func gitFileStatusSymbols() async throws {
        #expect(GitFileStatus.unmodified.symbolName == "checkmark.circle")
        #expect(GitFileStatus.modified.symbolName == "pencil.circle")
        #expect(GitFileStatus.added.symbolName == "plus.circle")
        #expect(GitFileStatus.deleted.symbolName == "minus.circle")
        #expect(GitFileStatus.renamed.symbolName == "arrow.triangle.2.circlepath")
        #expect(GitFileStatus.copied.symbolName == "doc.on.doc")
        #expect(GitFileStatus.untracked.symbolName == "questionmark.circle")
        #expect(GitFileStatus.ignored.symbolName == "eye.slash")
        #expect(GitFileStatus.typeChanged.symbolName == "arrow.up.arrow.down.circle")
        #expect(GitFileStatus.conflicted.symbolName == "exclamationmark.triangle")
    }
    
    @Test
    func gitFileStatusPriorities() async throws {
        #expect(GitFileStatus.conflicted.priority == 0)
        #expect(GitFileStatus.untracked.priority == 1)
        #expect(GitFileStatus.modified.priority == 2)
        #expect(GitFileStatus.added.priority == 3)
        #expect(GitFileStatus.deleted.priority == 4)
        #expect(GitFileStatus.renamed.priority == 5)
        #expect(GitFileStatus.copied.priority == 6)
        #expect(GitFileStatus.typeChanged.priority == 7)
        #expect(GitFileStatus.ignored.priority == 8)
        #expect(GitFileStatus.unmodified.priority == 9)
    }
    
    @Test
    func gitFileStatusComparison() async throws {
        #expect(GitFileStatus.conflicted < GitFileStatus.untracked)
        #expect(GitFileStatus.untracked < GitFileStatus.modified)
        #expect(GitFileStatus.modified < GitFileStatus.added)
        #expect(GitFileStatus.added < GitFileStatus.deleted)
        #expect(GitFileStatus.deleted < GitFileStatus.renamed)
        #expect(GitFileStatus.renamed < GitFileStatus.copied)
        #expect(GitFileStatus.copied < GitFileStatus.typeChanged)
        #expect(GitFileStatus.typeChanged < GitFileStatus.ignored)
        #expect(GitFileStatus.ignored < GitFileStatus.unmodified)
    }
    
    @Test
    func gitFileStatusCaseIterable() async throws {
        let allCases = GitFileStatus.allCases
        #expect(allCases.count == 10)
        #expect(allCases.contains(.unmodified))
        #expect(allCases.contains(.modified))
        #expect(allCases.contains(.added))
        #expect(allCases.contains(.deleted))
        #expect(allCases.contains(.renamed))
        #expect(allCases.contains(.copied))
        #expect(allCases.contains(.untracked))
        #expect(allCases.contains(.ignored))
        #expect(allCases.contains(.typeChanged))
        #expect(allCases.contains(.conflicted))
    }
    
    // MARK: - FileStatusInfo Tests
    
    @Test
    func fileStatusInfoInitialization() async throws {
        let info = FileStatusInfo(
            path: "test/file.swift",
            workdirStatus: .modified,
            indexStatus: .unmodified,
            isStaged: false,
            isUntracked: false,
            isIgnored: false,
            modificationTime: Date(),
            size: 1024
        )
        
        #expect(info.path == "test/file.swift")
        #expect(info.workdirStatus == .modified)
        #expect(info.indexStatus == .unmodified)
        #expect(info.isStaged == false)
        #expect(info.isUntracked == false)
        #expect(info.isIgnored == false)
        #expect(info.size == 1024)
    }
    
    @Test
    func fileStatusInfoEffectiveStatus() async throws {
        let info1 = FileStatusInfo(
            path: "test.swift",
            workdirStatus: .modified,
            indexStatus: .unmodified,
            isStaged: false,
            isUntracked: false,
            isIgnored: false,
            modificationTime: Date(),
            size: 1024
        )
        #expect(info1.effectiveStatus == .modified)
        
        let info2 = FileStatusInfo(
            path: "test.swift",
            workdirStatus: .modified,
            indexStatus: .added,
            isStaged: true,
            isUntracked: false,
            isIgnored: false,
            modificationTime: Date(),
            size: 1024
        )
        #expect(info2.effectiveStatus == .added)
    }
    
    @Test
    func fileStatusInfoStagableChanges() async throws {
        let stagedInfo = FileStatusInfo(
            path: "test.swift",
            workdirStatus: .modified,
            indexStatus: .modified,
            isStaged: true,
            isUntracked: false,
            isIgnored: false,
            modificationTime: Date(),
            size: 1024
        )
        #expect(stagedInfo.hasStagableChanges == false)
        
        let unstagedInfo = FileStatusInfo(
            path: "test.swift",
            workdirStatus: .modified,
            indexStatus: .unmodified,
            isStaged: false,
            isUntracked: false,
            isIgnored: false,
            modificationTime: Date(),
            size: 1024
        )
        #expect(unstagedInfo.hasStagableChanges == true)
        
        let ignoredInfo = FileStatusInfo(
            path: "test.swift",
            workdirStatus: .ignored,
            indexStatus: .unmodified,
            isStaged: false,
            isUntracked: false,
            isIgnored: true,
            modificationTime: Date(),
            size: 1024
        )
        #expect(ignoredInfo.hasStagableChanges == false)
    }
    
    @Test
    func fileStatusInfoConflicts() async throws {
        let conflictedInfo = FileStatusInfo(
            path: "test.swift",
            workdirStatus: .conflicted,
            indexStatus: .unmodified,
            isStaged: false,
            isUntracked: false,
            isIgnored: false,
            modificationTime: Date(),
            size: 1024
        )
        #expect(conflictedInfo.hasConflicts == true)
        
        let normalInfo = FileStatusInfo(
            path: "test.swift",
            workdirStatus: .modified,
            indexStatus: .unmodified,
            isStaged: false,
            isUntracked: false,
            isIgnored: false,
            modificationTime: Date(),
            size: 1024
        )
        #expect(normalInfo.hasConflicts == false)
    }
    
    @Test
    func fileStatusInfoDisplayProperties() async throws {
        let info = FileStatusInfo(
            path: "src/components/TestComponent.swift",
            workdirStatus: .modified,
            indexStatus: .unmodified,
            isStaged: false,
            isUntracked: false,
            isIgnored: false,
            modificationTime: Date(),
            size: 2048
        )
        
        #expect(info.displayName == "TestComponent.swift")
        #expect(info.directoryPath == "src/components")
        #expect(info.sizeDescription.contains("2")) // Should contain "2" somewhere in the formatted size
    }
    
    @Test
    func fileStatusInfoComparison() async throws {
        let conflictedFile = FileStatusInfo(
            path: "b.swift",
            workdirStatus: .conflicted,
            indexStatus: .unmodified,
            isStaged: false,
            isUntracked: false,
            isIgnored: false,
            modificationTime: Date(),
            size: 1024
        )
        
        let modifiedFile = FileStatusInfo(
            path: "a.swift",
            workdirStatus: .modified,
            indexStatus: .unmodified,
            isStaged: false,
            isUntracked: false,
            isIgnored: false,
            modificationTime: Date(),
            size: 1024
        )
        
        // Conflicted has higher priority than modified
        #expect(conflictedFile < modifiedFile)
        
        let modifiedFile2 = FileStatusInfo(
            path: "z.swift",
            workdirStatus: .modified,
            indexStatus: .unmodified,
            isStaged: false,
            isUntracked: false,
            isIgnored: false,
            modificationTime: Date(),
            size: 1024
        )
        
        // Same status, should sort by path
        #expect(modifiedFile < modifiedFile2)
    }
    
    // MARK: - StatusChange Tests
    
    @Test
    func statusChangeInitialization() async throws {
        let change = FileStatusInfo.StatusChange(
            previousStatus: .unmodified,
            newStatus: .modified,
            timestamp: Date(),
            path: "test.swift"
        )
        
        #expect(change.previousStatus == .unmodified)
        #expect(change.newStatus == .modified)
        #expect(change.path == "test.swift")
    }
    
    @Test
    func statusChangeSignificance() async throws {
        let significantChange = FileStatusInfo.StatusChange(
            previousStatus: .modified,
            newStatus: .added,
            timestamp: Date(),
            path: "test.swift"
        )
        #expect(significantChange.isSignificant == true)
        
        let noChange = FileStatusInfo.StatusChange(
            previousStatus: .modified,
            newStatus: .modified,
            timestamp: Date(),
            path: "test.swift"
        )
        #expect(noChange.isSignificant == false)
        
        let fromUnmodified = FileStatusInfo.StatusChange(
            previousStatus: .unmodified,
            newStatus: .modified,
            timestamp: Date(),
            path: "test.swift"
        )
        #expect(fromUnmodified.isSignificant == false)
    }
    
    @Test
    func statusChangeDescription() async throws {
        let change = FileStatusInfo.StatusChange(
            previousStatus: .modified,
            newStatus: .added,
            timestamp: Date(),
            path: "test.swift"
        )
        
        #expect(change.description == "test.swift: Modified → Added")
    }
    
    @Test
    func createStatusChange() async throws {
        let info = FileStatusInfo(
            path: "test.swift",
            workdirStatus: .modified,
            indexStatus: .unmodified,
            isStaged: false,
            isUntracked: false,
            isIgnored: false,
            modificationTime: Date(),
            size: 1024
        )
        
        let change = info.createStatusChange(to: .added)
        
        #expect(change.previousStatus == .modified)
        #expect(change.newStatus == .added)
        #expect(change.path == "test.swift")
    }
}