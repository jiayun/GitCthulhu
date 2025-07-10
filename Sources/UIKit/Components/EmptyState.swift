import SwiftUI

public struct EmptyState: View {
    let title: String
    let subtitle: String
    let systemImage: String
    
    public init(title: String, subtitle: String, systemImage: String) {
        self.title = title
        self.subtitle = subtitle
        self.systemImage = systemImage
    }
    
    public var body: some View {
        VStack(spacing: 16) {
            Image(systemName: systemImage)
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            VStack(spacing: 4) {
                Text(title)
                    .font(.headline)
                
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: 300)
    }
}

#Preview {
    EmptyState(
        title: "No Repositories",
        subtitle: "Open or clone a repository to get started",
        systemImage: "folder"
    )
}