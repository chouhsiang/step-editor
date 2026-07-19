# Step Patch

[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/Platform-iOS-blue.svg)](https://www.apple.com/ios/)
[![Swift](https://img.shields.io/badge/Swift-5.0-orange.svg)](https://swift.org)
[![iOS](https://img.shields.io/badge/iOS-17%2B-lightgrey.svg)](https://www.apple.com/ios/)
[![GitHub stars](https://img.shields.io/github/stars/chouhsiang/step-patch?style=social)](https://github.com/chouhsiang/step-patch/stargazers)

<p align="center">
  <img src="docs/app-icon.png" alt="Step Patch App Icon" width="128">
</p>

把你輸入的步數寫入 iPhone「健康」App（HealthKit）。

開源專案：https://github.com/chouhsiang/step-patch

<p align="center">
  <img src="docs/screenshot.png" alt="Step Patch App 介面" width="320">
</p>

## 功能

- 輸入要新增的步數
- 選擇紀錄時間
- 一鍵同步到「健康」App

## 需求

- macOS + **Xcode 15+**（需安裝完整 Xcode，不只 Command Line Tools）
- **實體 iPhone**（HealthKit 寫入步數請用真機；模擬器功能有限）
- Apple ID（免費開發者帳號即可測試）

## 開啟與執行

1. 雙擊開啟 `StepEditor.xcodeproj`
2. 上方選你的 **Team**（Signing & Capabilities → Team）
3. 確認已勾選 **HealthKit** capability（專案已含 entitlements）
4. 用 USB 連接 iPhone，選擇該裝置後按 Run（▶）
5. 首次開啟會跳出健康授權，請允許「步數」寫入

## 使用方式

1. 在 App 輸入步數（例如 `2000`）
2. （可選）調整紀錄時間
3. 按「新增步數」
4. 打開系統「健康」App → 瀏覽 → 活動能力 → 步數，即可看到新增紀錄（來源會顯示本 App）

## 若授權失敗

到 iPhone：**設定 → 健康 → 資料取用與裝置 → Step Patch**，開啟步數的寫入權限。

## 專案結構

```
StepEditor/
├── StepEditorApp.swift      # App 入口
├── ContentView.swift        # 輸入介面
├── HealthKitManager.swift   # HealthKit 寫入邏輯
├── Info.plist               # 健康權限說明文字
└── StepEditor.entitlements  # HealthKit entitlement
```

## 授權

本專案採用 [MIT License](LICENSE)。
