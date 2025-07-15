//
// StatusGroup.swift
// GitCthulhu
//
// Created by GitCthulhu Team on 2025-07-15.
//

import Foundation

/// Represents a group of files with the same status
public struct StatusGroup: Identifiable, Hashable {
    public let id = UUID()
    public let status: GitFileStatus
    public let files: [FileStatusInfo]
    
    public init(status: GitFileStatus, files: [FileStatusInfo]) {
        self.status = status
        self.files = files.sorted()
    }
    
    /// The number of files in this group
    public var count: Int {
        files.count
    }
    
    /// Whether this group is empty
    public var isEmpty: Bool {
        files.isEmpty
    }
    
    /// A display name for the group
    public var displayName: String {
        let countText = count == 1 ? "1 file" : "\(count) files"
        return "\(status.displayName) (\(countText))"
    }
    
    /// The total size of all files in the group
    public var totalSize: Int64 {
        files.reduce(0) { $0 + $1.size }
    }
    
    /// A human-readable total size string
    public var totalSizeDescription: String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: totalSize)
    }
    
    /// Whether all files in this group are staged
    public var allStaged: Bool {
        !files.isEmpty && files.allSatisfy(\.isStaged)
    }
    
    /// Whether any files in this group are staged
    public var anyStaged: Bool {
        files.contains(where: \.isStaged)
    }
    
    /// Whether all files in this group have stageable changes
    public var allHaveStagableChanges: Bool {
        !files.isEmpty && files.allSatisfy(\.hasStagableChanges)
    }
    
    /// Whether any files in this group have conflicts
    public var anyHaveConflicts: Bool {
        files.contains(where: \.hasConflicts)
    }
}

// MARK: - Comparable

extension StatusGroup: Comparable {
    public static func < (lhs: StatusGroup, rhs: StatusGroup) -> Bool {
        lhs.status < rhs.status
    }
}

// MARK: - Status Grouping Utilities

public struct StatusGrouping {
    /// Groups files by their effective status
    public static func groupByStatus(_ files: [FileStatusInfo]) -> [StatusGroup] {
        let grouped = Dictionary(grouping: files, by: \.effectiveStatus)
        
        return grouped.compactMap { (status, files) in
            guard !files.isEmpty else { return nil }
            return StatusGroup(status: status, files: files)
        }.sorted()
    }
    
    /// Groups files by their staging status
    public static func groupByStaging(_ files: [FileStatusInfo]) -> (staged: [FileStatusInfo], unstaged: [FileStatusInfo]) {
        let grouped = Dictionary(grouping: files, by: \.isStaged)
        return (
            staged: grouped[true] ?? [],
            unstaged: grouped[false] ?? []
        )
    }
    
    /// Groups files by their directory
    public static func groupByDirectory(_ files: [FileStatusInfo]) -> [String: [FileStatusInfo]] {
        Dictionary(grouping: files, by: \.directoryPath)
    }
    
    /// Creates a summary of all status groups
    public static func createSummary(from files: [FileStatusInfo]) -> StatusSummary {
        let groups = groupByStatus(files)
        return StatusSummary(groups: groups)
    }
}

// MARK: - Status Summary

/// Provides a comprehensive summary of file statuses
public struct StatusSummary: Identifiable, Hashable {
    public let id = UUID()
    public let groups: [StatusGroup]
    
    public init(groups: [StatusGroup]) {
        self.groups = groups.sorted()
    }
    
    /// Total number of files across all groups
    public var totalFileCount: Int {
        groups.reduce(0) { $0 + $1.count }
    }
    
    /// Total size of all files across all groups
    public var totalSize: Int64 {
        groups.reduce(0) { $0 + $1.totalSize }
    }
    
    /// A human-readable total size string
    public var totalSizeDescription: String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: totalSize)
    }
    
    /// Number of files with conflicts
    public var conflictCount: Int {
        groups.first(where: { $0.status == .conflicted })?.count ?? 0
    }
    
    /// Number of untracked files
    public var untrackedCount: Int {
        groups.first(where: { $0.status == .untracked })?.count ?? 0
    }
    
    /// Number of modified files
    public var modifiedCount: Int {
        groups.first(where: { $0.status == .modified })?.count ?? 0
    }
    
    /// Number of staged files
    public var stagedCount: Int {
        groups.reduce(0) { total, group in
            total + group.files.filter(\.isStaged).count
        }
    }
    
    /// Whether there are any changes that can be committed
    public var hasChangesToCommit: Bool {
        stagedCount > 0
    }
    
    /// Whether there are any conflicts that need resolution
    public var hasConflicts: Bool {
        conflictCount > 0
    }
    
    /// Whether the working directory is clean
    public var isClean: Bool {
        totalFileCount == 0 || groups.allSatisfy { $0.status == .unmodified }
    }
    
    /// A brief description of the current state
    public var statusDescription: String {
        if isClean {
            return "Working directory clean"
        }
        
        var components: [String] = []
        
        if hasConflicts {
            components.append("\(conflictCount) conflict\(conflictCount == 1 ? "" : "s")")
        }
        
        if stagedCount > 0 {
            components.append("\(stagedCount) staged")
        }
        
        if modifiedCount > 0 {
            components.append("\(modifiedCount) modified")
        }
        
        if untrackedCount > 0 {
            components.append("\(untrackedCount) untracked")
        }
        
        return components.joined(separator: ", ")
    }
}