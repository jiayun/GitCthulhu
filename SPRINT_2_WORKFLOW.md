# Sprint 2 新工作流程

## 🎯 總體原則

### 核心理念
- **依賴驅動**: 嚴格按照技術依賴關係順序執行
- **質量優先**: 寧可慢一點也要確保每個階段的品質
- **一次一個**: 同時只專注於一個 Task 的實作

### 工作流程規則
1. **Task 順序建立**: 只有前置 Task 完成後才建立下一個
2. **協作通知延遲**: 建立 Task 時不立即 mention 協作者
3. **階段性驗證**: 每個階段完成後進行品質檢查
4. **依賴明確標示**: 每個 Task 都清楚標示其依賴關係

## 📋 Sprint 2 實施階段

### Phase 1: 基礎設施 (Week 1)
**目標**: 建立所有後續功能的基礎

#### Task 1: Git Status 檢查 (#32)
- **狀態**: 已建立 ✅
- **依賴**: 無 (基礎 Task)
- **功能**: 實作 Git CLI status 命令執行和解析
- **交付**: GitStatusManager 和 GitStatusEntry

#### Task 2: 檔案狀態模型 (待建立)
- **狀態**: 等待 Task 1 完成
- **依賴**: Task 1 完成
- **功能**: 建立完整的檔案狀態資料結構
- **交付**: 完整的狀態模型和工具函數

### Phase 2: 核心功能 (Week 2)
**目標**: 實作主要的使用者功能

#### Task 3: 檔案列表 UI (待建立)
- **依賴**: Task 1, 2 完成
- **功能**: 顯示檔案列表和狀態指示器
- **交付**: FileListView 和相關 UI 元件

#### Task 4: Staging 操作 (待建立)
- **依賴**: Task 1, 2 完成
- **功能**: 實作 git add/reset 操作
- **交付**: GitStagingManager 和操作介面

#### Task 5: Diff 檢視器 (待建立)
- **依賴**: Task 1 完成 (相對獨立)
- **功能**: 顯示檔案差異內容
- **交付**: DiffViewer 和相關元件

### Phase 3: 增強功能 (Week 3)
**目標**: 提升使用者體驗

#### Task 6: 檔案篩選功能 (待建立)
- **依賴**: Task 3 完成
- **功能**: 按狀態、類型篩選檔案

#### Task 7: 快捷鍵支援 (待建立)
- **依賴**: Task 3, 4 完成
- **功能**: 鍵盤快捷鍵操作

#### Task 8: 即時狀態更新 (待建立)
- **依賴**: Task 1 完成
- **功能**: 檔案系統監控和自動更新

#### Task 9: 檔案圖示系統 (待建立)
- **依賴**: Task 3 完成
- **功能**: 檔案類型和狀態圖示

### Phase 4: 整合 (Week 4)
**目標**: 確保所有功能協同工作

#### Task 10: 整合測試 (待建立)
- **依賴**: 所有功能 Task 完成
- **功能**: 端到端測試和效能驗證

## 🔄 Task 管理流程

### 1. Task 建立時機
```
當前 Task 完成 → 創建下一個 Task Issue → 開始實作
```

### 2. Task Issue 格式
- **標題**: `[TASK] 功能描述 (Phase X)`
- **內容**: 包含詳細技術方案但不 mention 協作者
- **標籤**: `type/task`, `priority/high/medium/low`
- **里程碑**: `Sprint 2: 檔案狀態管理`

### 3. 協作通知時機
- Task Issue 建立後，手動決定何時開始實作
- 在準備開始時才 mention 協作者
- 或直接在 Issue 中回覆開始工作

### 4. 完成標準
每個 Task 完成須滿足：
- [ ] 功能正常運作
- [ ] 單元測試覆蓋率 > 85%
- [ ] 代碼通過 Review
- [ ] 文檔已更新
- [ ] CI/CD 管道成功
- [ ] 後續 Task 的依賴條件滿足

## 🚀 分支管理策略

### 標準實作流程
1. **建立分支**: 從 main 分支建立新的 feature branch
2. **分支命名**: `feature/task-{number}-{description}`
   - 例如: `feature/task-32-git-status-check`
3. **實作完成**: 開啟 Pull Request 到 main 分支
4. **PR 審查**: 確保符合所有品質標準
5. **合併**: 使用 Squash and Merge
6. **清理**: 刪除 feature branch

### PR 要求標準
- [ ] 詳細描述變更內容和目的
- [ ] 所有測試通過
- [ ] 程式碼覆蓋率 > 85%
- [ ] 通過 CI/CD 管道驗證
- [ ] 文檔已更新
- [ ] 無 linting 錯誤

### 合併策略
1. **順序合併**: 按照 Task 完成順序合併
2. **PR Review**: 每個 Task 都需要 PR 和 Review
3. **CI/CD 驗證**: 合併前必須通過所有測試
4. **文檔更新**: 每次合併都更新相關文檔
5. **Squash and Merge**: 保持 commit history 清潔

### 衝突預防
- 明確每個 Task 的檔案修改範圍
- 定期同步 main 分支到 feature 分支
- 使用介面協議避免 API 衝突

## 📊 進度追蹤

### 每日檢查點
- 當前 Task 進度
- 遇到的技術問題
- 預期完成時間
- 是否需要調整後續計畫

### 階段性里程碑
- Phase 1 完成: 基礎設施就緒
- Phase 2 完成: 核心功能可用
- Phase 3 完成: 增強功能完整
- Phase 4 完成: Sprint 2 交付

## 🎓 從錯誤中學習

### 避免的錯誤
1. ❌ 同時建立所有 Task
2. ❌ 在建立時就 mention 協作者
3. ❌ 忽略依賴關係
4. ❌ 並行修改相同檔案

### 正確的做法
1. ✅ 按階段建立 Task
2. ✅ 延遲協作通知
3. ✅ 明確依賴關係
4. ✅ 順序執行和合併

## 🔧 工具和自動化

### GitHub Labels
- `type/task` - Task 類型
- `priority/high` - 高優先級
- `depends-on/task-X` - 依賴關係 (如需要)

### 自動化檢查
- CI/CD 管道驗證
- 測試覆蓋率檢查
- 代碼品質檢查
- 文檔更新驗證

---

*此工作流程基於 Sprint 2 重置的經驗教訓，確保高品質的順序開發*
