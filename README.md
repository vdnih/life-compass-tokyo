# My Career App

女性がキャリアとプライベートの両面からライフプランを考えるためのタイムラインアプリ。
規定ライフイベントのカタログから項目をタイムラインへドラッグ&ドロップし、イベント間の依存関係や
制約（「入籍の後に結婚式」など）を確認しながらライフプランを組み立てられる。

Flutter 製で、Web を主要ターゲットとして Firebase Hosting にデプロイしている。

## 必要環境

- Flutter 3.x（Dart SDK `^3.10.4`）
- Firebase CLI（デプロイする場合のみ）

## セットアップと起動

```bash
flutter pub get
firebase emulators:start   # 別ターミナルで起動しておく（サインインを試す場合に必要）
flutter run -d chrome
```

未ログイン（ゲスト）状態ではサンプルデータを含むインメモリのデータストアが使われるため、
Firebase の設定なしでも動作を確認できる。

`flutter run`（デバッグビルド）は常にローカルの Firebase エミュレータに接続し、本番の
Firebase プロジェクトには一切触れない（ADR-024）。Google ログインを試す場合はエミュレータの
偽アカウントでサインインすることになる。本番データを見る必要がある場合は
`flutter run --release` を使う。

## 開発

```bash
flutter analyze                 # 静的解析
flutter test                    # 全テスト
flutter test --coverage         # カバレッジ付き（coverage/lcov.info を生成）
```

`flutter analyze` と `flutter test` は CI の必須ゲート（`.github/workflows/ci.yml`）。

## デプロイ

`main` への push で GitHub Actions が Firebase Hosting に自動デプロイする。PR には
プレビューチャンネルが払い出される。手動でデプロイする場合:

```bash
flutter build web --release
firebase deploy --only hosting
```

## ドキュメント

| 知りたいこと | 参照先 |
|---|---|
| なぜこのプロダクトか | [docs/PRODUCT_VISION.md](./docs/PRODUCT_VISION.md) |
| 何の機能があるか | [docs/PRD.md](./docs/PRD.md) |
| ビジネスルール（カタログ・制約） | [docs/SPEC.md](./docs/SPEC.md) |
| ソフトウェア設計 | [docs/SOFTWARE_ARCHITECTURE.md](./docs/SOFTWARE_ARCHITECTURE.md) |
| Firebase インフラ設計 | [docs/FIREBASE_ARCHITECTURE.md](./docs/FIREBASE_ARCHITECTURE.md) |
| なぜその設計にしたか | [docs/adr/](./docs/adr/) |
| なぜこの機能・優先順位か | [docs/pdr/](./docs/pdr/) |
| 開発ルール | [CLAUDE.md](./CLAUDE.md) |

実装の詳細はコード（`lib/` と `test/`）を正とする。
