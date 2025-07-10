//
// GitBranch.swift
// GitCthulhu
//
// Created by GitCthulhu Team on 2025-07-11.
//

import Foundation

public struct GitBranch: Identifiable, Hashable {
    public let id = UUID()
    public let name: String
    public let shortName: String
    public let isRemote: Bool
    public let isCurrent: Bool

    public init(name: String, shortName: String, isRemote: Bool = false, isCurrent: Bool = false) {
        self.name = name
        self.shortName = shortName
        self.isRemote = isRemote
        self.isCurrent = isCurrent
    }

    public var displayName: String {
        isRemote ? "origin/\(shortName)" : shortName
    }
}
