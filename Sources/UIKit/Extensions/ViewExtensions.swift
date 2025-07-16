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
    func conditionalDraggable(_ payload: some Transferable, @ViewBuilder preview: () -> some View) -> some View {
        draggable(payload, preview: preview)
    }
}

@available(macOS, deprecated: 13.0)
extension View {
    @ViewBuilder
    func conditionalDraggable(_: some Any, @ViewBuilder _: () -> some View) -> some View {
        self
    }
}
