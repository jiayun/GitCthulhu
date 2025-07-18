//
// IntegratedRepositoryStagingAreaTab.swift
// GitCthulhu
//
// Created by GitCthulhu Team on 2025-07-18.
//

import GitCore
import SwiftUI

struct IntegratedRepositoryStagingAreaTab: View {
    @Binding var repository: GitRepository?
    @ObservedObject var stagingViewModel: StagingViewModel

    var body: some View {
        if let repository {
            StagingAreaView(
                repository: repository,
                selectedFiles: .constant(Set<String>()),
                onStageFiles: { _ in
                    Task {
                        await stagingViewModel.stageSelectedFiles(Set(filePaths))
                        // Refresh repository status after staging
                        await repository.refreshStatus()
                    }
                },
                onUnstageFiles: { _ in
                    Task {
                        await stagingViewModel.unstageSelectedFiles(Set(filePaths))
                        // Refresh repository status after unstaging
                        await repository.refreshStatus()
                    }
                },
                onStageAll: { _ in
                    Task {
                        await stagingViewModel.stageAllFiles()
                        // Refresh repository status after staging all
                        await repository.refreshStatus()
                    }
                },
                onUnstageAll: { _ in
                    Task {
                        await stagingViewModel.unstageAllFiles()
                        // Refresh repository status after unstaging all
                        await repository.refreshStatus()
                    }
                }
            )
            .frame(minWidth: 300, idealWidth: 400)
            .id(repository.id) // Force refresh when repository changes
        } else {
            VStack {
                Text("Staging Area")
                    .font(.headline)
                    .padding()

                Text("Loading...")
                    .foregroundColor(.secondary)
                    .padding()

                Spacer()
            }
            .frame(minWidth: 300, idealWidth: 400)
        }
    }
}
