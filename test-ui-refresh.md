# 測試 UI 自動刷新功能

## 測試步驟

### 準備工作
1. 確保 GitCthulhu 有足夠的 log 輸出來觀察行為
2. 運行 GitCthulhu：`swift run GitCthulhu`
3. 打開這個 repository

### 測試場景

#### 1. 基本分支切換測試
```bash
# 在終端機中執行
git checkout main
git checkout invalid/branch/name
git checkout main
```

**預期結果：**
- 左側 repository 列表中的分支名稱應該立即更新
- 不需要手動點擊其他 repository

#### 2. 觀察 Log 輸出
在終端機執行分支切換時，應該看到以下 log：

```
[RepositoryManager] Repository 'GitCthulhu' changed, triggering RepositoryManager update
[RepositoryManager] Repository 'GitCthulhu' branch changed to: main
[GitRepository] Evaluating event for refresh: .git/HEAD
[GitRepository]   -> Git file .git/HEAD: will refresh
[GitRepository] File system changes detected, refreshing repository status
```

#### 3. 驗證 UI 響應性
- **左側 repositories 列表**：分支名稱應該在 1-2 秒內自動更新 ✅
- **Current Repository 區域**：分支信息應該在 1-2 秒內自動更新 ✅
- **右側詳細資訊面板**：RepositoryInfoPanel 中的分支信息也應該同步更新 ✅

### 如果測試失敗
1. 檢查 console log 是否有錯誤信息
2. 確認文件系統監控是否正常啟動
3. 驗證 repository change observation 是否正確建立
4. 檢查 RepositoryDetailViewModel 是否正確觀察 repository 變更

## 修復內容摘要

### 1. RepositoryManager 增強
- 添加了 `observeRepositoryChanges()` 方法監聽每個 GitRepository 的變更
- 當 repository 的 @Published 屬性改變時，觸發 RepositoryManager 的 `objectWillChange`
- 在添加/移除 repository 時正確管理觀察訂閱

### 2. UI 綁定修復
- 將 `SidebarRepositoryRow` 中的 `let repository` 改為 `@ObservedObject var repository`
- 將 `RepositoryInfoPanel` 中的 `let repository` 改為 `@ObservedObject var repository`
- 確保 UI 組件能夠響應 repository 對象的變更

### 3. 文件系統監控增強
- 改進 `shouldRefreshForEvent` 邏輯，正確檢測 `.git/HEAD` 變更
- 移除 FileSystemMonitor 中過於嚴格的過濾規則
- 添加詳細的 debug logging

### 4. RepositoryDetailViewModel 改進
- 添加了 repository-specific 觀察機制
- Repository 變更時自動觸發 repositoryInfo 刷新
- 使用 debounced 更新防止過度的 API 調用
- 觀察 objectWillChange 和 currentBranch 屬性變更
- 修復右側詳細資訊面板不自動更新的問題

這些修復應該完全解決外部 git 操作不觸發 UI 更新的問題。
