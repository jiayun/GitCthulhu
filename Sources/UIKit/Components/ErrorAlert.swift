import SwiftUI
import GitCore

public struct ErrorAlert: View {
    let error: GitError
    let onRetry: (() -> Void)?
    let onDismiss: () -> Void
    
    public init(error: GitError, onRetry: (() -> Void)? = nil, onDismiss: @escaping () -> Void) {
        self.error = error
        self.onRetry = onRetry
        self.onDismiss = onDismiss
    }
    
    public var body: some View {
        VStack(spacing: 16) {
            // Error Icon
            Image(systemName: errorIcon)
                .font(.system(size: 48))
                .foregroundColor(.red)
            
            // Error Title
            Text(errorTitle)
                .font(.title2)
                .fontWeight(.semibold)
            
            // Error Description
            Text(error.localizedDescription)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            // Action Buttons
            HStack(spacing: 12) {
                Button("Dismiss") {
                    onDismiss()
                }
                .buttonStyle(.bordered)
                
                if let onRetry = onRetry {
                    Button("Retry") {
                        onRetry()
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
        .padding()
        .background(Color(NSColor.windowBackgroundColor))
        .cornerRadius(12)
        .shadow(radius: 8)
    }
    
    private var errorIcon: String {
        switch error {
        case .failedToOpenRepository:
            return "folder.badge.questionmark"
        case .failedToInitializeRepository:
            return "plus.square.dashed"
        case .invalidRepositoryPath:
            return "exclamationmark.triangle"
        case .libgit2Error:
            return "terminal"
        case .fileNotFound:
            return "doc.badge.exclamationmark"
        case .permissionDenied:
            return "lock.shield"
        case .networkError:
            return "wifi.exclamationmark"
        case .unknown:
            return "questionmark.circle"
        }
    }
    
    private var errorTitle: String {
        switch error {
        case .failedToOpenRepository:
            return "Failed to Open Repository"
        case .failedToInitializeRepository:
            return "Failed to Initialize Repository"
        case .invalidRepositoryPath:
            return "Invalid Repository Path"
        case .libgit2Error:
            return "Git Operation Failed"
        case .fileNotFound:
            return "File Not Found"
        case .permissionDenied:
            return "Permission Denied"
        case .networkError:
            return "Network Error"
        case .unknown:
            return "Unknown Error"
        }
    }
}

public struct ErrorBanner: View {
    let error: GitError
    let onDismiss: () -> Void
    
    public init(error: GitError, onDismiss: @escaping () -> Void) {
        self.error = error
        self.onDismiss = onDismiss
    }
    
    public var body: some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.red)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Error")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(error.localizedDescription)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button(action: onDismiss) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding()
        .background(Color.red.opacity(0.1))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.red.opacity(0.3), lineWidth: 1)
        )
    }
}

#Preview("Error Alert") {
    ErrorAlert(
        error: .failedToOpenRepository("The selected folder is not a valid Git repository."),
        onRetry: { print("Retry") },
        onDismiss: { print("Dismiss") }
    )
    .frame(width: 400, height: 300)
}

#Preview("Error Banner") {
    ErrorBanner(
        error: .permissionDenied,
        onDismiss: { print("Dismiss") }
    )
    .padding()
}