# CLAUDE.md — 授業のオトモ システム概要

> LINE × AI 歯学部授業集中度モニタリングシステム  
> Claude Codeでの開発・保守向けドキュメント

---

## サービス概要

歯学部の授業中に**LINEを使って学生の集中度をリアルタイム計測**するシステム。  
先生がLINEまたは管理画面（LIFF）で問題を出題し、学生が回答 → GPT-4o-miniが採点 → 集中度スコアを自動計算・蓄積。

**集中度スコア = 正確性スコア（GPT採点: 0〜100）× 速度乗数（0.1〜1.0）**

速度乗数の考え方: 授業をその場で聞いていれば即答できるはずなので、遅い回答は検索や見直しを疑う。
- 60秒以内: ×1.0（ペナルティなし）
- 60〜180秒: 線形減少（×0.75 → ×0.08 ※clampで0.1に）
- 180秒以降: ×0.1（最低保証 — 正解していれば必ず点が残る）
- 実装: `Math.max(0.1, (180 - sec) / 120)`

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
  admin_liff.html … 管理者ダッシュボード（授業管理・学生ダッシュボード・登録管理）
  index.html      … 学生マイページ（集中度・直近授業確認）← リッチメニューの行き先
  demo.html       … デモ画面（現在は未使用・デフォルト動線なし）
```

---

## 固有ID・URL一覧

### LINE

| 項目 | 値 |
|---|---|
| Channel ID | `2008587142` |
| Channel Name | 授業のオトモ |
| Admin User ID | `Ubf96bf52b57d4e329a5bcf4ce509c6be` |
| Admin LIFF ID | `2009739219-9qVGb0Xm` |
| 学生マイページ LIFF ID | `2009739219-dSnPUVFj`（index.html） |
| デモ LIFF ID | `2009739219-N7Pi2ywn`（demo.html、現在は未使用） |

### Google Apps Script

| 項目 | 値 |
|---|---|
| Project ID | `1dfHpjEjSigxTJbSnuER99IKDBROzZ-ZXJ2XPiNJMfDsUZ9idejL35Cq8` |
| Web App URL（Webhook & API） | `https://script.google.com/macros/s/AKfycbwx7XFQHALQSD7UMBsVXKdxqgH9yktleZOjV3HN-qStmlod8ifpNw6_FazO4-jI6mWiug/exec` |
| Deploy ID（`clasp deploy -i` に指定） | `AKfycbwx7XFQHALQSD7UMBsVXKdxqgH9yktleZOjV3HN-qStmlod8ifpNw6_FazO4-jI6mWiug` |
| 現在のバージョン | v288（2026/05/22） |

### Google Sheets（Spreadsheet ID: `15UpJAol2SayyiEQDyOdKYX02eQQ4pMH4gq4SssJrYT4`）

| シート名 | カラム |
|---|---|
| 学生マスタ | userID, 表示名, アイコンURL, 登録日時 |
| 授業セッション | セッションID, 科目名, 授業回数, 開始時刻, 終了時刻, ステータス, [pause状態, pause時刻] |
| 問題マスタ | 問題ID, セッションID, 科目名, 授業回数, 経過分, 問題文, 模範解答, 出題時刻 |
| 回答データ | 回答ID, 学生ID, セッションID, 問題ID, 科目名, 授業回数, 経過分, 回答テキスト, 正確性スコア, 回答時間(秒), 集中度スコア, 回答時刻 |
| 科目マスタ | 科目名, 曜日, 学年, 学期（16科目, 学年4, spring） |
| 試験日程 | 試験ID, 科目名, 試験日, 復習標準時間（分）, 作成日時, 開始時間（HH:mm文字列）, 復習必要コマ数 |
| 学習計画 | 計画ID, userId, 試験ID, 科目名, セッションID, 授業回数, タイプ, 予定日, 所要時間（分）, 完了状態, 完了日時, リプラン回数 |
| 小テスト | quizId, 科目名, テスト名, 範囲, 日程（YYYY-MM-DD）, 作成日時 |

### Google Drive

| 項目 | 値 |
|---|---|
| ルートフォルダ（授業のOtomo） | `1PEBapWgq6JwpSMElYjqoxn2PTnRp189_` |
| 4年生フォルダ | `1bnc5GnMVNuscnbuGI-W3NuFfJsKuvX4X` |
| 3年生フォルダ | `1JMv7VD2kVkn3Symdsths_7KgGmrqLhs3` |
| 2年生フォルダ | `1PRJXyN5bLvxsWyugjotuEz11eXu4wxJ_` |
| prototypeフォルダ（アーカイブ） | `1KPvrYlWBvmiAxfblAwtIBpqK8D2h7kBH` |
| 管理者用リッチメニュー画像 File ID（4年生） | `1UOmAB9M4slNxrjTRWWIn1ZsqEhVEAOeM`（richmenu_admin.png） |
| 学生用リッチメニュー画像 File ID（4年生） | `1WEpVdG21Ss4Pp9zQQRpLb2PHA1rjlS8b`（mypage_full_blue_final.png） |

### Google Sheets（学年別）

| 学年 | Spreadsheet ID | 状態 |
|---|---|---|
| 4年生 | `15UpJAol2SayyiEQDyOdKYX02eQQ4pMH4gq4SssJrYT4` | 稼働中 |
| 3年生 | `13UPbC8CeT2Chwzf_9-dxviVImkm-EDxKto4saeOHm9o` | 準備中（空） |
| 2年生 | `1_TD4l9nrfSNo1AVHnjvM-GtoTIZzS_Vm2mZW3Jn0528` | 準備中（空・学習計画実装後に使用） |

### GitHub / LIFF

| 項目 | 値 |
|---|---|
| Repository | `otomodentist/dental-liff` |
| GitHub Pages URL | `https://otomodentist.github.io/dental-liff/` |
| 4年生 Admin LIFF URL | `https://liff.line.me/2009739219-9qVGb0Xm` |
| 3年生 Admin LIFF URL | 未作成（LIFF endpoint: `admin_liff.html?grade=3`） |
| 2年生 Admin LIFF URL | 未作成（LIFF endpoint: `admin_liff.html?grade=2`） |

---

## GASファイル構成

### `gas_main.js.gs`

**Webhook & イベント処理**
- `doPost(e)` — LINE Webhookエントリポイント
- `handleEvent(event)` — followイベント（管理者: リッチメニュー再設定 / 学生: 自動登録）・messageイベントのルーティング（管理者メッセージは無視）
- `handleStudentAnswer(userId, text, replyToken, timestamp)` — GPT採点 → 集中度計算 → 保存 → 返信

**採点**
- `scoreAnswerWithGPT(answer, modelAnswer, question)` — GPT-4o-miniで正確性0〜100点採点。キーワード一致ではなく意味の正確性で判定。逆のこと・矛盾は0〜10点、似た言葉でも意味が異なれば0〜20点
- `calculateSpeedMultiplier(responseTimeSec)` — 速度乗数算出（60秒以内=×1.0、60〜180秒で線形減少、180秒以降=×0.1最低保証）
- `geoMeanScore(scores)` — 集中度スコア配列の幾何平均を返す。一度でも低い回があると大きく引き下がり「維持」を評価する

**セッション管理**
- `adminStartSession(subjectName, sessionNumber)` — 授業開始（セッション作成 + 全員LINE通知）
- `adminEndSession()` — 授業終了（セッション終了 + 全員LINE通知）
- `adminBroadcast(question, modelAnswer)` — 出題・全員配信
- `pauseQuestionDelivery(sessionId)` — 出題一時停止（全員にLINE通知）
- `resumeQuestionDelivery(sessionId)` — 出題再開

**LIFF用 Web API (`doGet`)**
- `getInitData()` — 一括初期化API（activeSession + semesterData + subjects）。GASコールドスタートを1回に削減
- `getUserInitData(userId)` — 学生マイページ初期化API（activeSession + dashboard + nickname + billingStatus + todayItems/tomorrowItems）
- `getActiveSession()` — アクティブセッション情報取得
- `getSubjectMaster()` — アクティブ学年・学期の科目一覧
- `getActiveSemester()` / `setActiveSemester(grade, semester)` — アクティブクール取得・設定
- `getAdminStudentList()` — 学生一覧
- `getAdminStudentListWithBilling()` — 課金ステータス込み学生一覧（登録管理タブ用）
- `getStudentsByGradeAndSemester(grade, semester)` — 学年・学期フィルタ学生一覧（billingStatus付き、ダッシュボードタブ用）
- `getStudentSessions(userId)` — 学生が参加したセッション一覧（sustainScore・latestAnswerAt付き、直近活動順）
- `queryBySessionAndStudent(sessionId, userId)` — セッション×学生の回答詳細（問題文・模範解答付き）
- `getLatestSessionData(userId)` — 直近終了セッションのサマリ（sustainScore付き）
- `getDashboardData(userId)` — 科目・セッション別集計（学生LIFF用、sustainScore・latestAnswerAt付き・科目を直近活動順でソート）
- `registerFreeSemester(userId)` — 未登録ユーザーを無償で登録（`processStripePayment` 経由で billingStatus='契約中' に設定）。index.html からの自動登録に使用
- `broadcastToRegistered(message)` — 登録済み学生全員へ一斉メッセージ送信（`getPaidStudentIds()` 対象）
- `getExamSchedule()` — 試験日程一覧（startTime・requiredSessions含む）
- `addExamDate(subjectName, examDate, reviewMinutes, startTime, requiredSessions)` — 試験日程追加
- `updateExamDate(examId, examDate, reviewMinutes, startTime, requiredSessions)` — 試験日程更新
- `deleteExamDate(examId)` — 試験日程削除
- `generateStudyPlan(userId, examId, dailyAvailableHours)` — 学習計画生成（requiredSessionsで対象コマ数を制限）
- `getStudyPlan(userId)` — 学習計画一覧取得
- `getTodayStudyItems(userId)` — 今日・明日の学習予定（todayItems, tomorrowItems, pendingCount）
- `markStudyComplete(userId, planId)` — 学習完了記録
- `replanStudy(userId, dailyAvailableHours)` — 全科目の未完了分を今日から再スケジュール
- `replanStudyForExam(userId, examId, dailyAvailableHours)` — 特定科目の未完了分を今日から再スケジュール
- `getStudyPlanInitData(userId)` — 学習計画ビュー初期化（exams・plan・progressBlocks・attendedBySubject）
- `getQuizList()` — 小テスト一覧（日程が今日以降のもの、日程昇順）
- `addQuiz(subjectName, quizName, scope, examDate)` — 小テスト追加（シートなければ作成）→ 課金済み学生にLINE通知
- `updateQuiz(quizId, ...)` — 小テスト更新
- `deleteQuiz(quizId)` — 小テスト削除
- `getQuestionRanking(questionId)` — 出題中問題のランキング（回答済み降順 + 未回答者をグレーアウト用フィールドで付加）
- `getSessionRanking(sessionId)` — セッション通算ランキング（同上）
- `getUserSessionGraph(sessionId, targetUserId)` — セッション内回答タイムライン（questionText・modelAnswer・answerText含む、問題マスタをjoin）
- `setUserPref(userId, key, value)` / `getUserPref_(userId, key, default)` — PropertiesServiceでユーザー設定を保存（`PREF_{key}_{userId}`）
- `deleteStudentData(studentName)` — 学生データ完全削除（回答データ・学習計画・学生マスタ行を削除。試験日程・小テストはクラス共通のため削除しない）
- `getScheduledSessionStart_()` — コマ定刻に基づく授業開始時刻を返す（内部関数）

**スプレッドシート操作**
- `saveAnswer(...)` — 回答データ保存
- `ensureStudentRegistered(userId)` — 未登録学生の自動登録
- `getPaidStudentIds()` — 課金有効・管理者承認の学生IDリスト取得

**LINE APIヘルパー**
- `replyMessage(replyToken, text)` — 返信
- `multicastMessage(userIds, text)` — 最大500件ずつ分割してMulticast送信
- `getLineProfile(userId)` — LINEプロフィール取得

**授業セッション自動終了**
- 授業開始から90分後に自動終了（`getScheduledSessionStart_()` が返す定時刻ベース）
- コマ定刻: 1コマ8:40 / 2コマ10:25 / 3コマ12:55 / 4コマ14:40

**朝のリマインダー（GASトリガー）**
- `sendMorningReminders()` — 毎朝7時に当日の学習計画をLINE通知（GASタイムトリガーから実行）
- `setupMorningReminderTrigger()` — 上記トリガーを登録（手動実行）

**初回セットアップ（手動実行）**
- `setupSpreadsheet()` — 全シート作成・ヘッダー設定
- `setupSubjectMaster()` — 科目マスタ初期データ投入
- `broadcastRegistrationMessage()` — 学生登録案内ブロードキャスト
- `registerAllFollowers()` — フォロワー全員を学生マスタに一括登録

### `gas_richmenu.js.gs`（手動実行用）

- `createAndSetRichMenu()` — 学生用リッチメニュー作成・画像アップ・デフォルト設定（index.html行き。デモ廃止済み）
- `createAndSetAdminRichMenu()` — 管理者用リッチメニュー作成・設定
- `getAdminRichMenuIdFromList()` — LINE APIから `name:'admin_richmenu'` のIDを検索（followイベントから呼び出し）
- `setRichMenuForAdmin(adminRichMenuId)` — 管理者ユーザーにリッチメニューをリンク
- `setRichMenuForPaidUser(userId)` — 課金済みユーザーにindex.html行きリッチメニューを個別設定
- `getOrCreatePaidStudentRichMenu()` — `name:'paid_student_richmenu'` を取得または作成（index.html行き）
- `setUserRichMenu(userId, richMenuId)` — 特定ユーザーにリッチメニューをリンク
- `deleteUserRichMenu(userId)` — 特定ユーザーの個別リッチメニュー設定を削除（デフォルトに戻す）
- `refreshPaidStudentRichMenu()` — 既存 `paid_student_richmenu` を削除・再作成し、課金済み全学生に再リンク（手動実行）
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
  createAndSetRichMenu()        ← 学生用デフォルト（index.html行き、全ユーザー）
  createAndSetAdminRichMenu()   ← 管理者用（ADMIN_USER_IDにリンク）

ブロック解除時（自動）:
  follow event → getAdminRichMenuIdFromList() → setRichMenuForAdmin()

初回マイページ開封時（自動）:
  index.html init → billingStatus未登録 → registerFreeSemester() → billingStatus='契約中'
  → setRichMenuForPaidUser()（paid_student_richmenu: index.html行き）
```

---

## 環境変数・設定値

```javascript
// gas_main.js.gs の CONFIG 定数
const CONFIG = {
  LINE_CHANNEL_ACCESS_TOKEN: '...',
  FREE_SEMESTER_MODE: true, // true=春学期無料提供 / false=Stripe決済必須に戻す（秋学期以降）
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
const LIFF_DASHBOARD_URL = 'https://liff.line.me/2009739219-dSnPUVFj'; // index.html
const LIFF_DEMO_URL      = 'https://liff.line.me/2009739219-N7Pi2ywn'; // demo.html（未使用）
const LIFF_ADMIN_URL     = 'https://liff.line.me/2009739219-9qVGb0Xm';
const ADMIN_RICHMENU_FOLDER_ID = '1PEBapWgq6JwpSMElYjqoxn2PTnRp189_';

// PropertiesService で管理（サーバーサイド状態）
ACTIVE_SESSION_ID      // 進行中セッションID（セッション中のみ存在）
ACTIVE_SUBJECT         // 進行中科目名
ACTIVE_SESSION_NUMBER  // 進行中授業回数
SESSION_START_TIME     // コマ定刻開始時刻エポックms（1コマ8:40・2コマ10:25・3コマ12:55・4コマ14:40、コマ外はボタン押下時刻）
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
2. **HTML変更は clasp push + git push の両方が必要** — `admin_liff.html` / `index.html` / `demo.html` はGitHub Pagesから配信される。clasp pushだけでは反映されない。`gas_main.js.js` / `gas_richmenu.js.js` はclaspのみでOK（.gitignore対象）
3. **GASコールドスタート対策** — 初期化は必ず `getInitData()` 1回で行う。並列fetchは直列実行になりタイムアウトの原因になる
4. **followイベントはhandleEventの先頭で処理** — `event.type !== 'message'` の前に書くこと
5. **管理者コマンドはLINE User IDで判定** — `userId === CONFIG.ADMIN_USER_ID`
6. **科目マスタのフィルタは ACTIVE_GRADE + ACTIVE_SEMESTER** — `getSubjectMaster()` / `getInitData()` 参照
7. **LIFFキャッシュ** — LINE設定 → ストレージ → キャッシュ消去 で古いHTMLが表示される問題を解消できる
8. **ダッシュボードフィルタはlocalStorage** — `FILTER_KEY = 'dashboardFilter'` で永続化。初回はactiveSemesterを自動適用
9. **Sheets の時刻自動変換** — `appendRow` / `setValue` で "HH:mm" 文字列を書き込むと Sheets がDate型に自動変換する。書き込み前に `setNumberFormat('@STRING@')` を適用すること。読み取り時は `r[n] instanceof Date ? Utilities.formatDate(r[n], 'Asia/Tokyo', 'HH:mm') : String(r[n])` で文字列に戻す
10. **index.html の主要localStorageキー** — `hideAnswerInRanking`（ランキング回答非表示）、`dashboardFilter`（ダッシュボードフィルタ）
11. **学習計画タブはlazy-load** — `switchMainTab('plan')` で初めて `loadPlanTabData()` を呼び出す。`planTabData = { exams, progressBlocks, quizzes }` にキャッシュ。`openStudyPlanView()` 後は exams/progressBlocks のみ更新
12. **HTMLテンプレート文字列の深いインデント** — `admin_liff.html` / `index.html` のテンプレート文字列は数千文字のインデントが入ることがあり、Editツールの完全一致が失敗する場合は Python スクリプトで `content.replace()` を使うこと
13. **ランキングポーリング仕様** — 問題配信後に20秒×9回（3分間）自動更新。admin側: `startAdminRankingPoll()` / index側: `scheduleLiveRefreshes()`。配信成功の瞬間にフォームの問題文・模範解答を即時描画し、GAS応答後に回答者リストで上書き
14. **ランキング未回答者フィールド** — `getQuestionRanking`/`getSessionRanking` が返す `item.answered === false` で未回答者を判定。`item.hideAnswer` でユーザーの非表示設定を判定。未回答者はGASの `getPaidStudentIds()` 対象者のみ（`FREE_SEMESTER_MODE=true` 時は全登録学生）
15. **試験日程・小テストはクラス共通データ** — `deleteStudentData()` は個人データのみ削除する。試験日程シート・小テストシートは触らないこと
16. **FREE_SEMESTER_MODE** — `true` の間は `isStudentPaid()` が常に `true` を返し、`getPaidStudentIds()` が全登録学生（userId が `U` 始まり）を返す。`customer.subscription.deleted` Webhook もスキップされる。秋学期以降に `false` に変えてデプロイするだけで Stripe 決済必須に戻る
17. **Stripe連携の保存仕様** — 決済リンク: `https://buy.stripe.com/8x25kCgP2gul9KigcHfbq03`。Webhook: `checkout.session.completed` → `processStripePayment()`、`customer.subscription.deleted` → `cancelSubscription()`。Stripe Secret / Webhook Secret は PropertiesService 管理。再有効化は `FREE_SEMESTER_MODE: false` に変更してデプロイするだけ
18. **既存Stripeトライアル登録者（3名）** — 2026/05/21 に `cancelAllTrialSubscriptions()` で Stripe サブスクをキャンセル済み。スプレッドシートのステータスは `契約中` のまま（`FREE_SEMESTER_MODE` ガードにより解約メッセージ・ステータス変更は発生しない）
19. **自動登録フロー（FREE_SEMESTER_MODE）** — 未登録ユーザーが index.html を開くと、`getUserInitData` で `billingStatus` が空であることを検知し、非同期で `registerFreeSemester` を呼び出す。成功後 `myBillingStatus='契約中'` にして再レンダリング。`setRichMenuForPaidUser` も自動実行される（`processStripePayment` 内）
20. **登録者一斉送信** — admin_liff.html「登録管理」タブ上部の textarea から送信。GAS `broadcastToRegistered` アクションが `getPaidStudentIds()` 全員（管理者除く）に `multicastMessage` する

---

## 未完了・今後の作業

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
| 2026/05/09 | admin_liff.html: ダッシュボードタブ名変更・課金ステータス未登録を赤表示（v47） |
| 2026/05/09 | index.html・demo.html: 試験対策を横スクロール棒グラフ表示に変更・バータップで科目別編集画面へ遷移（v49） |
| 2026/05/09 | index.html: Today/Tomorrow 学習スケジュールを科目・コマ番号・所要時間でまとめ表示（v48） |
| 2026/05/09 | GAS: replanStudyForExam 追加・getTodayStudyItems に tomorrowItems 追加・getStudentsByGradeAndSemester に billingStatus 追加（v47〜49） |
| 2026/05/11 | 試験日程のコマ番号表記を開始時間（HH:mm文字列）に変更。admin_liff・index・demo 全対応（v50〜61） |
| 2026/05/11 | GAS: Sheets時刻自動変換バグ修正（getExamSchedule/addExamDate/updateExamDate） |
| 2026/05/11 | admin_liff.html: 試験登録フォームのレイアウト整理（試験日+開始時間・復習時間+復習コマ数を横並び）・全入力欄中央揃え |
| 2026/05/11 | demo.html: 表示科目を3科目に拡充・試験時間割グリッド追加・不要CSS削除 |
| 2026/05/11 | GAS: GPT採点プロンプト厳格化（逆・矛盾=0〜10点、意味の正確性で判定）（v62） |
| 2026/05/11 | GAS: `geoMeanScore()` 追加・全スコアを算術平均→幾何平均（維持スコア）に変更（v63） |
| 2026/05/11 | index.html・admin_liff.html: `averageScore`/`avgScore` → `sustainScore`・ラベル「平均点」→「維持スコア」 |
| 2026/05/11 | index.html・admin_liff.html: SNSランキング機能追加（問題ごとのLIVEランキング・授業後セッションランキング）（v64〜65） |
| 2026/05/11 | GAS: `getQuestionRanking(questionId)` / `getSessionRanking(sessionId)` 追加、`adminBroadcast` が questionId を返すよう変更 |
| 2026/05/11 | GAS: `getActiveSession()` / `getInitData()` に currentQuestionId・currentQuestionText を追加 |
| 2026/05/11 | demo.html: LIVEランキングカード・セッションランキングを静的デモデータで追加（授業中を想定、未回答者も「未回答」表示）|
| 2026/05/15 | admin_liff.html: 問題配信フォームに問題文・模範解答クリアボタン追加、180秒クールダウン、フォームpadding整理（v120〜）|
| 2026/05/15 | GAS: `calculateSpeedMultiplier` を線形式に変更（60s以内=×1.0、60〜180sで線形減少、180s以降=×0.3固定）|
| 2026/05/15 | GAS: `getUserSessionGraph()` を問題マスタjoin方式に修正（questionText・modelAnswer・answerTextを返すように）|
| 2026/05/15 | index.html: スコア表記「回答」→「回答時間」、集中度＝正確性×速度 の計算式を表示 |
| 2026/05/15 | index.html: ランキング未回答ロック（回答完了後のみランキング・模範解答を表示）|
| 2026/05/15 | index.html: ランキング回答非表示設定（localStorage `hideAnswerInRanking`）、設定画面に「ランキング設定」セクション追加 |
| 2026/05/15 | index.html: 学習計画タブをlazy-load（`loadPlanTabData()`）、定期試験リスト・小テストリストを直接表示（旧exam-sectionボタンUI削除）|
| 2026/05/15 | GAS: 小テスト機能追加（`getQuizList`/`addQuiz`/`deleteQuiz`/`updateQuiz`、シート「小テスト」）。`addQuiz`時に課金済み学生へLINE通知 |
| 2026/05/15 | admin_liff.html: 試験タブに小テスト登録フォーム・一覧追加（`addQuiz()`/`deleteQuiz()`）|
| 2026/05/15 | admin_liff.html・index.html: 科目ヘッダー色 `#e8f2eb`→`#b8d9bd`、セッション行 white→`#f0f6f1`（アコーディオン視認性改善）|
| 2026/05/15 | index.html: 不要CSS削除（`.exam-btn`・`.exam-section`・関連クラス）（v129） |
| 2026/05/16 | GAS: `getInitData()` に `sessionStartTimeEpoch` を追加・90分超過チェックを追加（クライアント側自動終了を修正） |
| 2026/05/16 | GAS: `getQuestionRanking`/`getSessionRanking` に未回答者（`answered:false`）・`hideAnswer` フィールドを追加（課金済みのみ対象）|
| 2026/05/16 | GAS: `deleteStudentData()` のバグ修正 — クラス共通の試験日程・小テストを誤削除していた問題を解消 |
| 2026/05/16 | GAS: `setUserPref`/`getUserPref_` 追加（PropertiesServiceで `PREF_{key}_{userId}` 管理）|
| 2026/05/16 | GAS: `calculateSpeedMultiplier` の最低値を0→0.1に変更（正解でも0点表記が出る問題を解消）|
| 2026/05/16 | gas_richmenu.js.gs: `refreshPaidStudentRichMenu()` 追加 |
| 2026/05/16 | index.html: ランキングカード（LIVE・直近授業）を常時表示。未回答時・非表示設定時はランキング行を非表示にしてメッセージ表示 |
| 2026/05/16 | index.html: 未回答者をグレーアウト（`opacity:0.45`）表示・ランキング欄「—」・回答欄「未回答」 |
| 2026/05/16 | index.html: 各ランキングカードヘッダーに「設定」ボタンを追加（設定画面へ遷移）|
| 2026/05/16 | index.html: 設定→集中スコア画面への戻り時の bounce-back 競合を修正（`currentView` ガード）|
| 2026/05/16 | index.html: `scheduleLiveRefreshes()` を 60/120/180s 1発タイマー → 20s×9回 setInterval に変更 |
| 2026/05/16 | index.html: 「クラスランキング」→「直近授業ランキング」統一 |
| 2026/05/16 | admin_liff.html: 未回答者・非表示設定者をランキング行に4パターン表示（`buildAdminRankRowHTML` / `buildAdminSessionRankRowHTML`）|
| 2026/05/16 | admin_liff.html: `startAdminRankingPoll()` を 60/120/180s 1発タイマー → 20s×9回 setInterval に変更 |
| 2026/05/16 | admin_liff.html: 問題配信成功時に `adminRankingSection` を即時描画（フォームの問題文・模範解答を使用）し、`pollAdminRanking()` で更新 |
| 2026/05/16 | admin_liff.html: 配信不可ボタン文言に「学生が回答中です」追加・「5秒ごとに自動更新」表示削除 |
| 2026/05/16 | GAS: 不要関数 `deleteAokiData()` 削除（`deleteStudentData()` に統合済み）（v164）|
| 2026/05/21 | GAS: `FREE_SEMESTER_MODE` フラグ追加（`true`=春学期無償、`false`=Stripe決済必須）。Stripe連携コメントブロックで仕様保存（v260） |
| 2026/05/21 | GAS: `isStudentPaid()` / `getPaidStudentIds()` を `FREE_SEMESTER_MODE` 対応に更新（v260） |
| 2026/05/21 | GAS: `registerFreeSemester` doGetアクション追加（`processStripePayment` 経由で `契約中` に設定）（v261） |
| 2026/05/21 | GAS: `cancelAllTrialSubscriptions()` 追加・`customer.subscription.deleted` Webhookに `FREE_SEMESTER_MODE` ガード追加（v263） |
| 2026/05/21 | GAS: `handleStudentAnswer()` の未登録メッセージを無料モード対応に修正（Stripeリンクなし）（v260） |
| 2026/05/21 | GAS: `sendCancellationMessage()` をStripeリンクなし・再登録案内に変更（v264） |
| 2026/05/21 | GAS: `sendDecisionMessage()` を春学期無償案内に変更（v265） |
| 2026/05/21 | demo.html: 登録ボタン上に「🎁 春学期は無償で提供します。」追加、ボタン文言「決済登録なしで無料で利用を開始」に変更（v262） |
| 2026/05/21 | demo.html: 登録ボタン動作を Stripe → `registerFreeSemester` GAS呼び出しに変更、成功後 `index.html` へ遷移（v261） |
| 2026/05/21 | demo.html: 設定画面「契約内容」→「利用状況」・`管理者承認` 時「利用中（春学期無料）」表示（v261） |
| 2026/05/21 | index.html: キャンセルモーダルを「登録解除」表記に統一、「再度決済が必要」→「デモ画面から登録できます」に変更（v264） |
| 2026/05/22 | gas_richmenu.js.gs: デフォルトリッチメニューのリンク先を `LIFF_DEMO_URL`（demo.html）→ `LIFF_DASHBOARD_URL`（index.html）に変更。デモ画面廃止 |
| 2026/05/22 | index.html: 未登録ユーザーが index.html を開いた際に `registerFreeSemester` を自動呼び出し・マイページを開くだけで登録完了する仕様に変更 |
| 2026/05/22 | GAS: `sendSessionSustainScores()` の授業終了メッセージを「他のユーザーのランキングも確認できます」に変更 |
| 2026/05/22 | GAS: `broadcastToRegistered` doGetアクション追加（登録済み学生全員へ一斉メッセージ送信） |
| 2026/05/22 | GAS: 各メッセージ文言からデモ画面動線を削除（`sendCompletionMessage` / `sendCancellationMessage` / `sendDecisionMessage` / 未登録ユーザー返信） |
| 2026/05/22 | admin_liff.html: 登録管理タブに「登録者への一斉メッセージ」送信UIを追加（`sendBroadcastMessage()`） |
