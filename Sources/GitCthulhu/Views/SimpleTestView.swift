//
// SimpleTestView.swift
// GitCthulhu
//
// Created by GitCthulhu Team on 2025-07-11.
//

import SwiftUI
import Utilities

struct SimpleTestView: View {
    var body: some View {
        VStack(spacing: 30) {
            Text("GitCthulhu Test")
                .font(.largeTitle)
                .fontWeight(.bold)

            Image(systemName: "terminal")
                .font(.system(size: 60))
                .foregroundColor(.blue)

            Text("If you can see this, the app is working!")
                .font(.title2)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Button("Test Button") {
                Logger(category: "SimpleTestView").info("Test button tapped")
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white)
    }
}

#Preview {
    SimpleTestView()
}
