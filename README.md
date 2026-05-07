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

`https://script.google.com/macros/s/AKfycbwx7XFQHALQSD7UMBsVXKdxqgH9yktleZOjV3HN-qStmlod8ifpNw6_FazO4-jI6mWiug/exec`

（現在 v37）

## ファイル構成

| ファイル | 内容 |
|---|---|
| `admin_liff.html` | 管理者向けLIFF（授業管理・学生ダッシュボード・課金管理・試験日程登録） |
| `index.html` | 学生向けLIFF（集中度ダッシュボード・学習計画・試験対策） |
| `demo.html` | デモ体験ページ（未課金ユーザー向けサンプルデータ表示・学習計画デモ） |
| `gas_main.js.js` | GASメイン処理（Webhook・採点・API・課金・学習計画・リマインダー） |
| `gas_richmenu.js.js` | リッチメニュー管理（課金状態による切り替え） |
| `richmenu_generator.html` | 学生用リッチメニュー画像ジェネレーター |

## 主な機能

### 授業リアルタイム採点
- 管理者がLIFF管理画面から問題を出題 → 学生がLINEで回答 → GPT-4o-miniが正確性を採点
- **集中度スコア** = 回答正当度（GPT採点）× 速度乗数（0.3〜1.0）
- 次の問題出題時に前問を自動締め切り（未回答は0点として記録）

### 学習計画（定期試験対策）
- 管理者が試験日程・授業最終日・復習時間を登録
- 学習計画を自動生成（試験4日前〜再復習、逆算でベスト開始日）
- 朝リマインダー（毎朝7時、GASトリガー設定要）
- 進捗ブロック表示（15コマ横棒グラフ）・リプラン機能

### 課金・デモ
- Stripe決済リンク連携（`client_reference_id` で学生ID紐付け）
- 未課金ユーザーはdemo.htmlでサービス体験

## 手動設定が必要な項目

| 項目 | 方法 |
|---|---|
| 朝リマインダーのトリガー | GASエディタで `setupMorningReminderTrigger()` を1回実行 |
| 試験日程登録 | 管理者パネル「試験日程」タブから入力 |
| 授業最終日設定 | 管理者パネル「試験日程」タブ上部から設定 |

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
| 2026/04/24 | admin_liff.html HTMLタグバグ修正 |
| 2026/04/25 | followイベント処理追加（ブロック解除後に管理者用リッチメニュー再設定） |
| 2026/04/26 | clasp連携・scriptId修正 |
| 2026/04/29 | Bug修正: getSubjectMaster をWeb App対応に修正 |
| 2026/04/29 | Bug修正: 学生フォロー時に自動登録処理を追加 |
| 2026/05/05 | demo.html 新規作成（未課金ユーザー向けサンプルダッシュボード） |
| 2026/05/05 | admin_liff.html 課金管理タブ追加・課金分岐リッチメニュー追加 |
| 2026/05/05 | gas_main.js.js: 課金チェック・Stripe決済URL生成・デモアクセス記録追加 |
| 2026/05/06 | index.html: サブスク解約ボタン・確認モーダル追加 |
| 2026/05/06 | gas_main.js.js: cancelSubscription・handleFollowEvent簡略化・完了メッセージ追加 |
| 2026/05/06 | 学習計画機能（大機能1〜4）実装（GAS v32） |
| 2026/05/06 | admin_liff.html: 試験日程タブ追加（科目・試験日・復習時間の登録・削除） |
| 2026/05/06 | index.html: 今日の学習セクション・学習計画画面・試験対策セクション追加 |
| 2026/05/06 | gas_main.js.js: generateStudyPlan・getProgressBlocks・sendMorningReminders等追加 |
| 2026/05/06 | demo.html: 定期試験対策デモ表示追加（令和7年3年生春学期想定） |
| 2026/05/07 | index.html: getStudyPlanInitData 単一API統合・学年学期フィルター・実施コマ表示（GAS v33） |
| 2026/05/07 | 試験日程タブ改善: 授業最終日（全科目共通）・登録済み科目除外・インライン編集機能（GAS v35） |
| 2026/05/08 | グラフのY軸をconcentrationScore（集中度スコア）に統一 |
| 2026/05/08 | 「採点結果」→「回答正当度」にラベル変更（admin_liff・demo 両方） |
| 2026/05/08 | 未回答問題を0点として表示・次問出題時に前問を自動締め切り（回答混戦防止）（GAS v36） |
| 2026/05/08 | GPT採点関数にログ追加（HTTPステータス・レスポンスボディ・スコアテキスト） |
| 2026/05/08 | gas_main.js.js: 授業開始・終了時の学生へのLINE一斉通知を削除（配信数削減）（GAS v37） |
