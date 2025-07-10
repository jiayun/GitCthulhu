import SwiftUI

struct RepositorySidebar: View {
    var body: some View {
        List {
            Section("Repositories") {
                Text("No repositories yet")
                    .foregroundColor(.secondary)
            }
        }
        .navigationTitle("GitCthulhu")
        .frame(minWidth: 200)
    }
}

#Preview {
    RepositorySidebar()
}