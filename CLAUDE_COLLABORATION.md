# 🤖 Claude 協作指南

## 📋 協作流程

### 1. Issue 建立與分配
- 根據 `plan.md` 建立結構化的 Issues
- 每個 Issue 都有明確的標籤和 Milestone
- 使用 `@claude` mention 來請求協助

### 2. 開發流程
```
1. 在 Issue 中 @claude 並描述需求
2. Claude 回覆確認任務並建立 Todo List
3. Claude 開始開發並更新進度
4. 完成後 Claude 建立 PR 並關聯 Issue
5. Code Review 後合併
```

### 3. Issue 標籤系統

#### 優先級
- `priority/critical` - 需要立即處理
- `priority/high` - 高優先級
- `priority/medium` - 中優先級
- `priority/low` - 低優先級

#### 類型
- `type/epic` - 大型功能主題
- `type/story` - 使用者故事
- `type/task` - 具體開發任務
- `type/bug` - 軟體缺陷
- `type/enhancement` - 功能改進

#### 狀態
- `status/ready` - 準備開始
- `status/in-progress` - 進行中
- `status/blocked` - 被阻塞
- `status/review` - 需要審核

#### Sprint
- `sprint/0-setup` - 專案初始化
- `sprint/1-core` - 核心架構
- `sprint/2-status` - 檔案狀態管理
- `sprint/3-commit` - Commit 功能
- `sprint/4-branch` - 分支管理
- `sprint/5-remote` - Remote 操作
- `sprint/6-mvp` - MVP 完善

### 4. Claude 協作標記
在 Issue 中加入 `claude-assisted` 標籤來標記由 Claude 協助的任務

## 🎯 最佳實踐

### Issue 描述範例
```markdown
@claude 請協助實作這個功能

**需求描述:**
[詳細描述需求]

**接受條件:**
- [ ] 條件 1
- [ ] 條件 2

**技術考量:**
[任何技術限制或建議]
```

### Claude 回覆範例
```markdown
我會協助您實作這個功能！

**實作計劃:**
1. [步驟 1]
2. [步驟 2]
3. [步驟 3]

**預估時間:** [時間]
**相關檔案:** [檔案清單]

開始進行實作，我會持續更新進度。
```

## 📊 進度追蹤

### Milestone 對應
- **Sprint 0**: 專案初始化 (Week 1-2)
- **Sprint 1**: 核心架構 (Week 3-4)
- **Sprint 2**: 檔案狀態管理 (Week 5-6)
- **Sprint 3**: Commit 功能 (Week 7-8)
- **Sprint 4**: 分支管理 (Week 9-10)
- **Sprint 5**: Remote 操作 (Week 11-12)
- **Sprint 6**: MVP 完善 (Week 13-14)

### 每週檢查點
- 每週五檢查 Sprint 進度
- 更新 Issue 狀態和標籤
- 調整下週工作重點

## 🔧 技術規範

### 代碼規範
- 遵循 Swift 官方程式碼規範
- 使用 SwiftLint 進行代碼檢查
- 單元測試覆蓋率 > 85%

### 提交規範
- 使用語義化的 commit message
- 每個 commit 對應一個具體功能
- 包含相關 Issue 編號

### PR 規範
- 必須關聯相關 Issue
- 通過所有 CI 檢查
- 代碼審查通過後才能合併

## 🚀 快速開始

1. **設置環境**
   ```bash
   # 執行專案設置
   .github/scripts/setup-labels.sh
   .github/scripts/setup-milestones.sh
   .github/scripts/create-sprint0-issues.sh
   ```

2. **開始第一個任務**
   - 到 Issues 頁面找到 Sprint 0 任務
   - 在 Issue 中 @claude 開始協作
   - 按照協作流程進行開發

3. **持續協作**
   - 定期檢查 Issue 進度
   - 及時回應 Claude 的問題
   - 協助進行 Code Review

## 📞 支援與回饋

如果在協作過程中遇到問題：
1. 在相關 Issue 中詳細描述問題
2. 使用 `help-wanted` 標籤請求協助
3. 透過 GitHub Discussions 進行討論

---

透過這個協作流程，我們可以高效地完成 GitCthulhu 的開發！🐙
