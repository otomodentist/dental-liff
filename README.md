# 授業のオトモ — 歯学部授業集中度モニタリングシステム

LINE × AI を使って学生の授業集中度をリアルタイム計測するシステム。  
先生が問題を出題し、学生はLINEで回答するだけ。GPT-4o-miniが即座に採点し、集中度スコアとクラスランキングをその場で表示する。

## システム構成

```
[LINE Bot（授業のオトモ）]
        ↓ Webhook
[Google Apps Script（GAS）]
  gas_main.js.gs     … Webhook受信・AI採点・API・データ管理
  gas_richmenu.js.gs … リッチメニュー管理
        ↓ OpenAI API（採点）   ↓ Google Sheets（データ永続化）
[GPT-4o-mini]               [otomo_data]
        ↓
[LIFF（GitHub Pages）]
  admin_liff.html    … 学年管理者ダッシュボード
  index.html         … 学生マイページ
  question_bank.html … 教員ポータル（科目担当教員向け）
```

## 主な機能

### リアルタイム出題 & AI採点
- 管理画面または教員ポータルから問題を出題 → 学生がLINEで回答
- GPT-4o-miniが「意味の正確さ」で0〜100点採点（キーワード一致ではなく理解度で判定）
- 複数回答・OR表記・漢字誤字許容など柔軟な採点ルール

### 集中度スコア
- **集中度スコア = 正確性スコア × 速度乗数**（0.1〜1.0）
- 速度乗数：60秒以内=×1.0、180秒以降=×0.1（線形減少）
- 一コマの集中度は幾何平均（維持スコア）で評価

### LIVEクラスランキング
- 出題中はリアルタイムで順位更新
- 未回答者も表示、授業後はコマ通じた維持スコアでセッションランキング

### 教員ポータル（question_bank.html）
- 科目ごとのパスワード認証
- 問題バンク：授業前に問題・模範解答を登録し、授業中に1タップで出題
- 授業開始・終了・出題操作
- 出題統計：問題ごとの平均スコア・高得点率・回答数の確認
- 小テスト管理
- 「実習：〇〇」形式の関連科目を同一ログインで管理可能

### 保護者機能
- 学生が保護者にシェアURLを送信して登録（最大3名）
- 通知設定：回答ごと / コマ終了時サマリー / なし
- 保護者はLINEから子どもの学習状況・スコアを閲覧可能

### 管理画面（学年管理者）
- 学生一覧・課金ステータス・参加状況の確認
- 科目・学年・学期の管理
- 登録者への一斉メッセージ配信
- 学年管理者（サブ管理者）への権限付与

### AI試験対策プランナー *(アップデート予定)*
- 試験日・科目を登録すると復習スケジュールを自動生成
- 毎朝LINEで今日の学習タスクを通知
- 進捗管理・リプラン機能

## ファイル構成

| ファイル | 内容 |
|---|---|
| `admin_liff.html` | 学年管理者向けLIFF（授業管理・学生管理・試験日程） |
| `index.html` | 学生向けLIFF（集中度ダッシュボード・ランキング・保護者設定） |
| `question_bank.html` | 教員ポータル（問題バンク・出題・統計） |
| `gas_main.js.js` | GASメイン処理（gitignore対象） |
| `gas_richmenu.js.js` | リッチメニュー管理（gitignore対象） |
| `service_spec.md` | サービス仕様書 |

## LIFF URL

| 用途 | URL |
|---|---|
| 学年管理者パネル | `https://liff.line.me/2009739219-9qVGb0Xm` |
| 学生マイページ | `https://otomodentist.github.io/dental-liff/` |
| 教員ポータル | `https://otomodentist.github.io/dental-liff/question_bank.html` |

## デプロイ

```bash
# GASへプッシュ（APIキー等を含むためgitignore対象）
clasp push
clasp deploy -i <Deploy ID> -d "vXXX: 変更内容"

# GitHub Pagesへプッシュ（LIFF HTML自動更新）
git push origin main
```
