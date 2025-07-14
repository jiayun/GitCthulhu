//
// BaseViewModel.swift
// GitCthulhu
//
// Created by GitCthulhu Team on 2025-07-14.
//

import Combine
import Foundation

protocol BaseViewModel: ObservableObject {
    var isLoading: Bool { get set }
    var errorMessage: String? { get set }
    var cancellables: Set<AnyCancellable> { get set }

    func handleError(_ error: Error)
    func clearError()
}

extension BaseViewModel {
    func handleError(_ error: Error) {
        Task { @MainActor in
            self.errorMessage = error.localizedDescription
            self.isLoading = false
        }
    }

    func clearError() {
        Task { @MainActor in
            self.errorMessage = nil
        }
    }
}

@MainActor
class ViewModelBase: ObservableObject {
    @Published var isLoading = false
    @Published var errorMessage: String?
    var cancellables = Set<AnyCancellable>()

    func handleError(_ error: Error) {
        errorMessage = error.localizedDescription
        isLoading = false
    }

    func clearError() {
        errorMessage = nil
    }

    func runAsync<T>(_ operation: @escaping () async throws -> T) async throws -> T {
        isLoading = true
        defer { isLoading = false }

        do {
            let result = try await operation()
            clearError()
            return result
        } catch {
            handleError(error)
            throw error
        }
    }
}
