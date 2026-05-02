# CLAUDE.md — 授業のオトモ システム概要

> LINE × AI 歯学部授業集中度モニタリングシステム  
> Claude Codeでの開発・保守向けドキュメント

---

## サービス概要

歯学部の授業中に**LINEを使って学生の集中度をリアルタイム計測**するシステム。  
先生がLINEまたは管理画面（LIFF）で問題を出題し、学生が回答 → GPT-4o-miniが採点 → 集中度スコアを自動計算・蓄積。

**集中度スコア = 正確性スコア（GPT採点: 0〜100）× 速度乗数（0.3〜1.0）**

速度乗数の考え方: 授業をその場で聞いていれば即答できるはずなので、遅い回答は検索や見直しを疑う。
- 60秒以内: ×1.0（ペナルティなし）
- 60〜270秒: 30秒ごとに×0.1減衰（×0.9, ×0.8, …）
- 270秒（4.5分）以降: ×0.3固定

---

## システム構成

```
[LINE Bot（授業のオトモ）]
↓ Webhook
[Google Apps Script（GAS）]
  gas_main.js.gs    … Webhook受信・採点・スプレッドシート操作・LIFF用API
  gas_richmenu.js.gs … リッチメニュー管理（手動実行用）
↓ OpenAI API（採点）  ↓ DriveApp（リッチメニュー画像）
[GPT-4o-mini]          [Google Drive]
↓ SpreadsheetApp
[Google Sheets（otomo_data）]
↓ GAS Web App API（CORS対応）
[LIFF（GitHub Pages）]
  admin_liff.html … 管理者ダッシュボード（授業管理・学生ダッシュボード）
  index.html      … 学生マイページ（集中度・直近授業確認）
```

---

## 固有ID・URL一覧

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
| Deploy ID（`clasp deploy -i` に指定） | `AKfycbwx7XFQHALQSD7UMBsVXKdxqgH9yktleZOjV3HN-qStmlod8ifpNw6_FazO4-jI6mWiug` |
| 現在のバージョン | v25（2026/05/03） |

### Google Sheets（Spreadsheet ID: `15UpJAol2SayyiEQDyOdKYX02eQQ4pMH4gq4SssJrYT4`）

| シート名 | カラム |
|---|---|
| 学生マスタ | userID, 表示名, アイコンURL, 登録日時 |
| 授業セッション | セッションID, 科目名, 授業回数, 開始時刻, 終了時刻, ステータス, [pause状態, pause時刻] |
| 問題マスタ | 問題ID, セッションID, 科目名, 授業回数, 経過分, 問題文, 模範解答, 出題時刻 |
| 回答データ | 回答ID, 学生ID, セッションID, 問題ID, 科目名, 授業回数, 経過分, 回答テキスト, 正確性スコア, 回答時間(秒), 集中度スコア, 回答時刻 |
| 科目マスタ | 科目名, 曜日, 学年, 学期（16科目, 学年4, spring） |

### Google Drive

| 項目 | 値 |
|---|---|
| リッチメニュー画像フォルダID | `1PEBapWgq6JwpSMElYjqoxn2PTnRp189_` |
| 管理者用リッチメニュー画像 File ID | `1UOmAB9M4slNxrjTRWWIn1ZsqEhVEAOeM` |
| 学生用リッチメニュー画像 File ID | `1WEpVdG21Ss4Pp9zQQRpLb2PHA1rjlS8b`（mypage_full_blue_final.png） |

### GitHub / LIFF

| 項目 | 値 |
|---|---|
| Repository | `otomodentist/dental-liff` |
| GitHub Pages URL | `https://otomodentist.github.io/dental-liff/` |
| Admin LIFF URL | `https://liff.line.me/2009739219-9qVGb0Xm` |

---

## GASファイル構成

### `gas_main.js.gs`

**Webhook & イベント処理**
- `doPost(e)` — LINE Webhookエントリポイント
- `handleEvent(event)` — followイベント（管理者: リッチメニュー再設定 / 学生: 自動登録）・messageイベントのルーティング（管理者メッセージは無視）
- `handleStudentAnswer(userId, text, replyToken, timestamp)` — GPT採点 → 集中度計算 → 保存 → 返信

**採点**
- `scoreAnswerWithGPT(answer, modelAnswer, question)` — GPT-4o-miniで正確性0〜100点採点（内容のみ評価）
- `calculateSpeedMultiplier(responseTimeSec)` — 速度乗数算出（60秒以内=1.0、以降減衰、4.5分以降=0.3）

**セッション管理**
- `adminStartSession(subjectName, sessionNumber)` — 授業開始（セッション作成 + 全員LINE通知）
- `adminEndSession()` — 授業終了（セッション終了 + 全員LINE通知）
- `adminBroadcast(question, modelAnswer)` — 出題・全員配信
- `pauseQuestionDelivery(sessionId)` — 出題一時停止（全員にLINE通知）
- `resumeQuestionDelivery(sessionId)` — 出題再開

**LIFF用 Web API (`doGet`)**
- `getInitData()` — 一括初期化API（activeSession + semesterData + subjects）。GASコールドスタートを1回に削減
- `getActiveSession()` — アクティブセッション情報取得
- `getSubjectMaster()` — アクティブ学年・学期の科目一覧
- `getActiveSemester()` / `setActiveSemester(grade, semester)` — アクティブクール取得・設定
- `getAdminStudentList()` — 学生一覧
- `getStudentsByGradeAndSemester(grade, semester)` — 学年・学期でフィルタした学生一覧
- `getStudentSessions(userId)` — 学生が参加したセッション一覧
- `queryBySessionAndStudent(sessionId, userId)` — セッション×学生の回答詳細（問題文・模範解答付き）
- `getLatestSessionData(userId)` — 直近終了セッションのサマリ
- `getDashboardData(userId)` — 科目・セッション別集計（学生LIFF用）

**スプレッドシート操作**
- `saveAnswer(...)` — 回答データ保存
- `ensureStudentRegistered(userId)` — 未登録学生の自動登録
- `getActiveStudentIds()` — 全学生IDリスト取得

**LINE APIヘルパー**
- `replyMessage(replyToken, text)` — 返信
- `multicastMessage(userIds, text)` — 最大500件ずつ分割してMulticast送信
- `multicastStartMessage(subjectName, sessionNumber)` — 授業開始通知を全員に送信
- `multicastEndMessage(subjectName)` — 授業終了通知を全員に送信
- `getLineProfile(userId)` — LINEプロフィール取得

**初回セットアップ（手動実行）**
- `setupSpreadsheet()` — 全シート作成・ヘッダー設定
- `setupSubjectMaster()` — 科目マスタ初期データ投入
- `broadcastRegistrationMessage()` — 学生登録案内ブロードキャスト
- `registerAllFollowers()` — フォロワー全員を学生マスタに一括登録

### `gas_richmenu.js.gs`（182行、手動実行用）

- `createAndSetRichMenu()` — 学生用リッチメニュー作成・画像アップ・デフォルト設定
- `createAndSetAdminRichMenu()` — 管理者用リッチメニュー作成・設定
- `getAdminRichMenuIdFromList()` — LINE APIから `name:'admin_richmenu'` のIDを検索（followイベントから呼び出し）
- `setRichMenuForAdmin(adminRichMenuId)` — 管理者ユーザーにリッチメニューをリンク
- `saveStudentRichMenuImageFromDataUrl(dataUrl)` — Canvas生成画像をDriveに保存
- `openRichMenuGenerator()` — 学生用リッチメニュー画像ジェネレーターをSpreadsheetUIで開く

### `richmenu_generator.html`

Canvas APIで学生用リッチメニュー画像（2500×843px）を生成し「Save to Drive」でDriveに保存。

---

## 主要フロー

### 授業実施フロー（管理者 – LIFF管理画面）

```
admin_liff.html「授業管理」タブ
→ 科目選択 → 授業開始ボタン → adminStartSession()（全学生にLINE通知）
→ 問題入力 → 出題ボタン → adminBroadcast()（全学生にLINE配信）
→ 出題停止ボタン → pauseQuestionDelivery()（全学生にLINE通知）
→ 授業終了ボタン → adminEndSession()（全学生にLINE通知）
```

### 学生回答フロー

```
LINEに回答テキスト送信
→ handleStudentAnswer()
→ scoreAnswerWithGPT()  … GPT-4o-miniで正確性0〜100点
→ calculateSpeedMultiplier()  … 出題からの経過秒で乗数算出
→ 集中度スコア = 正確性 × 速度乗数
→ saveAnswer()  … 回答データシートに保存
→ 学生にフィードバック返信
   例: 正確性: 80/100 👍  速度: 45秒 🏃 速い ×1.0  集中度: 80/100
```

### リッチメニュー管理フロー

```
初回セットアップ:
  createAndSetRichMenu()        ← 学生用（デフォルト、全ユーザー）
  createAndSetAdminRichMenu()   ← 管理者用（ADMIN_USER_IDにリンク）

ブロック解除時（自動）:
  follow event → getAdminRichMenuIdFromList() → setRichMenuForAdmin()
```

---

## 環境変数・設定値

```javascript
// gas_main.js.gs の CONFIG 定数
const CONFIG = {
  LINE_CHANNEL_ACCESS_TOKEN: '...',
  OPENAI_API_KEY: 'sk-proj-...',
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

// PropertiesService で管理（サーバーサイド状態）
ACTIVE_SESSION_ID      // 進行中セッションID（セッション中のみ存在）
ACTIVE_SUBJECT         // 進行中科目名
ACTIVE_SESSION_NUMBER  // 進行中授業回数
SESSION_START_TIME     // セッション開始エポックms
CURRENT_QUESTION_ID    // 出題中問題ID
CURRENT_QUESTION_TEXT  // 出題中問題文
CURRENT_MODEL_ANSWER   // 出題中模範解答
QUESTION_SENT_TIME     // 出題時刻エポックms
DELIVERY_PAUSED        // 配信停止フラグ ('true' or なし)
ACTIVE_GRADE           // アクティブ学年 (例: '4')
ACTIVE_SEMESTER        // アクティブ学期 ('spring' or 'fall')
```

---

## 開発時の注意点

1. **GASデプロイはDeploy IDを固定** — `clasp deploy -i <Deploy ID>` を使うこと。`-i` を省略すると新しいDeploy IDが生成され、LINE Webhook URLが変わる
2. **GASファイルは .gitignore 対象** — `gas_main.js.js` / `gas_richmenu.js.js` はgit管理外。変更はclaspのみで反映
3. **GASコールドスタート対策** — 初期化は必ず `getInitData()` 1回で行う。並列fetchは直列実行になりタイムアウトの原因になる
4. **followイベントはhandleEventの先頭で処理** — `event.type !== 'message'` の前に書くこと
5. **管理者コマンドはLINE User IDで判定** — `userId === CONFIG.ADMIN_USER_ID`
6. **科目マスタのフィルタは ACTIVE_GRADE + ACTIVE_SEMESTER** — `getSubjectMaster()` / `getInitData()` 参照
7. **LIFFキャッシュ** — LINE設定 → ストレージ → キャッシュ消去 で古いHTMLが表示される問題を解消できる
8. **ダッシュボードフィルタはlocalStorage** — `FILTER_KEY = 'dashboardFilter'` で永続化。初回はactiveSemesterを自動適用

---

## 未完了・今後の作業

- [ ] 学生用リッチメニュー画像を新規生成・更新
  - `openRichMenuGenerator()` → Save to Drive → `uploadRichMenuImage()` のFile IDを更新
- [ ] 学生ダッシュボード（index.html）の集中度スコア表示機能実装
- [ ] 科目マスタ追加・編集UIをadmin_liffに追加

---

## 更新履歴

| 日付 | 内容 |
|---|---|
| 2026/04/24 | admin_liff.html のHTMLタグバグ修正（セメスターモーダル） |
| 2026/04/25 | followイベント処理追加（ブロック解除後に管理者用リッチメニュー再設定） |
| 2026/04/25 | `getAdminRichMenuIdFromList()` / `saveStudentRichMenuImageFromDataUrl()` / `openRichMenuGenerator()` 追加 |
| 2026/05/03 | 初期化を `getInitData()` 一括APIに統合（GASコールドスタート3回→1回） |
| 2026/05/03 | 採点を速度乗数方式に変更: 集中度 = 正確性 × 速度乗数（0.3〜1.0） |
| 2026/05/03 | GPT採点プロンプト修正: 正確性のみ0〜100点、完全正解=100点 |
| 2026/05/03 | ダッシュボードフィルタをlocalStorageで永続化・アクティブセメスター自動適用 |
| 2026/05/03 | gas_richmenu.js.gsの未使用関数削除（251→182行） |
| 2026/05/03 | CLAUDE.md全面更新 |
| 2026/05/03 | LINEコマンド（`[授業開始]`/`[出題]`/`[授業終了]`）削除 — 操作はLIFF管理画面に統一 |
