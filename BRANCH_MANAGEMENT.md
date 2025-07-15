# GitCthulhu 分支管理指南

## 🎯 總體原則

### 核心規則
- **main 分支保護**: 絕對不允許直接 commit 到 main 分支
- **PR 必須**: 所有變更都必須透過 Pull Request
- **品質門檻**: 所有 PR 都必須通過完整的品質檢查
- **歷史清潔**: 使用 Squash and Merge 保持 commit history 簡潔

## 📋 標準實作流程

### 1. 開始新的 Task
```bash
# 確保 main 分支是最新的
git checkout main
git pull origin main

# 建立新的 feature branch
git checkout -b feature/task-{number}-{description}
```

### 2. 分支命名規則
- **格式**: `feature/task-{number}-{description}`
- **範例**:
  - `feature/task-32-git-status-check`
  - `feature/task-33-file-status-model`
  - `feature/task-34-file-list-ui`

### 3. 開發過程中
```bash
# 定期提交變更
git add .
git commit -m "feat: implement basic status parsing"

# 定期同步 main 分支 (避免衝突)
git fetch origin main
git rebase origin/main
```

### 4. 完成實作後
```bash
# 最終推送到遠端
git push origin feature/task-{number}-{description}

# 開啟 Pull Request (使用 GitHub CLI)
gh pr create --title "[TASK] 功能描述" --body "詳細描述變更內容"
```

## 🔍 PR 品質檢查清單

### 必須通過的檢查
- [ ] **CI/CD 管道**: 所有自動化測試通過
- [ ] **程式碼覆蓋率**: 覆蓋率 > 85%
- [ ] **Linting**: 無 SwiftLint 警告或錯誤
- [ ] **建置**: 專案可以正常建置
- [ ] **功能測試**: 相關功能正常運作
- [ ] **文檔更新**: 相關文檔已更新
- [ ] **相依性檢查**: 不會破壞現有功能

### PR 描述規範
```markdown
## 🎯 變更摘要
簡要描述這個 PR 的目的和主要變更

## 📋 主要變更
- 變更 1
- 變更 2
- 變更 3

## 🧪 測試
- [ ] 單元測試已添加/更新
- [ ] 整合測試已驗證
- [ ] 手動測試已完成

## 📚 相關 Issue
Closes #32

## 🔗 依賴關係
- 依賴於 #31 (如果有)
- 被 #33 依賴 (如果有)
```

## 🚀 合併流程

### 1. PR 審查
- **自動檢查**: 所有 CI/CD 檢查必須通過
- **手動審查**: 程式碼品質和架構檢查
- **功能驗證**: 確認功能符合需求

### 2. 合併操作
```bash
# 使用 GitHub 介面的 "Squash and Merge"
# 或使用 CLI
gh pr merge {PR_NUMBER} --squash
```

### 3. 清理
```bash
# 刪除本地 feature branch
git checkout main
git branch -d feature/task-{number}-{description}

# 遠端 branch 會自動刪除 (GitHub 設定)
```

## 🔄 分支同步策略

### 定期同步
```bash
# 每日開始工作前
git checkout main
git pull origin main
git checkout feature/task-{number}-{description}
git rebase origin/main
```

### 衝突解決
```bash
# 如果 rebase 有衝突
git rebase origin/main
# 解決衝突後
git add .
git rebase --continue
```

## 🚨 緊急情況處理

### Hotfix 流程
```bash
# 建立 hotfix branch
git checkout main
git pull origin main
git checkout -b hotfix/critical-bug-fix

# 完成修復後
git push origin hotfix/critical-bug-fix
gh pr create --title "[HOTFIX] 緊急修復描述"
```

### 回滾策略
```bash
# 如果需要回滾某個 commit
git checkout main
git pull origin main
git revert {commit_hash}
git push origin main
```

## 📊 分支狀態監控

### 查看分支狀態
```bash
# 查看所有分支
git branch -a

# 查看分支與 main 的關係
git log --oneline --graph main..HEAD

# 查看未合併的分支
git branch --no-merged main
```

### 清理過期分支
```bash
# 清理已合併的本地分支
git branch --merged main | grep -v main | xargs -n 1 git branch -d

# 清理遠端追蹤分支
git remote prune origin
```

## 🎓 最佳實踐

### 分支管理
1. **小而頻繁**: 每個 PR 專注於單一功能
2. **即時同步**: 定期 rebase main 分支
3. **清潔提交**: 合併前整理 commit history
4. **描述清楚**: PR 標題和描述要詳細

### 避免的錯誤
1. ❌ 直接 commit 到 main 分支
2. ❌ 長時間不同步 main 分支
3. ❌ 在測試失敗時強制合併
4. ❌ 混合多個功能在同一個 PR

### 團隊協作
1. ✅ 使用統一的分支命名規則
2. ✅ 保持 PR 大小適中
3. ✅ 及時回應 PR 審查意見
4. ✅ 合併後及時清理分支

---

*此指南確保 GitCthulhu 專案的分支管理規範和程式碼品質*
