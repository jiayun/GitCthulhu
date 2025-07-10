import SwiftUI

struct WelcomeView: View {
    var body: some View {
        VStack(spacing: 30) {
            Spacer()

            // App Icon and Title
            VStack(spacing: 20) {
                Image(systemName: "terminal")
                    .font(.system(size: 80))
                    .foregroundColor(.blue)

                Text("GitCthulhu")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text("A Modern Git Client for macOS")
                    .font(.title2)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            Spacer()

            // Action Buttons
            VStack(spacing: 16) {
                Button("Open Repository") {
                    print("Open Repository tapped")
                    // TODO: Implement repository opening
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .frame(width: 200)

                Button("Clone Repository") {
                    print("Clone Repository tapped")
                    // TODO: Implement repository cloning
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                .frame(width: 200)
            }

            Spacer()

            // Status Text
            Text("Ready to explore your Git repositories")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.bottom, 20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(NSColor.windowBackgroundColor))
    }
}

#Preview {
    WelcomeView()
        .frame(width: 600, height: 400)
}
