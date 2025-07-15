//
// StatusGroupTests.swift
// GitCthulhu
//
// Created by GitCthulhu Team on 2025-07-15.
//

import Foundation
@testable import GitCore
import Testing

struct StatusGroupTests {
    
    // MARK: - Test Data Helper
    
    private func createTestFileStatusInfo(
        path: String,
        workdirStatus: GitFileStatus = .modified,
        indexStatus: GitFileStatus = .unmodified,
        isStaged: Bool = false,
        isUntracked: Bool = false,
        isIgnored: Bool = false,
        size: Int64 = 1024
    ) -> FileStatusInfo {
        FileStatusInfo(
            path: path,
            workdirStatus: workdirStatus,
            indexStatus: indexStatus,
            isStaged: isStaged,
            isUntracked: isUntracked,
            isIgnored: isIgnored,
            modificationTime: Date(),
            size: size
        )
    }
    
    // MARK: - StatusGroup Tests
    
    @Test
    func statusGroupInitialization() async throws {
        let files = [
            createTestFileStatusInfo(path: "file1.swift", workdirStatus: .modified),
            createTestFileStatusInfo(path: "file2.swift", workdirStatus: .modified)
        ]
        
        let group = StatusGroup(status: .modified, files: files)
        
        #expect(group.status == .modified)
        #expect(group.files.count == 2)
        #expect(group.count == 2)
        #expect(group.isEmpty == false)
    }
    
    @Test
    func statusGroupDisplayName() async throws {
        let singleFile = [createTestFileStatusInfo(path: "file1.swift")]
        let singleGroup = StatusGroup(status: .modified, files: singleFile)
        #expect(singleGroup.displayName == "Modified (1 file)")
        
        let multipleFiles = [
            createTestFileStatusInfo(path: "file1.swift"),
            createTestFileStatusInfo(path: "file2.swift")
        ]
        let multipleGroup = StatusGroup(status: .added, files: multipleFiles)
        #expect(multipleGroup.displayName == "Added (2 files)")
    }
    
    @Test
    func statusGroupTotalSize() async throws {
        let files = [
            createTestFileStatusInfo(path: "file1.swift", size: 1024),
            createTestFileStatusInfo(path: "file2.swift", size: 2048)
        ]
        
        let group = StatusGroup(status: .modified, files: files)
        
        #expect(group.totalSize == 3072)
        #expect(group.totalSizeDescription.contains("3")) // Should contain "3" somewhere
    }
    
    @Test
    func statusGroupStagingProperties() async throws {
        let files = [
            createTestFileStatusInfo(path: "file1.swift", isStaged: true),
            createTestFileStatusInfo(path: "file2.swift", isStaged: true)
        ]
        
        let allStagedGroup = StatusGroup(status: .modified, files: files)
        #expect(allStagedGroup.allStaged == true)
        #expect(allStagedGroup.anyStaged == true)
        
        let mixedFiles = [
            createTestFileStatusInfo(path: "file1.swift", isStaged: true),
            createTestFileStatusInfo(path: "file2.swift", isStaged: false)
        ]
        
        let mixedGroup = StatusGroup(status: .modified, files: mixedFiles)
        #expect(mixedGroup.allStaged == false)
        #expect(mixedGroup.anyStaged == true)
        
        let unstagedFiles = [
            createTestFileStatusInfo(path: "file1.swift", isStaged: false),
            createTestFileStatusInfo(path: "file2.swift", isStaged: false)
        ]
        
        let unstagedGroup = StatusGroup(status: .modified, files: unstagedFiles)
        #expect(unstagedGroup.allStaged == false)
        #expect(unstagedGroup.anyStaged == false)
    }
    
    @Test
    func statusGroupConflictDetection() async throws {
        let normalFiles = [
            createTestFileStatusInfo(path: "file1.swift", workdirStatus: .modified),
            createTestFileStatusInfo(path: "file2.swift", workdirStatus: .added)
        ]
        
        let normalGroup = StatusGroup(status: .modified, files: normalFiles)
        #expect(normalGroup.anyHaveConflicts == false)
        
        let conflictedFiles = [
            createTestFileStatusInfo(path: "file1.swift", workdirStatus: .modified),
            createTestFileStatusInfo(path: "file2.swift", workdirStatus: .conflicted)
        ]
        
        let conflictedGroup = StatusGroup(status: .modified, files: conflictedFiles)
        #expect(conflictedGroup.anyHaveConflicts == true)
    }
    
    @Test
    func statusGroupComparison() async throws {
        let modifiedGroup = StatusGroup(status: .modified, files: [])
        let addedGroup = StatusGroup(status: .added, files: [])
        let conflictedGroup = StatusGroup(status: .conflicted, files: [])
        
        #expect(conflictedGroup < modifiedGroup)
        #expect(modifiedGroup < addedGroup)
    }
    
    @Test
    func statusGroupSorting() async throws {
        let files = [
            createTestFileStatusInfo(path: "zebra.swift"),
            createTestFileStatusInfo(path: "alpha.swift"),
            createTestFileStatusInfo(path: "beta.swift")
        ]
        
        let group = StatusGroup(status: .modified, files: files)
        
        // Files should be sorted alphabetically
        #expect(group.files[0].path == "alpha.swift")
        #expect(group.files[1].path == "beta.swift")
        #expect(group.files[2].path == "zebra.swift")
    }
    
    // MARK: - StatusGrouping Tests
    
    @Test
    func statusGroupingByStatus() async throws {
        let files = [
            createTestFileStatusInfo(path: "file1.swift", workdirStatus: .modified),
            createTestFileStatusInfo(path: "file2.swift", workdirStatus: .modified),
            createTestFileStatusInfo(path: "file3.swift", workdirStatus: .added),
            createTestFileStatusInfo(path: "file4.swift", workdirStatus: .added),
            createTestFileStatusInfo(path: "file5.swift", workdirStatus: .deleted)
        ]
        
        let groups = StatusGrouping.groupByStatus(files)
        
        #expect(groups.count == 3)
        
        let modifiedGroup = groups.first { $0.status == .modified }
        #expect(modifiedGroup?.count == 2)
        
        let addedGroup = groups.first { $0.status == .added }
        #expect(addedGroup?.count == 2)
        
        let deletedGroup = groups.first { $0.status == .deleted }
        #expect(deletedGroup?.count == 1)
    }
    
    @Test
    func statusGroupingByStaging() async throws {
        let files = [
            createTestFileStatusInfo(path: "file1.swift", isStaged: true),
            createTestFileStatusInfo(path: "file2.swift", isStaged: true),
            createTestFileStatusInfo(path: "file3.swift", isStaged: false),
            createTestFileStatusInfo(path: "file4.swift", isStaged: false)
        ]
        
        let (staged, unstaged) = StatusGrouping.groupByStaging(files)
        
        #expect(staged.count == 2)
        #expect(unstaged.count == 2)
        #expect(staged.allSatisfy(\.isStaged))
        #expect(unstaged.allSatisfy { !$0.isStaged })
    }
    
    @Test
    func statusGroupingByDirectory() async throws {
        let files = [
            createTestFileStatusInfo(path: "src/file1.swift"),
            createTestFileStatusInfo(path: "src/file2.swift"),
            createTestFileStatusInfo(path: "tests/file3.swift"),
            createTestFileStatusInfo(path: "docs/file4.swift")
        ]
        
        let grouped = StatusGrouping.groupByDirectory(files)
        
        #expect(grouped.count == 3)
        #expect(grouped["src"]?.count == 2)
        #expect(grouped["tests"]?.count == 1)
        #expect(grouped["docs"]?.count == 1)
    }
    
    @Test
    func statusGroupingCreateSummary() async throws {
        let files = [
            createTestFileStatusInfo(path: "file1.swift", workdirStatus: .modified),
            createTestFileStatusInfo(path: "file2.swift", workdirStatus: .added),
            createTestFileStatusInfo(path: "file3.swift", workdirStatus: .conflicted)
        ]
        
        let summary = StatusGrouping.createSummary(from: files)
        
        #expect(summary.totalFileCount == 3)
        #expect(summary.groups.count == 3)
    }
    
    // MARK: - StatusSummary Tests
    
    @Test
    func statusSummaryInitialization() async throws {
        let groups = [
            StatusGroup(status: .modified, files: [
                createTestFileStatusInfo(path: "file1.swift", size: 1024)
            ]),
            StatusGroup(status: .added, files: [
                createTestFileStatusInfo(path: "file2.swift", size: 2048)
            ])
        ]
        
        let summary = StatusSummary(groups: groups)
        
        #expect(summary.groups.count == 2)
        #expect(summary.totalFileCount == 2)
        #expect(summary.totalSize == 3072)
    }
    
    @Test
    func statusSummaryConflictCount() async throws {
        let groups = [
            StatusGroup(status: .conflicted, files: [
                createTestFileStatusInfo(path: "file1.swift", workdirStatus: .conflicted),
                createTestFileStatusInfo(path: "file2.swift", workdirStatus: .conflicted)
            ]),
            StatusGroup(status: .modified, files: [
                createTestFileStatusInfo(path: "file3.swift", workdirStatus: .modified)
            ])
        ]
        
        let summary = StatusSummary(groups: groups)
        
        #expect(summary.conflictCount == 2)
        #expect(summary.hasConflicts == true)
    }
    
    @Test
    func statusSummaryUntrackedCount() async throws {
        let groups = [
            StatusGroup(status: .untracked, files: [
                createTestFileStatusInfo(path: "file1.swift", workdirStatus: .untracked, isUntracked: true),
                createTestFileStatusInfo(path: "file2.swift", workdirStatus: .untracked, isUntracked: true)
            ])
        ]
        
        let summary = StatusSummary(groups: groups)
        
        #expect(summary.untrackedCount == 2)
    }
    
    @Test
    func statusSummaryModifiedCount() async throws {
        let groups = [
            StatusGroup(status: .modified, files: [
                createTestFileStatusInfo(path: "file1.swift", workdirStatus: .modified),
                createTestFileStatusInfo(path: "file2.swift", workdirStatus: .modified),
                createTestFileStatusInfo(path: "file3.swift", workdirStatus: .modified)
            ])
        ]
        
        let summary = StatusSummary(groups: groups)
        
        #expect(summary.modifiedCount == 3)
    }
    
    @Test
    func statusSummaryStagedCount() async throws {
        let groups = [
            StatusGroup(status: .modified, files: [
                createTestFileStatusInfo(path: "file1.swift", isStaged: true),
                createTestFileStatusInfo(path: "file2.swift", isStaged: false)
            ]),
            StatusGroup(status: .added, files: [
                createTestFileStatusInfo(path: "file3.swift", isStaged: true)
            ])
        ]
        
        let summary = StatusSummary(groups: groups)
        
        #expect(summary.stagedCount == 2)
        #expect(summary.hasChangesToCommit == true)
    }
    
    @Test
    func statusSummaryCleanState() async throws {
        let emptyGroups: [StatusGroup] = []
        let emptySummary = StatusSummary(groups: emptyGroups)
        #expect(emptySummary.isClean == true)
        
        let unmodifiedGroups = [
            StatusGroup(status: .unmodified, files: [
                createTestFileStatusInfo(path: "file1.swift", workdirStatus: .unmodified)
            ])
        ]
        let unmodifiedSummary = StatusSummary(groups: unmodifiedGroups)
        #expect(unmodifiedSummary.isClean == true)
        
        let modifiedGroups = [
            StatusGroup(status: .modified, files: [
                createTestFileStatusInfo(path: "file1.swift", workdirStatus: .modified)
            ])
        ]
        let modifiedSummary = StatusSummary(groups: modifiedGroups)
        #expect(modifiedSummary.isClean == false)
    }
    
    @Test
    func statusSummaryStatusDescription() async throws {
        let cleanSummary = StatusSummary(groups: [])
        #expect(cleanSummary.statusDescription == "Working directory clean")
        
        let groups = [
            StatusGroup(status: .conflicted, files: [
                createTestFileStatusInfo(path: "file1.swift", workdirStatus: .conflicted)
            ]),
            StatusGroup(status: .modified, files: [
                createTestFileStatusInfo(path: "file2.swift", workdirStatus: .modified, isStaged: true)
            ]),
            StatusGroup(status: .untracked, files: [
                createTestFileStatusInfo(path: "file3.swift", workdirStatus: .untracked, isUntracked: true)
            ])
        ]
        
        let summary = StatusSummary(groups: groups)
        let description = summary.statusDescription
        
        #expect(description.contains("1 conflict"))
        #expect(description.contains("1 staged"))
        #expect(description.contains("1 untracked"))
    }
    
    @Test
    func statusSummaryPluralHandling() async throws {
        let groups = [
            StatusGroup(status: .conflicted, files: [
                createTestFileStatusInfo(path: "file1.swift", workdirStatus: .conflicted),
                createTestFileStatusInfo(path: "file2.swift", workdirStatus: .conflicted)
            ])
        ]
        
        let summary = StatusSummary(groups: groups)
        let description = summary.statusDescription
        
        #expect(description.contains("2 conflicts"))
    }
}