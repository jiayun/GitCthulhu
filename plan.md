# Mac Git Client 專案開發計畫

## 🎯 專案概述

**產品名稱**：GitCthulhu
**開發方式**：全開源 + 贊助服務模式
**技術堆疊**：Swift + SwiftUI/AppKit 混合 + libgit2
**最低需求**：macOS 12+

---

## 📁 專案架構設計

```
GitCthulhu/
├── 📱 Sources/
│   ├── GitCthulhu/           # 主應用程式
│   │   ├── App/              # App lifecycle
│   │   ├── Views/            # SwiftUI Views
│   │   ├── ViewModels/       # MVVM ViewModels
│   │   └── Resources/        # Assets, Localizable
│   ├── GitCore/              # Git 核心功能模組
│   │   ├── Repository/       # Repository 管理
│   │   ├── Operations/       # Git 操作封裝
│   │   ├── Models/           # 資料模型
│   │   └── libgit2/          # libgit2 wrapper
│   ├── UIKit/                # 共用 UI 元件
│   │   ├── Components/       # 可重用元件
│   │   ├── Extensions/       # SwiftUI 擴展
│   │   └── AppKitBridge/     # AppKit 整合
│   └── Utilities/            # 工具函式
│       ├── FileManager/      # 檔案管理
│       ├── KeychainManager/  # 認證管理
│       └── Logger/           # 日誌系統
├── 🧪 Tests/
│   ├── GitCthulhuTests/      # 單元測試
│   ├── GitCoreTests/         # Git 核心測試
│   └── UITests/              # UI 測試
├── 📚 Documentation/
│   ├── API/                  # API 文檔
│   ├── UserGuide/            # 使用指南
│   └── Contributing/         # 貢獻指南
├── 🛠 Scripts/
│   ├── build.sh              # 建置腳本
│   ├── test.sh               # 測試腳本
│   └── release.sh            # 發布腳本
├── .github/
│   ├── workflows/            # GitHub Actions
│   ├── ISSUE_TEMPLATE/       # Issue 範本
│   └── PULL_REQUEST_TEMPLATE.md
├── Package.swift             # Swift Package Manager
├── README.md
├── LICENSE
└── CHANGELOG.md
```

---

## 🚀 Sprint 規劃（MVP 導向）

### **Sprint 0：專案初始化（Week 1-2）**

#### Epic: 專案基礎建設
**Goal**: 建立完整的開發環境和 CI/CD 流程

##### User Stories:
- [ ] **US-001**: 作為開發者，我需要建立 Xcode 專案結構
- [ ] **US-002**: 作為貢獻者，我需要清楚的專案文檔
- [ ] **US-003**: 作為維護者，我需要自動化建置流程

##### Tasks:
```
□ 建立 Xcode Workspace
□ 設置 Swift Package Manager
□ 配置 libgit2 依賴
□ 建立基本專案結構
□ 撰寫 README.md
□ 設置 GitHub Sponsors
□ 配置 GitHub Actions CI/CD
□ 建立 Issue/PR 範本
□ 設置代碼品質工具（SwiftLint, SwiftFormat）
□ 配置自動化測試環境
```

##### Definition of Done:
- [ ] 專案可在 Xcode 中正常編譯
- [ ] GitHub Actions 正常運行
- [ ] 代碼覆蓋率達 80%
- [ ] 所有依賴正確安裝

---

### **Sprint 1：核心架構（Week 3-4）**

#### Epic: Git 核心功能架構
**Goal**: 建立 Git 操作的基礎架構

##### User Stories:
- [ ] **US-004**: 作為使用者，我需要開啟本地 Git repository
- [ ] **US-005**: 作為開發者，我需要穩定的 Git 操作抽象層
- [ ] **US-006**: 作為使用者，我需要看到 repository 的基本資訊

##### Tasks:
```
□ 設計 GitRepository 協議
□ 實作 libgit2 wrapper
□ 建立 Repository 管理器
□ 實作檔案系統監控
□ 建立錯誤處理機制
□ 設計 MVVM 架構
□ 建立基本的 SwiftUI 視圖
□ 實作 Repository 選擇功能
□ 添加單元測試
□ 建立日誌系統
```

##### Definition of Done:
- [ ] 可以成功讀取 Git repository
- [ ] 錯誤處理完整
- [ ] 單元測試覆蓋率 > 85%
- [ ] 記憶體無洩漏

---

### **Sprint 2：檔案狀態管理（Week 5-6）**
**⚠️ 已於 2025-07-15 重置，採用新的階段式開發流程**

#### Epic: 工作目錄狀態檢視 (#18)
**Goal**: 顯示和管理 Git 工作目錄狀態

##### User Stories:
- [ ] **US-007** (#19): 作為使用者，我需要看到所有檔案的 Git 狀態
- [ ] **US-008** (#20): 作為使用者，我需要 stage/unstage 檔案
- [ ] **US-009** (#21): 作為使用者，我需要查看檔案差異

##### 新的階段式 Tasks 執行計畫:

**Phase 1 - 基礎設施**:
```
☐ #32 實作 Git Status 檢查 (進行中)
☐ 建立檔案狀態模型 (等待 #32 完成)
```

**Phase 2 - 核心功能**:
```
☐ 設計檔案列表 UI (依賴 Phase 1)
☐ 實作 Staging 操作 (依賴 Phase 1)
☐ 建立 Diff 檢視器 (相對獨立)
```

**Phase 3 - 增強功能**:
```
☐ 實作檔案篩選功能 (依賴 Phase 2)
☐ 添加快捷鍵支援 (依賴 Phase 2)
☐ 實作即時狀態更新 (依賴 Phase 1)
☐ 建立檔案圖示系統 (依賴 Phase 2)
```

**Phase 4 - 整合**:
```
☐ 添加整合測試 (依賴所有 Phase)
```

##### Definition of Done:
- [ ] 檔案狀態即時更新
- [ ] Stage/Unstage 操作正常
- [ ] Diff 顯示正確
- [ ] UI 響應流暢
- [ ] 所有階段按依賴順序完成

##### 重要文件:
- `SPRINT_2_RESET.md` - 重置記錄和原因
- `SPRINT_2_WORKFLOW.md` - 新工作流程規範

---

### **Sprint 3：Commit 功能（Week 7-8）**

#### Epic: 提交變更功能
**Goal**: 實作完整的 commit 功能

##### User Stories:
- [ ] **US-010**: 作為使用者，我需要提交變更
- [ ] **US-011**: 作為使用者，我需要撰寫 commit message
- [ ] **US-012**: 作為使用者，我需要查看 commit 歷史

##### Tasks:
```
□ 實作 Commit 操作
□ 建立 Commit Message 編輯器
□ 實作 Commit 驗證
□ 建立 Commit 歷史檢視
□ 實作 Commit 詳細資訊
□ 添加 GPG 簽名支援
□ 實作 Amend Commit
□ 建立 Commit 範本
□ 添加 Commit 統計
□ 實作錯誤回復機制
```

##### Definition of Done:
- [ ] Commit 操作穩定可靠
- [ ] Message 驗證正確
- [ ] 歷史顯示完整
- [ ] 支援 GPG 簽名

---

### **Sprint 4：分支管理（Week 9-10）**

#### Epic: 分支操作功能
**Goal**: 實作分支的建立、切換、合併功能

##### User Stories:
- [ ] **US-013**: 作為使用者，我需要檢視所有分支
- [ ] **US-014**: 作為使用者，我需要建立和切換分支
- [ ] **US-015**: 作為使用者，我需要合併分支

##### Tasks:
```
□ 實作分支列表檢視
□ 建立分支操作介面
□ 實作分支建立功能
□ 實作分支切換功能
□ 建立分支合併介面
□ 實作 Fast-forward 合併
□ 實作 Three-way 合併
□ 建立分支視覺化
□ 添加分支保護機制
□ 實作分支清理功能
```

##### Definition of Done:
- [ ] 分支操作無誤
- [ ] 合併衝突正確處理
- [ ] 視覺化清晰易懂
- [ ] 資料一致性保證

---

### **Sprint 5：Remote 操作（Week 11-12）**

#### Epic: 遠端 Repository 整合
**Goal**: 實作 push、pull、fetch 等遠端操作

##### User Stories:
- [ ] **US-016**: 作為使用者，我需要推送變更到遠端
- [ ] **US-017**: 作為使用者，我需要從遠端拉取變更
- [ ] **US-018**: 作為使用者，我需要管理多個 remote

##### Tasks:
```
□ 實作 Remote 管理
□ 建立認證機制
□ 實作 Push 操作
□ 實作 Pull 操作
□ 實作 Fetch 操作
□ 建立衝突解決介面
□ 實作進度顯示
□ 添加 SSH Key 管理
□ 實作 Remote 分支追蹤
□ 建立網路錯誤處理
```

##### Definition of Done:
- [ ] Remote 操作穩定
- [ ] 認證機制完善
- [ ] 網路錯誤處理完整
- [ ] 進度回饋即時

---

### **Sprint 6：MVP 完善（Week 13-14）**

#### Epic: MVP 功能整合與優化
**Goal**: 完善 MVP 功能，準備首次發布

##### User Stories:
- [ ] **US-019**: 作為使用者，我需要穩定可用的 Git GUI
- [ ] **US-020**: 作為新用戶，我需要清楚的使用指引
- [ ] **US-021**: 作為貢獻者，我需要完整的開發文檔

##### Tasks:
```
□ 整合所有功能模組
□ 效能優化和記憶體管理
□ UI/UX 細節完善
□ 建立使用者指南
□ 完善錯誤訊息
□ 添加使用分析
□ 實作偏好設定
□ 建立自動更新機制
□ 完善測試覆蓋率
□ 準備 MVP 發布
```

##### Definition of Done:
- [ ] 所有 MVP 功能正常運作
- [ ] 測試覆蓋率 > 90%
- [ ] 效能符合預期
- [ ] 使用文檔完整

---

## 🔧 GitHub Actions 配置

### **CI/CD Pipeline**

```yaml
# .github/workflows/ci.yml
name: CI/CD Pipeline

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

jobs:
  test:
    runs-on: macos-latest
    steps:
    - uses: actions/checkout@v4
    - name: Setup Xcode
      uses: maxim-lobanov/setup-xcode@v1
      with:
        xcode-version: latest-stable
    - name: Build and Test
      run: |
        xcodebuild -scheme GitCthulhu \
                   -destination 'platform=macOS' \
                   -configuration Debug \
                   clean build test
    - name: Code Coverage
      run: |
        xcrun xccov view --report --json \
        DerivedData/Logs/Test/*.xcresult > coverage.json
    - name: Upload Coverage
      uses: codecov/codecov-action@v3

  lint:
    runs-on: macos-latest
    steps:
    - uses: actions/checkout@v4
    - name: SwiftLint
      uses: norio-nomura/action-swiftlint@3.2.1

  build:
    runs-on: macos-latest
    needs: [test, lint]
    if: github.ref == 'refs/heads/main'
    steps:
    - uses: actions/checkout@v4
    - name: Build Release
      run: |
        xcodebuild -scheme GitCthulhu \
                   -configuration Release \
                   -archivePath GitCthulhu.xcarchive \
                   archive
    - name: Export App
      run: |
        xcodebuild -exportArchive \
                   -archivePath GitCthulhu.xcarchive \
                   -exportPath ./build \
                   -exportOptionsPlist ExportOptions.plist
    - name: Create DMG
      run: ./Scripts/create-dmg.sh
    - name: Upload Artifacts
      uses: actions/upload-artifact@v3
      with:
        name: GitCthulhu-${{ github.sha }}
        path: ./build/GitCthulhu.dmg
```

### **Release Pipeline**

```yaml
# .github/workflows/release.yml
name: Release

on:
  push:
    tags:
      - 'v*'

jobs:
  release:
    runs-on: macos-latest
    steps:
    - uses: actions/checkout@v4
    - name: Build Release
      run: ./Scripts/build-release.sh
    - name: Create Release
      uses: actions/create-release@v1
      env:
        GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
      with:
        tag_name: ${{ github.ref }}
        release_name: Release ${{ github.ref }}
        draft: false
        prerelease: false
    - name: Upload Release Asset
      uses: actions/upload-release-asset@v1
      env:
        GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
      with:
        upload_url: ${{ steps.create_release.outputs.upload_url }}
        asset_path: ./GitCthulhu.dmg
        asset_name: GitCthulhu-${{ github.ref_name }}.dmg
        asset_content_type: application/x-apple-diskimage
```

---

## 📊 Sprint 規劃總覽

| Sprint | 週次 | 主要功能 | 預期產出 |
|--------|------|----------|----------|
| 0 | 1-2 | 專案初始化 | CI/CD + 基礎架構 |
| 1 | 3-4 | Git 核心架構 | Repository 讀取 |
| 2 | 5-6 | 檔案狀態管理 | Status + Staging |
| 3 | 7-8 | Commit 功能 | 完整 Commit 流程 |
| 4 | 9-10 | 分支管理 | Branch 操作 |
| 5 | 11-12 | Remote 操作 | Push/Pull 功能 |
| 6 | 13-14 | MVP 完善 | 可發布版本 |

---

## 🎯 Definition of Ready

每個 User Story 開始前須滿足：
- [ ] 需求明確定義
- [ ] 接受條件清楚
- [ ] 設計模型完成
- [ ] 技術實作方案確認
- [ ] 測試策略制定

## ✅ Definition of Done

每個 Sprint 完成須滿足：
- [ ] 所有功能正常運作
- [ ] 單元測試覆蓋率 > 85%
- [ ] 代碼通過 Review
- [ ] 文檔已更新
- [ ] CI/CD 管道成功
- [ ] 無已知 Critical Bug

---

這個計畫將在 14 週內交付一個功能完整的 MVP 版本！🚀
