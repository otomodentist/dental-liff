# 授業のオトモ — 歯学部授業集中度モニタリングシステム

LINE × GAS を使って学生の授業集中度をリアルタイム計測するシステム。

## システム構成

- **LINE Bot** — 学生・管理者との対話
- **Google Apps Script (GAS)** — Webhook処理・採点・データ管理
- **LIFF** — 管理者ダッシュボード / 学生マイページ（GitHub Pages）
- **Google Sheets** — データ永続化
- **OpenAI GPT-4o-mini** — 回答採点

## LIFF URL

| 用途 | URL |
|---|---|
| 管理者パネル | `https://liff.line.me/2009739219-9qVGb0Xm` |
| 学生マイページ | `https://otomodentist.github.io/dental-liff/` |

## GAS Web App URL

`https://script.google.com/macros/s/AKfycbzjB3a71oBi5qFJeZOjV3HN-qStmlod8ifpNw6_FazO4-jI6mWiug/exec`

## ファイル構成

| ファイル | 内容 |
|---|---|
| `admin_liff.html` | 管理者向けLIFF（授業開始/終了/出題） |
| `index.html` | 学生向けLIFF（集中度ダッシュボード） |
| `gas_main.js.js` | GASメイン処理（Webhook・採点・API） |
| `gas_richmenu.js.js` | リッチメニュー管理 |
| `richmenu_generator.html` | 学生用リッチメニュー画像ジェネレーター |

## デプロイ手順

```bash
# GASへプッシュ
clasp push

# GitHubへプッシュ（GitHub Pages自動更新）
git push origin main
```

## 修正履歴

| 日付 | 内容 |
|---|---|
| 2026/04/29 | Bug修正: getSubjectMaster をWeb App対応に修正（getActiveSpreadsheet→openById、ContentService二重ラップ解消）|
| 2026/04/29 | Bug修正: admin_liff.html の余分なHTMLタグ除去（`div>`テキストノード・末尾の重複タグ）|
| 2026/04/29 | Bug修正: index.html の GAS_URL を正しいデプロイURLに修正 |
| 2026/04/29 | Bug修正: 学生フォロー時に自動登録処理を追加（初回出題時に学生マスタが空になる問題を解消）|
| 2026/04/26 | clasp連携・scriptId修正 |
| 2026/04/25 | followイベント処理追加（ブロック解除後に管理者用リッチメニュー再設定） |
| 2026/04/24 | admin_liff.html HTMLタグバグ修正 |
