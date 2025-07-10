//
// RepositoryDetailView.swift
// GitCthulhu
//
// Created by GitCthulhu Team on 2025-07-11.
//

import SwiftUI

struct RepositoryDetailView: View {
    var body: some View {
        VStack {
            Text("Repository Detail")
                .font(.title)

            Text("Repository content will be displayed here")
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    RepositoryDetailView()
}
