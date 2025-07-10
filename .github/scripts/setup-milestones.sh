#!/bin/bash

# GitHub Milestones 設置腳本
# 使用 GitHub CLI 建立 Sprint Milestones

set -e

echo "🎯 設置 GitHub Milestones..."

# 計算日期 (假設從今天開始)
START_DATE=$(date +%Y-%m-%d)

# Sprint 0: 專案初始化 (Week 1-2)
gh api repos/:owner/:repo/milestones \
  --method POST \
  --field title="Sprint 0: 專案初始化" \
  --field description="建立完整的開發環境和 CI/CD 流程

🎯 主要目標:
- 建立 Xcode 專案結構
- 設置 Swift Package Manager
- 配置 libgit2 依賴
- 建立基本專案結構
- 設置 GitHub Actions CI/CD

✅ Definition of Done:
- 專案可在 Xcode 中正常編譯
- GitHub Actions 正常運行
- 代碼覆蓋率達 80%
- 所有依賴正確安裝" \
  --field state="open" \
  --field due_on="$(date -d "+14 days" -u +%Y-%m-%dT%H:%M:%SZ)"

# Sprint 1: 核心架構 (Week 3-4)
gh api repos/:owner/:repo/milestones \
  --method POST \
  --field title="Sprint 1: 核心架構" \
  --field description="建立 Git 操作的基礎架構

🎯 主要目標:
- 設計 GitRepository 協議
- 實作 libgit2 wrapper
- 建立 Repository 管理器
- 設計 MVVM 架構
- 建立基本的 SwiftUI 視圖

✅ Definition of Done:
- 可以成功讀取 Git repository
- 錯誤處理完整
- 單元測試覆蓋率 > 85%
- 記憶體無洩漏" \
  --field state="open" \
  --field due_on="$(date -d "+28 days" -u +%Y-%m-%dT%H:%M:%SZ)"

# Sprint 2: 檔案狀態管理 (Week 5-6)
gh api repos/:owner/:repo/milestones \
  --method POST \
  --field title="Sprint 2: 檔案狀態管理" \
  --field description="顯示和管理 Git 工作目錄狀態

🎯 主要目標:
- 實作 Git Status 檢查
- 建立檔案狀態模型
- 設計檔案列表 UI
- 實作 Staging 操作
- 建立 Diff 檢視器

✅ Definition of Done:
- 檔案狀態即時更新
- Stage/Unstage 操作正常
- Diff 顯示正確
- UI 響應流暢" \
  --field state="open" \
  --field due_on="$(date -d "+42 days" -u +%Y-%m-%dT%H:%M:%SZ)"

# Sprint 3: Commit 功能 (Week 7-8)
gh api repos/:owner/:repo/milestones \
  --method POST \
  --field title="Sprint 3: Commit 功能" \
  --field description="實作完整的 commit 功能

🎯 主要目標:
- 實作 Commit 操作
- 建立 Commit Message 編輯器
- 建立 Commit 歷史檢視
- 添加 GPG 簽名支援
- 實作 Amend Commit

✅ Definition of Done:
- Commit 操作穩定可靠
- Message 驗證正確
- 歷史顯示完整
- 支援 GPG 簽名" \
  --field state="open" \
  --field due_on="$(date -d "+56 days" -u +%Y-%m-%dT%H:%M:%SZ)"

# Sprint 4: 分支管理 (Week 9-10)
gh api repos/:owner/:repo/milestones \
  --method POST \
  --field title="Sprint 4: 分支管理" \
  --field description="實作分支的建立、切換、合併功能

🎯 主要目標:
- 實作分支列表檢視
- 建立分支操作介面
- 實作分支合併介面
- 建立分支視覺化
- 實作分支清理功能

✅ Definition of Done:
- 分支操作無誤
- 合併衝突正確處理
- 視覺化清晰易懂
- 資料一致性保證" \
  --field state="open" \
  --field due_on="$(date -d "+70 days" -u +%Y-%m-%dT%H:%M:%SZ)"

# Sprint 5: Remote 操作 (Week 11-12)
gh api repos/:owner/:repo/milestones \
  --method POST \
  --field title="Sprint 5: Remote 操作" \
  --field description="實作 push、pull、fetch 等遠端操作

🎯 主要目標:
- 實作 Remote 管理
- 建立認證機制
- 實作 Push/Pull/Fetch 操作
- 建立衝突解決介面
- 添加 SSH Key 管理

✅ Definition of Done:
- Remote 操作穩定
- 認證機制完善
- 網路錯誤處理完整
- 進度回饋即時" \
  --field state="open" \
  --field due_on="$(date -d "+84 days" -u +%Y-%m-%dT%H:%M:%SZ)"

# Sprint 6: MVP 完善 (Week 13-14)
gh api repos/:owner/:repo/milestones \
  --method POST \
  --field title="Sprint 6: MVP 完善" \
  --field description="完善 MVP 功能，準備首次發布

🎯 主要目標:
- 整合所有功能模組
- 效能優化和記憶體管理
- UI/UX 細節完善
- 建立使用者指南
- 準備 MVP 發布

✅ Definition of Done:
- 所有 MVP 功能正常運作
- 測試覆蓋率 > 90%
- 效能符合預期
- 使用文檔完整" \
  --field state="open" \
  --field due_on="$(date -d "+98 days" -u +%Y-%m-%dT%H:%M:%SZ)"

echo "✅ GitHub Milestones 設置完成！"
