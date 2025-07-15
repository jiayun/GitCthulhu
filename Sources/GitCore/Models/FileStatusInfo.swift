//
// FileStatusInfo.swift
// GitCthulhu
//
// Created by GitCthulhu Team on 2025-07-15.
//

import Foundation

/// Represents comprehensive information about a file's status in a Git repository
public struct FileStatusInfo: Identifiable, Hashable {
    public let id = UUID()
    public let path: String
    public let workdirStatus: GitFileStatus
    public let indexStatus: GitFileStatus
    public let isStaged: Bool
    public let isUntracked: Bool
    public let isIgnored: Bool
    public let modificationTime: Date
    public let size: Int64
    
    public init(
        path: String,
        workdirStatus: GitFileStatus,
        indexStatus: GitFileStatus,
        isStaged: Bool,
        isUntracked: Bool,
        isIgnored: Bool,
        modificationTime: Date,
        size: Int64
    ) {
        self.path = path
        self.workdirStatus = workdirStatus
        self.indexStatus = indexStatus
        self.isStaged = isStaged
        self.isUntracked = isUntracked
        self.isIgnored = isIgnored
        self.modificationTime = modificationTime
        self.size = size
    }
    
    /// The effective status of the file, considering both working directory and index statuses
    public var effectiveStatus: GitFileStatus {
        if indexStatus != .unmodified {
            return indexStatus
        }
        return workdirStatus
    }
    
    /// Whether the file has changes that can be staged
    public var hasStagableChanges: Bool {
        !isStaged && workdirStatus != .unmodified && workdirStatus != .ignored
    }
    
    /// Whether the file has conflicts that need resolution
    public var hasConflicts: Bool {
        workdirStatus == .conflicted || indexStatus == .conflicted
    }
    
    /// The file's display name for UI purposes
    public var displayName: String {
        (path as NSString).lastPathComponent
    }
    
    /// The file's directory path
    public var directoryPath: String {
        (path as NSString).deletingLastPathComponent
    }
    
    /// A human-readable size string
    public var sizeDescription: String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: size)
    }
    
    /// A human-readable modification time string
    public var modificationTimeDescription: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: modificationTime)
    }
}

// MARK: - Comparable

extension FileStatusInfo: Comparable {
    public static func < (lhs: FileStatusInfo, rhs: FileStatusInfo) -> Bool {
        // First sort by status priority
        if lhs.effectiveStatus != rhs.effectiveStatus {
            return lhs.effectiveStatus < rhs.effectiveStatus
        }
        
        // Then by path alphabetically
        return lhs.path < rhs.path
    }
}

// MARK: - Status Change Tracking

extension FileStatusInfo {
    /// Represents a change in file status over time
    public struct StatusChange: Identifiable, Hashable {
        public let id = UUID()
        public let previousStatus: GitFileStatus
        public let newStatus: GitFileStatus
        public let timestamp: Date
        public let path: String
        
        public init(
            previousStatus: GitFileStatus,
            newStatus: GitFileStatus,
            timestamp: Date,
            path: String
        ) {
            self.previousStatus = previousStatus
            self.newStatus = newStatus
            self.timestamp = timestamp
            self.path = path
        }
        
        /// Whether this change represents a significant status change
        public var isSignificant: Bool {
            previousStatus != newStatus && 
            previousStatus != .unmodified && 
            newStatus != .unmodified
        }
        
        /// A human-readable description of the change
        public var description: String {
            "\(path): \(previousStatus.displayName) → \(newStatus.displayName)"
        }
    }
    
    /// Creates a status change from this file to another status
    public func createStatusChange(to newStatus: GitFileStatus) -> StatusChange {
        StatusChange(
            previousStatus: self.effectiveStatus,
            newStatus: newStatus,
            timestamp: Date(),
            path: self.path
        )
    }
}