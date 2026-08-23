# ADR-027: Firebase AI Logic（Agent Platform バックエンド）を採用する

**Date**: 2026-08-23
**Status**: Accepted

## 背景

`docs/hackathon/SUBMISSION_PLAN.md` Phase 2 として、AIコーチ（`lib/features/ai_coach/`）を
`ScriptedCoach`（キーワード一致の固定応答）から実際の Gemini 呼び出しに置き換える。
PDR-006 で「対話型AI × オープンデータ」への注力は決定済みで、本 ADR は実装方式の選定を記録する。

026 は #102（実施主体・出典リンク追加）が先に採番したため、本 ADR は 027 から始める。

## 決定

### 1. パッケージは `firebase_ai`、バックエンドは Agent Platform（旧 Vertex AI）

`firebase_ai` パッケージを採用し、バックエンドは `FirebaseAI.agentPlatform()` を使う。

Firebase Knowledge MCP で確認した結果、ドキュメント上の名称・API は以下のように変わっていた
（実装前提として誤りやすい点）:

- `FirebaseAI.vertexAI()` は非推奨。Vertex AI バックエンドは「Agent Platform Gemini API」に
  改称され、現行 API は `FirebaseAI.agentPlatform()`。既定 location は `us-central1` ではなく
  `global`
- 「Agent Platform」は Vertex AI Gemini API が改称されただけの名前で、Agent Engine /
  Vertex AI Agent Builder（エージェントランタイムのデプロイ）とは無関係
- モデルは `gemini-2.5-flash` 系が deprecated のため `gemini-3.7-flash` を使う
  （Function Calling 対応モデルは `gemini-3.7-flash` / `gemini-3.6-flash` / `gemini-3.5-flash` /
  `gemini-3.5-flash-lite` / `gemini-3.1-pro-preview`）

Gemini Developer API（無料枠あり）は選ばなかった。無料枠は Spark プラン限定で、本プロジェクトは
Blaze 済みのため Developer API を選んでも無料にはならず、選択の決め手にならない。

### 2. 実装は Chat であり Agent ではない

`model.startChat()` によるマルチターン会話を使う。Function Calling の関数本体は Flutter
アプリ内（`ChatController._executeTool`）で実行し、Gemini 側は「どの関数をどの引数で呼びたいか」
の構造化データを返すだけ。Gemini 側が何かを実行するランタイムは存在しない。

### 3. サーバは一切立てない

Flutter Web（Firebase Hosting = 静的配信）から `firebase_ai` クライアント SDK が Gemini を直接
呼ぶだけの構成で、Cloud Run も Cloud Functions も無い。常時稼働コストはゼロで、リクエストが
0 なら課金も 0 の完全従量課金（Blaze プラン自体に固定費は無い）。歯止めは既存のログインゲート
（`coach_chat_panel.dart`。Google サインイン必須）と、Function Calling ループの最大3ラウンド
上限。Firebase App Check の導入は見送り、Issue 化した（→ #103 相当、スコープ外）。

### 4. Function Calling で公開するのは3関数のみ

`applyGoalTemplate` / `addEventFromCatalog` / `getInstitutionalLimit`。`moveEvent`
（イベント移動）は公開しない。eventId を AI に特定させるコストが高く、依存関係の連動移動は
既に D&D で見せられているため、Function Calling で二重に持つ必要が薄いと判断した。

`getInstitutionalLimit` は `open_data/data/institutional_limits.dart`（PDR-008 の B1、
制度上限）のみを参照する。`reference_baselines.dart`（A分類＝平均値）は関数として一切公開
しない。AI が平均値を発話しないための設計上のガード。

### 5. AI 呼び出し失敗時は `ScriptedCoach` にフォールバックする

`ChatController.send` は Gemini 呼び出しを try/catch し、例外時は既存の `ScriptedCoach`
（キーワード一致の固定応答）にフォールバックする。ハッカソン提出後、審査員がデモURLを操作する
期間中に API 障害でチャットが完全に沈黙する事態を避けるため。`ScriptedCoach` は削除せず残す。

### 6. ADR-024 が予告していた制約を引き継ぐ

ADR-024 の「④ AI 機能導入後の制約」で「AI 呼び出し部分だけエミュレータの境界をすり抜けて本番に
到達する」と記録されていた制約を、本実装で正式に受け入れる。`connectToEmulators()`
（`lib/core/firebase/emulator_config.dart`）は Auth / Firestore のみをエミュレータに向けており、
`firebase_ai` は対象外のため、`flutter run` のデバッグビルドでも AI コーチの発話は常に本番の
Gemini API に到達し、実際に課金される。ローカル開発中に AI コーチを試す際はこの点を踏まえること。

## 検討したが採らなかった案

- **Gemini Developer API**: Blaze プランでは無料枠が使えず、Vertex AI 系と比べて選ぶ理由が
  無かった（上記1）
- **`moveEvent` の Function Calling 公開**: 実装量に対して審査軸への寄与が小さいと判断し
  見送った（上記4）。必要になれば Issue で扱う

## 影響範囲

- `pubspec.yaml`: `firebase_ai` を追加
- 新規: `lib/features/ai_coach/domain/coach_turn.dart`,
  `lib/features/ai_coach/logic/coach_prompt.dart`, `lib/features/ai_coach/logic/coach_tools.dart`,
  `lib/features/ai_coach/data/coach_repository.dart`,
  `lib/features/ai_coach/data/gemini_coach_repository.dart`
- `lib/features/ai_coach/presentation/chat_controller.dart`: `ScriptedCoach` 直接呼び出しから
  Gemini 呼び出し + フォールバックの構成に変更。`ChatSendResult` を `GoalExpansionResult` 単体から
  `List<LifeEvent>` / `List<EventDependency>` 保持に一般化
- `lib/features/ai_coach/presentation/coach_chat_panel.dart`: `undoLast` の呼び出し引数を追随
- Firebase コンソール: AI Logic（Agent Platform バックエンド）を有効化
  （`firebasevertexai.googleapis.com`）
- CI・デプロイへの影響なし（`flutter build web --release` は無改修で動作する。ADR-024 と同じ）

## 関連

- `docs/pdr/PDR-006-ai-agent-open-data-pivot.md`（対話型AI採用の決定）
- `docs/pdr/PDR-008-hide-averages-show-institutional-limits.md`（B1/A分類の区別）
- `docs/adr/024-firebase-local-emulator.md`（本 ADR が引き継いだ制約の予告元）
- `docs/hackathon/SUBMISSION_PLAN.md` Phase 2
