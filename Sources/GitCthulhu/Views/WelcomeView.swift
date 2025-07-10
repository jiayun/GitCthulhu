import SwiftUI

struct WelcomeView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "octopus")
                .font(.system(size: 80))
                .foregroundColor(.accentColor)
            
            Text("GitCthulhu")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("A Modern Git Client for macOS")
                .font(.title2)
                .foregroundColor(.secondary)
            
            VStack(spacing: 12) {
                Button("Open Repository") {
                    // TODO: Implement repository opening
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                
                Button("Clone Repository") {
                    // TODO: Implement repository cloning
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
            }
            .padding(.top)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(NSColor.windowBackgroundColor))
    }
}

#Preview {
    WelcomeView()
}