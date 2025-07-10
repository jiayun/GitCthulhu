import SwiftUI

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
                print("Button tapped!")
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