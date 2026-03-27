# ライフプランアプリ - 開発ワークフローと自律実行ルール

## 1. プロジェクト概要

女性がキャリアとプライベートの両面からライフプランを考えるためのタイムラインアプリ。
詳細は `docs/PRD.md` を参照。

## 2. 自律実行ポリシー (Vibe Coding Policy)

### 2.1. 基本姿勢
- 途中で人間に質問や承認を求めず、Sub Agentを駆使して可能な限り自己解決すること。
- エラーが発生した場合も、ログを解析して修正ループを自律的に回すこと。
- ただし**設計ドキュメントの変更**は必ず `docs/audit_log.md` に理由を記録すること。

### 2.2. 監査ログ (Audit Log) の絶対義務
- すべての重要な意思決定は `docs/audit_log.md` に時系列で追記すること。
- 記録対象: アーキテクチャ判断、ファイル作成・削除、テスト失敗理由と修正内容、依存パッケージの追加。
- フォーマット:
  ```
  ## YYYY-MM-DD HH:MM - [カテゴリ] タイトル
  - **判断内容**: 何をしたか
  - **理由**: なぜそうしたか
  - **影響範囲**: どのファイルに影響するか
  ```

### 2.3. 2フェーズ実行モデル
- **Phase 1 (設計)**: PRD → アーキテクチャ設計 → テストシナリオ設計まで。ここで一旦停止し、人間のレビューを待つ。
- **Phase 2 (実装)**: 人間の承認後、TDD実装 → QA検証を自律実行する。
- 人間から「Phase 2を開始して」と指示があるまで、実装コードの生成に着手しないこと。

## 3. 技術スタック（確定事項 - 判断不要）

### フロントエンド (Flutter)
- **言語**: Dart 3.x
- **状態管理**: Riverpod v2 (`flutter_riverpod`, `riverpod_annotation`, `riverpod_generator`)
- **コード生成**: `build_runner`, `freezed`, `freezed_annotation`, `json_serializable`
- **ルーティング**: GoRouter (`go_router`)
- **テスト**: `flutter_test`, `mocktail`
- **画像圧縮**: `flutter_image_compress`

### バックエンド (Firebase)
- **認証**: Firebase Authentication（メール/パスワード）
- **DB**: Cloud Firestore（`asia-northeast1`）
- **ストレージ**: Cloud Storage for Firebase（`asia-northeast1`）
- **ホスティング**: Firebase Hosting（Web版）
- **Flutter SDK**: `firebase_core`, `firebase_auth`, `cloud_firestore`, `firebase_storage`

### 開発ツール
- **リント**: `flutter_lints` (デフォルト)
- **CI**: GitHub Actions
- **デプロイ**: Firebase CLI

## 4. 判断に迷ったときのデフォルト方針

以下は、設計・実装中に判断が必要になった場合のデフォルトルール。迷ったらこちらに従うこと。

| 判断ポイント | デフォルト方針 |
|---|---|
| Widgetの分割粒度 | 1ファイル200行を超えたら分割 |
| エラーハンドリング | `AsyncValue` の `loading` / `error` / `data` で3状態を必ず処理 |
| null安全性 | `required` パラメータを優先。Optionalは明示的に `?` と `??` で処理 |
| 命名規則 | Dart公式スタイルガイドに従う（lowerCamelCase / UpperCamelCase） |
| コメント | 公開API（public method/class）には必ずdartdocコメントを付ける |
| テストの粒度 | 1テストメソッド = 1アサーション を原則とする |
| 新規パッケージの追加 | pub.dev のLike数500以上、最終更新6ヶ月以内を目安とする |
| MVPスコープ外の機能 | 実装しない。TODOコメントを残して `audit_log.md` に記録する |

## 5. エージェント体制

### 5.1. ロール構成（3ロール + メイン）

| ロール | 定義ファイル | 責務 |
|---|---|---|
| **メインエージェント** (Project Manager) | _(Claude Code本体)_ | オーケストレーション、WBS管理、audit_log記録 |
| **Architect** | `.claude/agents/architect.md` | PRD・インフラ・ソフトウェア設計の策定と更新 |
| **Implementer** | `.claude/agents/implementer.md` | Flutter実装（TDD）、Firebase連携コード |
| **QA** | `.claude/agents/qa.md` | テストシナリオ設計、テスト実行、品質レポート |

### 5.2. ファイル所有権（ネガティブリスト方式）

各エージェントが**触ってはいけないファイル**を以下に定義する。

- **Architect**: `lib/` 配下、`test/` 配下のコード全般（実装コードに触らない）。技術選択時はADRを作成すること
- **Implementer**: `docs/PRD.md`, `docs/SPEC.md`, `docs/FIREBASE_ARCHITECTURE.md`, `docs/SOFTWARE_ARCHITECTURE.md`, `docs/adr/`（設計ドキュメントを書き換えない）
- **QA**: `lib/` 配下のプロダクトコード（テストコードのみ触る。プロダクトコードの修正はImplementerに依頼）

### 5.3. エージェント呼び出しの原則

- メインエージェントは、タスクの種類に応じて適切なSub Agentに委譲する。
- Sub Agentに渡すプロンプトには、必ず「参照すべきドキュメントのパス」と「成果物の出力先」を明示する。
- Sub Agentの作業完了後、メインエージェントは成果物を確認し、問題があれば再実行を指示する。

## 6. ドキュメント体系

```
docs/
├── PRD.md                      # ビジョン・ターゲット・フェーズ別機能一覧（スリム版）
├── SPEC.md                     # ビジネスルール仕様（カテゴリ定義・制約ルール・テンプレート定義）
├── adr/                        # Architecture Decision Records（なぜその設計にしたか）
├── FIREBASE_ARCHITECTURE.md    # Firebaseインフラ・Firestoreスキーマ設計
├── SOFTWARE_ARCHITECTURE.md    # ソフトウェアアーキテクチャ設計（レイヤー構成・Riverpod規約）
├── TESTING_POLICY.md           # テスト方針
├── feature_registry.md         # 機能IDとコード/テストパスの対応表
└── audit_log.md                # 監査ログ（全行動の記録）
```

### ドキュメントと情報源の対応

| 「何を知りたいか」 | 参照先 |
|---|---|
| なぜその設計か | `docs/adr/` |
| 何がビジネスルールか | `docs/SPEC.md` |
| 何の機能があるか（概要） | `docs/PRD.md` |
| 実装の詳細・仕様 | コード（ソース・テスト）を正とする |
| どう使うか | （将来）`docs/USER_MANUAL.md` |

## 7. ディレクトリ構造（実装時の規約）

```
lib/
├── main.dart
├── core/
│   ├── router/                 # GoRouter設定
│   ├── theme/                  # アプリテーマ定義
│   └── constants/              # 定数定義
└── features/
    ├── timeline/
    │   ├── data/               # Repository
    │   ├── domain/             # データモデル (freezed)
    │   ├── logic/              # Riverpod Provider
    │   └── presentation/       # Widget + 画面
    ├── profile/
    │   ├── data/
    │   ├── domain/
    │   ├── logic/
    │   └── presentation/
    └── auth/                   # Phase 3
        ├── data/
        ├── domain/
        ├── logic/
        └── presentation/

test/
└── features/                   # lib/features/ と対称構造
    ├── timeline/
    │   ├── data/
    │   ├── logic/
    │   └── presentation/
    └── profile/
```
## 8. Git運用ルール

- 作業ブランチ: `dev`（Claude Codeは常にこのブランチで作業する）
- ブランチの作成・切替・マージは行わない（人間が管理する）
- commitは論理的な作業単位ごとに行う（1機能 or 1修正 = 1 commit）
- commitメッセージ規約:
  - `feat: タイムラインにイベント追加機能を実装`
  - `test: TimelineEventsProviderのユニットテストを追加`
  - `docs: SOFTWARE_ARCHITECTURE.md を更新`
  - `fix: イベント削除時の状態遷移バグを修正`
- `main` ブランチへのpush・mergeは禁止（人間のみが実行する）

## 9. Feature Registry の維持義務

- Implementer Agent は機能の実装完了時に docs/feature_registry.md を更新すること。
  - 状態を 🟢 RELEASED に変更
  - 実装ファイルパスとテストファイルパスを記入
- Architect Agent は設計変更時に、影響を受ける既存機能の状態を 🔵 MODIFY に変更し、
  備考に変更内容を記載すること。
- feature_registry.md は PRD.md と常に整合していること。
  PRD に存在する機能が registry に存在しない場合はエラーとする。