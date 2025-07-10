#!/bin/bash

# GitHub Labels 設置腳本
# 使用 GitHub CLI 建立專案標籤

set -e

echo "🏷️ 設置 GitHub Labels..."

# 優先級標籤
gh label create "priority/critical" --color "d93f0b" --description "需要立即處理的關鍵問題"
gh label create "priority/high" --color "ff9500" --description "高優先級任務"
gh label create "priority/medium" --color "fbca04" --description "中優先級任務"
gh label create "priority/low" --color "0e8a16" --description "低優先級任務"

# 類型標籤
gh label create "type/epic" --color "8b5cf6" --description "大型功能或主題"
gh label create "type/story" --color "3b82f6" --description "使用者故事"
gh label create "type/task" --color "10b981" --description "開發任務"
gh label create "type/bug" --color "dc2626" --description "軟體缺陷"
gh label create "type/enhancement" --color "a855f7" --description "功能改進"
gh label create "type/docs" --color "0ea5e9" --description "文檔相關"
gh label create "type/test" --color "84cc16" --description "測試相關"

# 狀態標籤
gh label create "status/ready" --color "22c55e" --description "準備開始"
gh label create "status/in-progress" --color "f59e0b" --description "進行中"
gh label create "status/blocked" --color "ef4444" --description "被阻塞"
gh label create "status/review" --color "8b5cf6" --description "需要審核"
gh label create "status/done" --color "059669" --description "已完成"

# Sprint 標籤
gh label create "sprint/0-setup" --color "fbbf24" --description "Sprint 0: 專案初始化"
gh label create "sprint/1-core" --color "f472b6" --description "Sprint 1: 核心架構"
gh label create "sprint/2-status" --color "60a5fa" --description "Sprint 2: 檔案狀態管理"
gh label create "sprint/3-commit" --color "a78bfa" --description "Sprint 3: Commit 功能"
gh label create "sprint/4-branch" --color "34d399" --description "Sprint 4: 分支管理"
gh label create "sprint/5-remote" --color "fbbf24" --description "Sprint 5: Remote 操作"
gh label create "sprint/6-mvp" --color "f87171" --description "Sprint 6: MVP 完善"

# 技術標籤
gh label create "tech/swift" --color "fa7517" --description "Swift 相關"
gh label create "tech/swiftui" --color "007aff" --description "SwiftUI 相關"
gh label create "tech/appkit" --color "5856d6" --description "AppKit 相關"
gh label create "tech/libgit2" --color "f03c2e" --description "libgit2 相關"
gh label create "tech/ci-cd" --color "2563eb" --description "CI/CD 相關"

# 特殊標籤
gh label create "good-first-issue" --color "7057ff" --description "適合新手的議題"
gh label create "help-wanted" --color "008672" --description "需要幫助"
gh label create "claude-assisted" --color "ff6b6b" --description "由 Claude 協助開發"

echo "✅ GitHub Labels 設置完成！"