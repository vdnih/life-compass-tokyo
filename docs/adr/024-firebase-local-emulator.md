# ADR-024: ローカル開発を Firebase Local Emulator Suite に分離する

**Date**: 2026-08-16
**Status**: Accepted

**訂正（2026-08-16）**: 初版でポートを `auth: 9199` / `firestore: 8180` / `ui: 4100` としていたが、`auth: 9199` が sakeflow の **Storage** エミュレータ（Firebase 標準デフォルト）と衝突していた。`+10000` オフセット方式（下記）に変更し、`_hub/CLAUDE.md` にプロダクト横断のポート帯管理を追加した。

## 背景

実機確認中、ブラウザ自動操作（Claude in Chrome）で「サインインが必要です」ダイアログを操作していたところ、誤って「Googleでサインイン」をクリックし、ブラウザに残っていた Google セッションでサイレンスサインインが完了してしまう事故が2回発生した。サインインしたのは操作者自身の日常利用アカウントで実害は無かったが、原因を調べたところ、事故が起きた理由は座標のズレという偶然だけではなく、**このリポジトリのローカル開発（`flutter run`）が構造的に本番 Firebase プロジェクト（`my-career-app-559fd`）に直結しており、ローカル/本番を分離する仕組みが一切無かった**ことだった。

- `firebase.json` に `emulators` セクションが無い
- `lib/main.dart` は `Firebase.initializeApp` を無条件で呼ぶだけで、エミュレータへの分岐が無い
- `.firebaserc` に dev/staging 用の別プロジェクトも無い

`flutter run` を打つたびに実データベース・実認証基盤を操作している状態であり、これは自動操作でなくても、手動操作でボタンを押し間違えれば同じ事故が起きる、常に開いていた穴だった。

**他プロダクト（`sakeflow`）は既にこの仕組みを導入済み**で、`app/lib/emulator_config.dart` + `main.dart` の `if (kDebugMode) await connectToEmulators();`、`firebase.json` の `emulators` ブロックという構成だった。sakeflow・my_career_app とも Firebase + Flutter という共通構造を持つため、同じ開発スキームを踏襲する。

## 決定

### 1. Firebase Local Emulator Suite を導入する

- `firebase.json` に `emulators` ブロックを追加。ポート番号は Firebase の標準デフォルト一式（auth: 9099, firestore: 8080, storage: 9199, ui: 4000 等）に**一律 +10000** した `auth: 19099` / `firestore: 18080` / `ui: 14000` を使う。プロダクトごとに別セッションで並行作業する運用（`_hub/CLAUDE.md`）と、標準デフォルトのままの sakeflow が同一マシンで起動しっぱなしになりうる状況は相性が悪いため、同時起動できるようポート帯を分離した。この帯の割り当ては `_hub/CLAUDE.md` にプロダクト横断で記録する
- `lib/core/firebase/emulator_config.dart` を新規追加。`connectToEmulators()` が Auth / Firestore エミュレータへ接続する
- `lib/main.dart` で `kDebugMode` のときのみ `connectToEmulators()` を呼ぶ

### 2. エスケープハッチを作らない

`kDebugMode`（`flutter run`）は**常に**エミュレータに接続する。`--dart-define` 等でオプトイン的に本番へ接続できるフラグは用意しない。ローカルで本番データを見る必要が生じた場合は `flutter run --release` を使う（`kReleaseMode` では無条件で本番）。

フラグ方式（例: `--dart-define=USE_PROD_FIREBASE=true`）も検討したが、「フラグの消し忘れで安全側のつもりが本番に繋がっていた」「逆に毎回フラグを付けるのが定着し、実質デフォルトが危険側に戻る」という2方向の事故リスクを持ち込むため採らなかった。分岐を「debug=エミュレータ / release=本番」の二択のみにする方が、設定を間違えようがない。

### 3. Google サインインにアカウント選択を強制する

`lib/features/auth/data/web_auth_repository.dart` の `signInWithPopup` は、ブラウザに Google セッションが1つでも残っていると、アカウント選択画面を出さずにそのセッションでサイレンスサインインしていた。これは自動操作のミスクリックだけでなく、**共有 PC で実ユーザーが「サインイン」を押したときにも意図しないアカウントで入ってしまいうる本番バグ**でもあったため、`GoogleAuthProvider.setCustomParameters({'prompt': 'select_account'})` を追加し、毎回アカウント選択を挟むようにした。

モバイル（`mobile_auth_repository.dart`）は `google_sign_in` のネイティブ `authenticate()` フローを使っており、既にアカウント選択が挟まる仕組みのため対象外。

### 4. AI 機能導入後の制約（今回はコード変更なし、記録のみ）

sakeflow の `docs/adr/0003-migrate-openai-to-firebase-ai-logic.md` に「`firebase_ai`（Vertex AI）パッケージはエミュレータ非対応。実機・実 Firebase プロジェクトでのテストが必要」という決定が記録されている。my_career_app は PDR-006 ピボットで Firebase AI Logic（Gemini）を導入予定であり、**導入後は AI 呼び出し部分だけエミュレータの境界をすり抜けて本番に到達する**という同じ制約を抱えることになる。導入時にこの前提を踏まえて設計すること（→ #47）。

## 検討したが採らなかった案

- **`--dart-define` によるオプトイン式の本番接続フラグ**: 上記の通り、フラグ管理という「消し忘れ／付け忘れ」の余地自体が事故の温床になるため不採用。
- **dev 用に別 Firebase プロジェクトを新設する**: プロジェクト管理コスト（Firebase コンソール設定・Firestore ルール・Auth プロバイダ設定の二重管理）が増える一方、エミュレータで得られる分離効果と大差ないため見送り。
- **sakeflow とポート番号を完全に一致させる**: 当初この方針で実装したが、検証中に「両プロダクトのエミュレータを同時起動できない」問題が実際に発生したため撤回した。ポート番号は統一すべき対象ではなく、統一すべきは「`kDebugMode` は常にエミュレータ、エスケープハッチ無し」という契約の方だと判断した。
- **sakeflow の各サービスの実ポートだけを個別に避ける**: 一度 `auth: 9199` / `firestore: 8180` / `ui: 4100` として実装・マージしたが、`9199` が sakeflow の Storage エミュレータ（Firebase 標準デフォルト）と衝突していた。個別のポートを都度確認して避ける方式は、サービスが増えるたびに再度衝突しうる脆い方式だと判明したため撤回し、Firebase の標準デフォルト一式に一律 `+10000` する方式に変更した。これなら sakeflow が将来 Firebase の別サービス（database, pubsub 等）を追加しても機械的に衝突しない。

## 影響範囲

- `firebase.json`: `emulators` ブロック追加
- 新規: `lib/core/firebase/emulator_config.dart`
- `lib/main.dart`: `kDebugMode` 分岐を追加
- `lib/features/auth/data/web_auth_repository.dart`: アカウント選択強制
- `CLAUDE.md` §4「知らないと事故るもの」に追記
- `README.md` のローカル実行手順にエミュレータ起動コマンドを追記
- `flutter build web --release`（CI の deploy ワークフローが使う）は無改修で本番のまま動作する

## 関連

- sakeflow の `app/lib/emulator_config.dart`、`docs/adr/0003-migrate-openai-to-firebase-ai-logic.md`（同一パターンの先行実装）
- `docs/pdr/PDR-006-ai-agent-open-data-pivot.md`（AI 機能導入予定、上記④の制約が関係する）
