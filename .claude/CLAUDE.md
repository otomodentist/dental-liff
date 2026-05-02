# CLAUDE.md — 授業のオトモ システム概要

> LINE × AI 歯学部授業集中度モニタリングシステム  
> Claude Codeでの開発・保守向けドキュメント

---

## 📌 サービス概要

歯学部の授業中に**LINEを使って学生の集中度をリアルタイム計測**するシステム。  
先生がLINEで問題を出題し、学生が回答 → GPT-4oが採点 → 集中度スコアを自動計算・蓄積。

**集中度スコア = 正確性スコア（GPT採点: 0〜100）× 速度乗数（0.3〜1.0）**

- 60秒以内: ×1.0（ペナルティなし）
- 60〜270秒: 30秒ごとに×0.1減衰（×0.9, ×0.8, …）
- 270秒（4.5分）以降: ×0.3固定
- 授業中リアルタイム出題のため「聞いていれば即答できるはず」という前提で即時性を重視

---

## 🏗️ システム構成

[LINE Bot（授業のオトモ）]
↓ Webhook
[Google Apps Script（GAS）]
↓
┌─────────────────────────┐
│  gas_main.js.gs          │  メイン処理：Webhook受信・イベントルーティング
│  gas_richmenu.js.gs      │  リッチメニュー管理（作成・画像アップ・設定）
└─────────────────────────┘
↓ OpenAI API（採点）       ↓ DriveApp（画像）
[GPT-4o]                   [Google Drive]
↓ SpreadsheetApp
[Google Sheets（otomo_data）]
↓ GAS Web App API（CORS対応）
[LIFF（GitHub Pages）]
├── admin_liff.html    管理者ダッシュボード
└── index.html         学生向けページ

---

## 🔑 固有ID・URL一覧

### LINE

| 項目 | 値 |
|---|---|
| Channel ID | `2008587142` |
| Channel Name | 授業のオトモ |
| Admin User ID | `Ubf96bf52b57d4e329a5bcf4ce509c6be` |
| LIFF ID | `2009739219-9qVGb0Xm` |

### Google Apps Script

| 項目 | 値 |
|---|---|
| Project ID | `1dfHpjEjSigxTJbSnuER99IKDBROzZ-ZXJ2XPiNJMfDsUZ9idejL35Cq8` |
| Web App URL（Webhook & API） | `https://script.google.com/macros/s/AKfycbwx7XFQHALQSD7UMBsVXKdxqgH9yktleZOjV3HN-qStmlod8ifpNw6_FazO4-jI6mWiug/exec` |
| Deploy ID（clasp deploy -i に使用） | `AKfycbwx7XFQHALQSD7UMBsVXKdxqgH9yktleZOjV3HN-qStmlod8ifpNw6_FazO4-jI6mWiug` |
| 現在のバージョン | v25（2026/05/03時点） |

### Google Sheets

| 項目 | 値 |
|---|---|
| Spreadsheet ID | `15UpJAol2SayyiEQDyOdKYX02eQQ4pMH4gq4SssJrYT4` |
| シート名: 問題マスタ | 問題ID, 問題文, 模範解答, 科目名, セッションID |
| シート名: 回答データ | 学生ID, セッションID, 問題ID, 回答, 正確性, 速度, 集中度スコア |
| シート名: 授業セッション | セッションID, 科目名, 回数, 開始時刻, 終了時刻 |
| シート名: 学生マスタ | 学生ID, 名前, LINE UserID |
| シート名: 科目マスタ | 科目名, 曜日, 学年, 学期（16科目, 学年4, spring） |

### Google Drive

| 項目 | 値 |
|---|---|
| リッチメニュー画像フォルダID | `1PEBapWgq6JwpSMElYjqoxn2PTnRp189_` |
| 管理者用リッチメニュー画像 File ID | `1UOmAB9M4slNxrjTRWWIn1ZsqEhVEAOeM` |
| 学生用リッチメニュー画像 File ID | `1PtJpjhGQR-osAADW1Qzh9vL00dlSSB7e` |

### GitHub / LIFF

| 項目 | 値 |
|---|---|
| Repository | `otomodentist/dental-liff` |
| GitHub Pages URL | `https://otomodentist.github.io/dental-liff/` |
| Admin LIFF URL | `https://liff.line.me/2009739219-9qVGb0Xm` |
| ファイル: 管理者LIFF | `admin_liff.html` |
| ファイル: 学生LIFF | `index.html` |
| ファイル: リッチメニュー画像生成 | `richmenu_generator.html` |

---

## 📁 GASファイル構成

### `gas_main.js.gs`
- `CONFIG` — APIキー・ID定数（LINE_CHANNEL_ACCESS_TOKEN, OPENAI_API_KEY, ADMIN_USER_ID, SPREADSHEET_ID）
- `doPost(e)` — LINE Webhookエントリポイント
- `handleEvent(event)` — イベントルーター
  - **followイベント** → 管理者判定 → 管理者用リッチメニュー再設定（ブロック解除対応）
  - **messageイベント** → 管理者コマンド or 学生回答に振り分け
- `handleAdminCommand(text, replyToken, timestamp)` — 管理者コマンド処理
  - `[授業開始] 科目名 回数` → `startSession()`
  - `[出題] 問題文 / 模範解答` → `broadcastQuestion()`
  - `[授業終了]` → `endSession()`
- `handleStudentAnswer(userId, text, replyToken, timestamp)` — 学生回答処理 → GPT採点 → 集中度計算
- `calculateSpeedMultiplier(responseTimeSec)` — 速度乗数算出（60秒以内=1.0、以降減衰、最低0.3）
- `scoreAnswerWithGPT(answer, modelAnswer, question)` — GPT-4o-miniで正確性0〜100点採点
- `getInitData()` — 初期化用一括APIエンドポイント（activeSession + semesterData + subjects）
- `getSubjectMaster()` — アクティブな学年・学期でフィルタした科目一覧取得
- `getActiveSemester()` / `setActiveSemester()` — PropertiesServiceでクール管理
- `multicastStartMessage()` / `multicastEndMessage()` — 授業開始・終了時の全員通知
- `pauseQuestionDelivery()` / `resumeQuestionDelivery()` — 出題一時停止・再開

### `gas_richmenu.js.gs`（約180行）
- `createAndSetRichMenu()` — 学生用リッチメニュー作成・画像アップ・デフォルト設定
- `uploadRichMenuImage(richMenuId)` — Google DriveからPNG取得してLINE APIにアップロード
- `setRichMenuDefault(richMenuId)` — デフォルトリッチメニュー設定
- `createAndSetAdminRichMenu()` — 管理者用リッチメニュー作成・設定
- `createAdminRichMenu()` — 管理者用メニュー定義（全面タップ → LIFF_ADMIN_URL）
- `uploadAdminRichMenuImage(richMenuId)` — 管理者用画像アップロード
- `setRichMenuForAdmin(adminRichMenuId)` — 管理者ユーザーにリッチメニューをリンク
- `getAdminRichMenuIdFromList()` — LINE APIから `name:'admin_richmenu'` のIDを検索
- `saveStudentRichMenuImageFromDataUrl(dataUrl)` — Canvas生成画像をDriveに保存
- `openRichMenuGenerator()` — 学生用リッチメニュー画像ジェネレーターをSpreadsheetUIで開く

### `richmenu_generator.html`
- Canvas APIで学生用リッチメニュー画像（2500×843px）を生成
- 青系グラデーション・棒グラフアイコン・「集中度ダッシュボード」テキスト
- 「Save to Drive」ボタンで `saveStudentRichMenuImageFromDataUrl()` 呼び出し

---

## 🔄 主要フロー

### 授業実施フロー（管理者）
1.[授業開始] 科目名 回数  →  LINEで送信
2.[出題] 問題文 / 模範解答  →  LINEで送信（全学生にPush）
3.[授業終了]  →  セッション終了


### 学生回答フロー
LINEで回答テキスト送信
→ GAS handleStudentAnswer()
→ OpenAI GPT-4o-mini に採点リクエスト（正確性スコア: 0〜100、内容のみで評価）
→ 速度乗数計算（出題からの経過時間: 60秒以内=1.0、以降減衰）
→ 集中度スコア = 正確性 × 速度乗数
→ Google Sheets 回答データに保存
→ 学生にスコア返信（正確性・速度・乗数・集中度スコアを表示）


### リッチメニュー管理フロー
初回セットアップ:
createAndSetRichMenu()        ← 学生用（デフォルト）
createAndSetAdminRichMenu()   ← 管理者用（ADMIN_USER_IDにリンク）
ブロック解除時（自動）:
follow event → getAdminRichMenuIdFromList() → setRichMenuForAdmin()


---

## ⚙️ 環境変数・設定値

```javascript
// gas_main.js.gs の CONFIG 定数
const CONFIG = {
  LINE_CHANNEL_ACCESS_TOKEN: '...',      // LINE Messaging API
  OPENAI_API_KEY: 'sk-proj-...',         // OpenAI GPT-4o
  ADMIN_USER_ID: 'Ubf96bf52b57d4e329a5bcf4ce509c6be',
  SPREADSHEET_ID: '15UpJAol2SayyiEQDyOdKYX02eQQ4pMH4gq4SssJrYT4',
  SHEETS: {
    QUESTIONS: '問題マスタ',
    ANSWERS: '回答データ',
    SESSIONS: '授業セッション',
    STUDENTS: '学生マスタ',
  },
};

// gas_richmenu.js.gs の定数
const LIFF_DASHBOARD_URL = 'https://otomodentist.github.io/dental-liff/';
const LIFF_ADMIN_URL     = 'https://liff.line.me/2009739219-9qVGb0Xm';
const ADMIN_RICHMENU_FOLDER_ID = '1PEBapWgq6JwpSMElYjqoxn2PTnRp189_';

// PropertiesService で管理
ACTIVE_GRADE    = '4'       // アクティブ学年
ACTIVE_SEMESTER = 'spring'  // アクティブ学期（クール）
```

---

## 📝 開発時の注意点

1. **GASデプロイ後にLINE Webhook URLは変わらない** — Deploy IDが同じなら再設定不要
2. **followイベントは handleEvent の最初で処理** — `event.type !== 'message'` の前に書くこと
3. **管理者コマンドはLINE User IDで判定** — `userId === CONFIG.ADMIN_USER_ID`
4. **リッチメニュー画像は Google Drive から取得** — File IDが変わったら `uploadRichMenuImage()` 内のIDを更新
5. **LIFF init は admin_liff.html の `liff.init({ liffId: LIFF_ID })` で実行**
6. **科目マスタのフィルタは ACTIVE_GRADE + ACTIVE_SEMESTER** — `getSubjectMaster()` 参照
7. **GASのAPIレスポンスはCORSヘッダー付き** — `Access-Control-Allow-Origin: *`

---

## 🚧 未完了・今後の作業

- [ ] 学生用リッチメニュー画像を管理者用と同テイストで新規生成・更新
  - `openRichMenuGenerator()` を実行 → Save to Drive → FILE IDを `uploadRichMenuImage()` に設定
- [ ] 学生ダッシュボード（index.html）の集中度スコア表示機能実装
- [ ] 科目マスタ追加・編集UIをadmin_liffに追加

---

## 🗓️ 更新履歴

| 日付 | 内容 |
|---|---|
| 2026/04/24 | admin_liff.html のHTMLタグバグ修正（セメスターモーダル） |
| 2026/04/25 | followイベント処理追加（ブロック解除後に管理者用リッチメニュー再設定） |
| 2026/04/25 | `getAdminRichMenuIdFromList()` / `saveStudentRichMenuImageFromDataUrl()` / `openRichMenuGenerator()` 追加 |
| 2026/05/03 | 初期化を`getInitData()`一括APIに統合（GASコールドスタート3回→1回）|
| 2026/05/03 | 採点を速度乗数方式に変更: 正確性×速度乗数（0.3〜1.0）|
| 2026/05/03 | GPT採点プロンプト修正: 正確性のみ0〜100点、完全正解=100点 |
| 2026/05/03 | ダッシュボードフィルタをlocalStorageで永続化・アクティブセメスター自動適用 |
| 2026/05/03 | gas_richmenu.js.gsの未使用関数削除（251→182行）|
