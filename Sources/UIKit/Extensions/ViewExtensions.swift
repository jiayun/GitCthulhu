//
// ViewExtensions.swift
// GitCthulhu
//
// Created by GitCthulhu Team on 2025-07-16.
//

import SwiftUI

// MARK: - Conditional Draggable Extension

@available(macOS 13.0, *)
extension View {
    @ViewBuilder
    func conditionalDraggable<T: Transferable, V: View>(_ payload: T, @ViewBuilder preview: () -> V) -> some View {
        self.draggable(payload, preview: preview)
    }
}

@available(macOS, deprecated: 13.0)
extension View {
    @ViewBuilder
    func conditionalDraggable<T, V: View>(_ payload: T, @ViewBuilder preview: () -> V) -> some View {
        self
    }
}
