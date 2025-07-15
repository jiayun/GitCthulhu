//
// FileListView.swift
// GitCthulhu
//
// Created by GitCthulhu Team on 2025-07-15.
//

import GitCore
import SwiftUI
import UIKit

struct FileListView: View {
    @StateObject private var viewModel: FileListViewModel
    @State private var searchText = ""
    @State private var showingContextMenu = false
    @State private var contextMenuFile: FileStatusInfo?
    
    init(repository: GitRepository) {
        _viewModel = StateObject(wrappedValue: FileListViewModel(repository: repository))
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header section
            headerSection
            
            Divider()
            
            // Content section
            if viewModel.isLoading {
                loadingView
            } else if viewModel.files.isEmpty {
                emptyStateView
            } else {
                fileListContent
            }
        }
        .background(Color(NSColor.controlBackgroundColor))
        .onAppear {
            Task {
                await viewModel.loadFileStatus()
            }
        }
        .sheet(isPresented: $showingContextMenu) {
            if let file = contextMenuFile {
                contextMenuSheet(for: file)
            }
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 8) {
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField("Search files...", text: $viewModel.searchText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                Button(action: {
                    Task {
                        await viewModel.refresh()
                    }
                }) {
                    Image(systemName: "arrow.clockwise")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            // Controls
            HStack {
                // Grouping toggle
                Button(action: {
                    viewModel.isGroupingEnabled.toggle()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: viewModel.isGroupingEnabled ? "checkmark.square.fill" : "square")
                        Text("Group by status")
                    }
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                }
                .buttonStyle(PlainButtonStyle())
                
                // Ignored files toggle
                Button(action: {
                    viewModel.showIgnoredFiles.toggle()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: viewModel.showIgnoredFiles ? "checkmark.square.fill" : "square")
                        Text("Show ignored")
                    }
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                }
                .buttonStyle(PlainButtonStyle())
                
                Spacer()
                
                // Selection controls
                if !viewModel.selectedFiles.isEmpty {
                    HStack(spacing: 8) {
                        Text("\(viewModel.selectedFiles.count) selected")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                        
                        Button("Stage") {
                            Task {
                                await viewModel.stageFiles(Array(viewModel.selectedFiles))
                            }
                        }
                        .font(.system(size: 12))
                        .buttonStyle(PlainButtonStyle())
                        
                        Button("Clear") {
                            viewModel.deselectAllFiles()
                        }
                        .font(.system(size: 12))
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }
    
    private var loadingView: some View {
        VStack(spacing: 8) {
            ProgressView()
                .scaleEffect(0.8)
            Text("Loading files...")
                .font(.system(size: 12))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 8) {
            Image(systemName: "folder")
                .font(.system(size: 40))
                .foregroundColor(.secondary)
            
            Text("No files to display")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text("All files are up to date")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var fileListContent: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                if viewModel.isGroupingEnabled {
                    groupedFileList
                } else {
                    ungroupedFileList
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
        }
    }
    
    private var ungroupedFileList: some View {
        ForEach(viewModel.files) { fileInfo in
            FileItemView(
                fileInfo: fileInfo,
                isSelected: viewModel.isFileSelected(fileInfo.filePath),
                onSelection: { filePath in
                    viewModel.toggleFileSelection(filePath)
                },
                onContextMenu: { file in
                    contextMenuFile = file
                    showingContextMenu = true
                }
            )
            .padding(.vertical, 1)
        }
    }
    
    private var groupedFileList: some View {
        ForEach(FileGroupCategory.allCases.sorted(by: { $0.priority < $1.priority }), id: \.self) { category in
            if let files = viewModel.groupedFiles[category], !files.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    // Group header
                    HStack {
                        FileGroupIndicator(category: category, count: files.count, size: 14)
                        
                        Spacer()
                        
                        // Group action buttons
                        HStack(spacing: 4) {
                            if category == .staged {
                                Button("Unstage All") {
                                    Task {
                                        await viewModel.unstageFiles(files.map { $0.filePath })
                                    }
                                }
                                .font(.system(size: 10))
                                .buttonStyle(PlainButtonStyle())
                            } else if category == .modified || category == .untracked {
                                Button("Stage All") {
                                    Task {
                                        await viewModel.stageFiles(files.map { $0.filePath })
                                    }
                                }
                                .font(.system(size: 10))
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.secondary.opacity(0.05))
                    )
                    
                    // Group files
                    ForEach(files) { fileInfo in
                        FileItemView(
                            fileInfo: fileInfo,
                            isSelected: viewModel.isFileSelected(fileInfo.filePath),
                            onSelection: { filePath in
                                viewModel.toggleFileSelection(filePath)
                            },
                            onContextMenu: { file in
                                contextMenuFile = file
                                showingContextMenu = true
                            }
                        )
                        .padding(.vertical, 1)
                        .padding(.leading, 16)
                    }
                }
                .padding(.bottom, 8)
            }
        }
    }
    
    private func contextMenuSheet(for file: FileStatusInfo) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // File info header
            HStack {
                StatusIndicator(
                    status: file.status,
                    isStaged: file.isStaged,
                    isUnstaged: file.isUnstaged
                )
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(file.fileName)
                        .font(.headline)
                    Text(file.filePath)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button("✕") {
                    showingContextMenu = false
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.bottom, 8)
            
            // Actions
            VStack(alignment: .leading, spacing: 8) {
                if !file.isStaged {
                    Button("Stage File") {
                        Task {
                            await viewModel.stageFiles([file.filePath])
                            showingContextMenu = false
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                if file.isStaged {
                    Button("Unstage File") {
                        Task {
                            await viewModel.unstageFiles([file.filePath])
                            showingContextMenu = false
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                if file.status == .modified {
                    Button("Discard Changes") {
                        Task {
                            await viewModel.discardChanges([file.filePath])
                            showingContextMenu = false
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                    .foregroundColor(.red)
                }
                
                Divider()
                
                Button("Show in Finder") {
                    let fileURL = URL(fileURLWithPath: file.filePath)
                    NSWorkspace.shared.selectFile(fileURL.path, inFileViewerRootedAtPath: "")
                    showingContextMenu = false
                }
                .buttonStyle(PlainButtonStyle())
                
                Button("Copy Path") {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(file.filePath, forType: .string)
                    showingContextMenu = false
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            Spacer()
        }
        .padding()
        .frame(width: 300, height: 200)
    }
}

#Preview("File List View") {
    FileListView(repository: GitRepository(url: URL(fileURLWithPath: "/tmp")))
        .frame(width: 400, height: 600)
}