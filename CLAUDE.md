# GitCthulhu 專案開發指南

## 專案概述
GitCthulhu 是一個現代化的 macOS Git 客戶端，使用 SwiftUI 開發，提供直觀的使用者介面。

## 技術架構
- **語言**: Swift 5.9+
- **UI 框架**: SwiftUI + AppKit
- **最低系統需求**: macOS 12.0+
- **架構模式**: MVVM
- **Git 整合**: CLI-based (使用 Process 執行 git 命令)

## 專案結構
```
GitCthulhu/
├── Sources/
│   ├── GitCthulhu/      # 主應用程式
│   │   ├── App/         # App 入口點
│   │   └── Views/       # SwiftUI 視圖
│   ├── GitCore/         # Git 核心功能
│   ├── UIKit/           # 共用 UI 元件
│   └── Utilities/       # 工具函數
└── Tests/               # 測試檔案
```

## 重要注意事項

### GUI 應用程式設定
由於使用 Swift Package Manager，需要在 App 初始化時設定：
```swift
NSApplication.shared.setActivationPolicy(.regular)
NSApplication.shared.activate(ignoringOtherApps: true)
```
這確保執行檔以 GUI 模式運行，而非命令列工具。

### Git 整合策略
- 使用 Process 執行 git CLI 命令
- 所有 Git 操作都透過 GitCommandExecutor 類別
- 支援非同步操作 (async/await)

## 開發指令

### 建置與執行
```bash
# 建置專案
swift build

# 執行應用程式
swift run GitCthulhu
# 或使用輔助腳本
./run-app.sh

# 執行測試
swift test
```

### 清理建置
```bash
rm -rf .build
```

## 開發慣例

### 程式碼風格
- 使用 Swift 標準命名慣例
- 檔案名稱與型別名稱一致
- 保持函數簡潔，單一職責

### Git Commit 訊息
- 使用明確的動詞開頭 (Add, Fix, Update, Remove)
- 簡短描述變更內容
- 必要時加入詳細說明

### 測試要求
- 所有 GitCore 功能必須有單元測試
- UI 元件使用 Preview 進行視覺測試
- 保持測試覆蓋率 > 80%

## 常見問題

### 視窗不顯示
確認 GitCthulhuApp.swift 中有正確的 NSApplication 設定。

### Git 命令執行失敗
檢查 GitCommandExecutor 的錯誤處理，確認 git 路徑正確。

### 編譯錯誤
確保沒有重複的 @main 入口點或重複的型別定義。

## 待辦事項追蹤
使用 TodoWrite 工具追蹤開發任務，確保進度透明。

## 聯絡資訊
專案維護者：Jiayun