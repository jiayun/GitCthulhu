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