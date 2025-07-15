//
// FileListViewModel.swift
// GitCthulhu
//
// Created by GitCthulhu Team on 2025-07-15.
//

import Combine
import Foundation
import GitCore

@MainActor
final class FileListViewModel: ViewModelBase {
    @Published var files: [FileStatusInfo] = []
    @Published var groupedFiles: [FileGroupCategory: [FileStatusInfo]] = [:]
    @Published var selectedFiles: Set<String> = []
    @Published var isGroupingEnabled: Bool = true
    @Published var showIgnoredFiles: Bool = false
    @Published var searchText: String = ""
    
    private let repository: GitRepository
    private let gitCommandExecutor: GitCommandExecutor
    private var refreshTimer: Timer?
    
    init(repository: GitRepository) {
        self.repository = repository
        self.gitCommandExecutor = GitCommandExecutor(repositoryURL: repository.url)
        super.init()
        setupBindings()
        Task {
            await loadFileStatus()
        }
    }
    
    deinit {
        refreshTimer?.invalidate()
    }
    
    private func setupBindings() {
        // Auto-refresh when search text changes
        $searchText
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateFilteredFiles()
            }
            .store(in: &cancellables)
        
        // Update grouping when grouping preference changes
        $isGroupingEnabled
            .sink { [weak self] _ in
                self?.updateGroupedFiles()
            }
            .store(in: &cancellables)
        
        // Update filtered files when show ignored preference changes
        $showIgnoredFiles
            .sink { [weak self] _ in
                self?.updateFilteredFiles()
            }
            .store(in: &cancellables)
        
        // Start auto-refresh timer
        startAutoRefresh()
    }
    
    private func startAutoRefresh() {
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            Task {
                await self?.loadFileStatus()
            }
        }
    }
    
    func loadFileStatus() async {
        do {
            try await runAsync {
                let statusOutput = try await gitCommandExecutor.execute(["status", "--porcelain=v1"])
                let fileInfos = parseGitStatusOutput(statusOutput)
                
                await MainActor.run {
                    self.files = fileInfos
                    self.updateFilteredFiles()
                    self.updateGroupedFiles()
                }
            }
        } catch {
            handleError(error)
        }
    }
    
    private func parseGitStatusOutput(_ output: String) -> [FileStatusInfo] {
        let lines = output.components(separatedBy: .newlines)
            .filter { !$0.isEmpty }
        
        var fileInfos: [FileStatusInfo] = []
        
        for line in lines {
            guard line.count >= 3 else { continue }
            
            let stagedChar = line[line.startIndex]
            let unstagedChar = line[line.index(line.startIndex, offsetBy: 1)]
            let filePath = String(line[line.index(line.startIndex, offsetBy: 3)...])
            
            let fileName = URL(fileURLWithPath: filePath).lastPathComponent
            let status = determineFileStatus(staged: stagedChar, unstaged: unstagedChar)
            let isStaged = stagedChar != " " && stagedChar != "?"
            let isUnstaged = unstagedChar != " "
            
            // Get file size and modification date
            let fileURL = repository.url.appendingPathComponent(filePath)
            let fileSize = try? fileURL.resourceValues(forKeys: [.fileSizeKey]).fileSize
            let modificationDate = try? fileURL.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate
            
            let fileInfo = FileStatusInfo(
                fileName: fileName,
                filePath: filePath,
                status: status,
                isStaged: isStaged,
                isUnstaged: isUnstaged,
                fileSize: fileSize.map { Int64($0) },
                modificationDate: modificationDate
            )
            
            fileInfos.append(fileInfo)
        }
        
        return fileInfos.sorted { $0.fileName.localizedCaseInsensitiveCompare($1.fileName) == .orderedAscending }
    }
    
    private func determineFileStatus(staged: Character, unstaged: Character) -> GitFileStatus {
        // Handle staged status first
        switch staged {
        case "A":
            return .added
        case "M":
            return .modified
        case "D":
            return .deleted
        case "R":
            return .renamed
        case "C":
            return .copied
        case "U":
            return .unmerged
        default:
            break
        }
        
        // Handle unstaged status
        switch unstaged {
        case "M":
            return .modified
        case "D":
            return .deleted
        case "U":
            return .unmerged
        case "?":
            return .untracked
        case "!":
            return .ignored
        default:
            return .modified
        }
    }
    
    private func updateFilteredFiles() {
        let filtered = files.filter { fileInfo in
            // Filter by ignored files preference
            if !showIgnoredFiles && fileInfo.status == .ignored {
                return false
            }
            
            // Filter by search text
            if !searchText.isEmpty {
                return fileInfo.fileName.localizedCaseInsensitiveContains(searchText) ||
                       fileInfo.filePath.localizedCaseInsensitiveContains(searchText)
            }
            
            return true
        }
        
        files = filtered
    }
    
    private func updateGroupedFiles() {
        guard isGroupingEnabled else {
            groupedFiles = [:]
            return
        }
        
        let grouped = Dictionary(grouping: files) { $0.groupCategory }
        let sortedGroups = grouped.mapValues { files in
            files.sorted { $0.fileName.localizedCaseInsensitiveCompare($1.fileName) == .orderedAscending }
        }
        
        groupedFiles = sortedGroups
    }
    
    // MARK: - File Selection
    
    func selectFile(_ filePath: String) {
        selectedFiles.insert(filePath)
    }
    
    func deselectFile(_ filePath: String) {
        selectedFiles.remove(filePath)
    }
    
    func toggleFileSelection(_ filePath: String) {
        if selectedFiles.contains(filePath) {
            deselectFile(filePath)
        } else {
            selectFile(filePath)
        }
    }
    
    func selectAllFiles() {
        selectedFiles = Set(files.map { $0.filePath })
    }
    
    func deselectAllFiles() {
        selectedFiles.removeAll()
    }
    
    func isFileSelected(_ filePath: String) -> Bool {
        selectedFiles.contains(filePath)
    }
    
    // MARK: - Git Operations
    
    func stageFiles(_ filePaths: [String]) async {
        do {
            try await runAsync {
                for filePath in filePaths {
                    try await gitCommandExecutor.execute(["add", filePath])
                }
                await loadFileStatus()
            }
        } catch {
            handleError(error)
        }
    }
    
    func unstageFiles(_ filePaths: [String]) async {
        do {
            try await runAsync {
                for filePath in filePaths {
                    try await gitCommandExecutor.execute(["reset", "HEAD", filePath])
                }
                await loadFileStatus()
            }
        } catch {
            handleError(error)
        }
    }
    
    func discardChanges(_ filePaths: [String]) async {
        do {
            try await runAsync {
                for filePath in filePaths {
                    try await gitCommandExecutor.execute(["checkout", "HEAD", filePath])
                }
                await loadFileStatus()
            }
        } catch {
            handleError(error)
        }
    }
    
    func refresh() async {
        await loadFileStatus()
    }
}