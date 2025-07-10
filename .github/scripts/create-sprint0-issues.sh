#!/bin/bash

# Sprint 0 Issues 建立腳本
# 根據 plan.md 建立 Sprint 0 的所有 Issues

set -e

echo "📋 建立 Sprint 0 Issues..."

# Epic: 專案基礎建設
gh issue create \
  --title "[EPIC] 專案基礎建設" \
  --label "type/epic,priority/high,sprint/0-setup" \
  --milestone "Sprint 0: 專案初始化" \
  --body "## 🎯 Epic 概述

建立完整的開發環境和 CI/CD 流程，為後續開發奠定基礎。

## 📊 業務價值

**為什麼這個 Epic 很重要？**
- 建立標準化的開發流程
- 確保代碼品質和自動化測試
- 提供清楚的專案架構和文檔

## 🎨 使用者體驗

**開發者將如何受益？**
- 簡化的開發環境設置
- 自動化的建置和測試流程
- 清楚的專案結構和貢獻指南

## 📋 相關 User Stories

### 必須完成 (Must Have)
- [ ] #[將由後續腳本填入] - 建立 Xcode 專案結構
- [ ] #[將由後續腳本填入] - 設置專案文檔
- [ ] #[將由後續腳本填入] - 配置自動化建置流程

## 🏗️ 技術架構

### 主要元件
- Xcode Workspace - 專案管理
- Swift Package Manager - 依賴管理
- GitHub Actions - CI/CD 流程
- libgit2 - Git 操作核心

### 技術債務/風險
- libgit2 整合複雜度 - 使用 Swift wrapper 簡化
- CI/CD 配置複雜 - 使用標準模板

## 📅 時程規劃

**預計開始日期**: $(date +%Y-%m-%d)
**預計完成日期**: $(date -v+14d +%Y-%m-%d)
**相關 Sprint**: Sprint 0

## 📏 成功指標

### 功能指標
- [ ] 專案可在 Xcode 中正常編譯
- [ ] GitHub Actions 正常運行

### 技術指標
- [ ] 代碼覆蓋率達 80%
- [ ] 所有依賴正確安裝

## ✅ Definition of Done

- [ ] 所有 Must Have User Stories 完成
- [ ] 整體功能測試通過
- [ ] 文檔更新完成
- [ ] CI/CD 管道正常運行"

# User Story 1: 建立 Xcode 專案結構
gh issue create \
  --title "[USER STORY] 作為開發者，我需要建立 Xcode 專案結構" \
  --label "type/story,priority/high,sprint/0-setup" \
  --milestone "Sprint 0: 專案初始化" \
  --body "## 📋 User Story

**作為** 開發者
**我需要** 建立完整的 Xcode 專案結構
**以便** 開始 Swift 應用程式開發

## 🎯 接受條件

- [ ] 建立 Xcode Workspace
- [ ] 設置 Swift Package Manager
- [ ] 配置 libgit2 依賴
- [ ] 建立基本專案結構
- [ ] 設置多模組架構

## 📝 詳細描述

### 背景
需要建立一個結構化的 Xcode 專案，支援 SwiftUI + AppKit 混合開發模式。

### 預期行為
- 專案結構清晰，模組化設計
- 支援 macOS 12+ 目標
- 整合 libgit2 作為 Git 操作核心

### 技術考量
- 使用 Swift Package Manager 管理依賴
- 模組化架構便於測試和維護
- 支援 SwiftUI 和 AppKit 混合開發

## 🧪 測試場景

### 測試案例 1: 專案建置
- **Given** 新的開發環境
- **When** 執行 Xcode 建置
- **Then** 專案成功編譯無錯誤

### 測試案例 2: 依賴整合
- **Given** 配置好的專案結構
- **When** 導入 libgit2
- **Then** 可以正常使用 Git 操作

## 📚 相關資源

- [ ] libgit2 Swift wrapper 文檔
- [ ] SwiftUI + AppKit 整合指南
- [ ] 專案架構設計文檔

## ✅ Definition of Done

- [ ] 專案可在 Xcode 中正常編譯
- [ ] 所有依賴正確安裝
- [ ] 基本專案結構完整
- [ ] 模組化架構就緒"

# User Story 2: 設置專案文檔
gh issue create \
  --title "[USER STORY] 作為貢獻者，我需要清楚的專案文檔" \
  --label "type/story,priority/medium,sprint/0-setup" \
  --milestone "Sprint 0: 專案初始化" \
  --body "## 📋 User Story

**作為** 貢獻者
**我需要** 清楚完整的專案文檔
**以便** 了解專案架構和貢獻方式

## 🎯 接受條件

- [ ] 撰寫 README.md
- [ ] 建立 CONTRIBUTING.md
- [ ] 設置 GitHub Sponsors
- [ ] 建立 Issue/PR 範本
- [ ] 撰寫 API 文檔

## 📝 詳細描述

### 背景
開源專案需要完整的文檔來幫助貢獻者理解專案架構和開發流程。

### 預期行為
- 新貢獻者可以快速上手
- 清楚的開發指南和規範
- 完整的 API 文檔

### 技術考量
- 使用 Markdown 格式
- 支援多語言（中英文）
- 自動化文檔生成

## 🧪 測試場景

### 測試案例 1: 文檔完整性
- **Given** 新的貢獻者
- **When** 閱讀專案文檔
- **Then** 可以理解專案架構和開發流程

### 測試案例 2: 設置指南
- **Given** 文檔中的設置步驟
- **When** 按照指南設置開發環境
- **Then** 可以成功運行專案

## 📚 相關資源

- [ ] GitHub 文檔最佳實踐
- [ ] 開源專案文檔範例
- [ ] API 文檔生成工具

## ✅ Definition of Done

- [ ] 所有文檔撰寫完成
- [ ] 文檔結構清晰
- [ ] 支援多語言
- [ ] 自動化更新機制"

# User Story 3: 配置自動化建置流程
gh issue create \
  --title "[USER STORY] 作為維護者，我需要自動化建置流程" \
  --label "type/story,priority/high,sprint/0-setup" \
  --milestone "Sprint 0: 專案初始化" \
  --body "## 📋 User Story

**作為** 維護者
**我需要** 自動化的建置和測試流程
**以便** 確保代碼品質和持續整合

## 🎯 接受條件

- [ ] 配置 GitHub Actions CI/CD
- [ ] 設置代碼品質工具
- [ ] 建立自動化測試環境
- [ ] 配置測試覆蓋率報告
- [ ] 設置自動化發布流程

## 📝 詳細描述

### 背景
需要建立完整的 CI/CD 流程來自動化建置、測試和部署。

### 預期行為
- 每次 PR 都自動執行測試
- 代碼品質檢查自動化
- 自動生成測試覆蓋率報告
- 自動化發布流程

### 技術考量
- 使用 GitHub Actions
- 整合 SwiftLint 和 SwiftFormat
- 支援多平台建置

## 🧪 測試場景

### 測試案例 1: CI 流程
- **Given** 新的 PR
- **When** 提交到 GitHub
- **Then** 自動執行建置和測試

### 測試案例 2: 代碼品質
- **Given** 不符合規範的代碼
- **When** 執行 CI 檢查
- **Then** 顯示相應的錯誤訊息

## 📚 相關資源

- [ ] GitHub Actions 文檔
- [ ] SwiftLint 配置指南
- [ ] Xcode 自動化建置

## ✅ Definition of Done

- [ ] GitHub Actions 正常運行
- [ ] 所有檢查流程完整
- [ ] 測試覆蓋率達標
- [ ] 自動化流程文檔化"

echo "✅ Sprint 0 Issues 建立完成！"
echo "🔄 請手動更新 Epic 中的 User Story 連結"