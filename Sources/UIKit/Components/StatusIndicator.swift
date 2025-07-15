//
// StatusIndicator.swift
// GitCthulhu
//
// Created by GitCthulhu Team on 2025-07-15.
//

import GitCore
import SwiftUI

public struct StatusIndicator: View {
    private let status: GitFileStatus
    private let isStaged: Bool
    private let isUnstaged: Bool
    private let size: CGFloat
    
    public init(
        status: GitFileStatus,
        isStaged: Bool = false,
        isUnstaged: Bool = false,
        size: CGFloat = 16
    ) {
        self.status = status
        self.isStaged = isStaged
        self.isUnstaged = isUnstaged
        self.size = size
    }
    
    public var body: some View {
        HStack(spacing: 2) {
            // Primary status indicator
            Image(systemName: status.symbolName)
                .font(.system(size: size))
                .foregroundColor(statusColor)
            
            // Staging status indicator
            if isStaged && isUnstaged {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: size * 0.7))
                    .foregroundColor(.green)
            } else if isStaged {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: size * 0.7))
                    .foregroundColor(.green)
            }
        }
    }
    
    private var statusColor: Color {
        switch status {
        case .untracked:
            return .orange
        case .modified:
            return .blue
        case .added:
            return .green
        case .deleted:
            return .red
        case .renamed:
            return .purple
        case .copied:
            return .purple
        case .unmerged:
            return .red
        case .ignored:
            return .gray
        }
    }
}

public struct FileGroupIndicator: View {
    private let category: FileGroupCategory
    private let count: Int
    private let size: CGFloat
    
    public init(category: FileGroupCategory, count: Int, size: CGFloat = 16) {
        self.category = category
        self.count = count
        self.size = size
    }
    
    public var body: some View {
        HStack(spacing: 4) {
            Image(systemName: category.symbolName)
                .font(.system(size: size))
                .foregroundColor(categoryColor)
            
            Text(category.displayName)
                .font(.system(size: size * 0.9, weight: .medium))
                .foregroundColor(.primary)
            
            if count > 0 {
                Text("(\(count))")
                    .font(.system(size: size * 0.8))
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private var categoryColor: Color {
        switch category {
        case .staged:
            return .green
        case .modified:
            return .blue
        case .untracked:
            return .orange
        case .deleted:
            return .red
        case .conflicted:
            return .red
        case .ignored:
            return .gray
        }
    }
}

#Preview("Status Indicators") {
    VStack(spacing: 10) {
        StatusIndicator(status: .untracked)
        StatusIndicator(status: .modified, isStaged: true)
        StatusIndicator(status: .added, isStaged: true)
        StatusIndicator(status: .modified, isStaged: true, isUnstaged: true)
        StatusIndicator(status: .deleted)
        StatusIndicator(status: .unmerged)
    }
    .padding()
}

#Preview("Group Indicators") {
    VStack(spacing: 10) {
        FileGroupIndicator(category: .staged, count: 3)
        FileGroupIndicator(category: .modified, count: 5)
        FileGroupIndicator(category: .untracked, count: 2)
        FileGroupIndicator(category: .deleted, count: 1)
        FileGroupIndicator(category: .conflicted, count: 1)
        FileGroupIndicator(category: .ignored, count: 0)
    }
    .padding()
}