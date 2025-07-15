//
// FileItemView.swift
// GitCthulhu
//
// Created by GitCthulhu Team on 2025-07-15.
//

import GitCore
import SwiftUI
import UIKit

struct FileItemView: View {
    let fileInfo: FileStatusInfo
    let isSelected: Bool
    let onSelection: (String) -> Void
    let onContextMenu: (FileStatusInfo) -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        HStack(spacing: 8) {
            // Selection indicator
            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 14))
                .foregroundColor(isSelected ? .accentColor : .secondary)
                .onTapGesture {
                    onSelection(fileInfo.filePath)
                }
            
            // File status indicator
            StatusIndicator(
                status: fileInfo.status,
                isStaged: fileInfo.isStaged,
                isUnstaged: fileInfo.isUnstaged,
                size: 14
            )
            
            // File icon
            Image(systemName: fileIcon)
                .font(.system(size: 14))
                .foregroundColor(.secondary)
            
            // File information
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(fileInfo.fileName)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    // File size
                    if let fileSize = fileInfo.formattedFileSize {
                        Text(fileSize)
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                }
                
                HStack {
                    // Relative path
                    if fileInfo.filePath != fileInfo.fileName {
                        Text(fileInfo.filePath)
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                    
                    Spacer()
                    
                    // Modification date
                    if let modificationDate = fileInfo.formattedModificationDate {
                        Text(modificationDate)
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
            
            // Status description
            Text(fileInfo.statusDescription)
                .font(.system(size: 11))
                .foregroundColor(.secondary)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.secondary.opacity(0.1))
                )
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(backgroundColorFill)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .stroke(borderColor, lineWidth: 1)
        )
        .onHover { hovering in
            isHovered = hovering
        }
        .onTapGesture {
            onSelection(fileInfo.filePath)
        }
        .contextMenu {
            contextMenuItems
        }
    }
    
    private var fileIcon: String {
        let pathExtension = URL(fileURLWithPath: fileInfo.fileName).pathExtension.lowercased()
        
        switch pathExtension {
        case "swift":
            return "doc.text"
        case "js", "ts", "jsx", "tsx":
            return "doc.text"
        case "py":
            return "doc.text"
        case "java", "kt":
            return "doc.text"
        case "cpp", "c", "h", "hpp":
            return "doc.text"
        case "rs":
            return "doc.text"
        case "go":
            return "doc.text"
        case "rb":
            return "doc.text"
        case "php":
            return "doc.text"
        case "html", "htm":
            return "doc.richtext"
        case "css", "scss", "sass":
            return "doc.richtext"
        case "json", "xml", "yaml", "yml":
            return "doc.plaintext"
        case "md", "markdown":
            return "doc.richtext"
        case "txt", "log":
            return "doc.plaintext"
        case "png", "jpg", "jpeg", "gif", "svg", "webp":
            return "photo"
        case "mp4", "mov", "avi", "mkv":
            return "video"
        case "mp3", "wav", "aac", "flac":
            return "music.note"
        case "zip", "tar", "gz", "rar", "7z":
            return "archivebox"
        case "pdf":
            return "doc.pdf"
        default:
            return "doc"
        }
    }
    
    private var backgroundColorFill: Color {
        if isSelected {
            return Color.accentColor.opacity(0.1)
        } else if isHovered {
            return Color.gray.opacity(0.05)
        } else {
            return Color.clear
        }
    }
    
    private var borderColor: Color {
        if isSelected {
            return Color.accentColor.opacity(0.3)
        } else {
            return Color.clear
        }
    }
    
    @ViewBuilder
    private var contextMenuItems: some View {
        Button("Stage File") {
            onContextMenu(fileInfo)
        }
        .disabled(fileInfo.isStaged)
        
        Button("Unstage File") {
            onContextMenu(fileInfo)
        }
        .disabled(!fileInfo.isStaged)
        
        if fileInfo.status == .modified {
            Button("Discard Changes") {
                onContextMenu(fileInfo)
            }
        }
        
        Divider()
        
        Button("Show in Finder") {
            onContextMenu(fileInfo)
        }
        
        Button("Copy Path") {
            onContextMenu(fileInfo)
        }
    }
}

#Preview("File Item View") {
    VStack(spacing: 4) {
        FileItemView(
            fileInfo: FileStatusInfo(
                fileName: "ContentView.swift",
                filePath: "Sources/GitCthulhu/Views/ContentView.swift",
                status: .modified,
                isStaged: false,
                isUnstaged: true,
                fileSize: 2048,
                modificationDate: Date()
            ),
            isSelected: false,
            onSelection: { _ in },
            onContextMenu: { _ in }
        )
        
        FileItemView(
            fileInfo: FileStatusInfo(
                fileName: "NewFile.swift",
                filePath: "Sources/GitCthulhu/Views/NewFile.swift",
                status: .added,
                isStaged: true,
                isUnstaged: false,
                fileSize: 1024,
                modificationDate: Date()
            ),
            isSelected: true,
            onSelection: { _ in },
            onContextMenu: { _ in }
        )
        
        FileItemView(
            fileInfo: FileStatusInfo(
                fileName: "test.png",
                filePath: "Assets/test.png",
                status: .untracked,
                isStaged: false,
                isUnstaged: true,
                fileSize: 512000,
                modificationDate: Date()
            ),
            isSelected: false,
            onSelection: { _ in },
            onContextMenu: { _ in }
        )
    }
    .padding()
    .frame(width: 400)
}