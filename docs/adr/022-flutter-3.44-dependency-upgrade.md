# ADR-022: Flutter 3.44 化と依存関係の全面更新、パッケージ選定基準の廃止

**Date**: 2026-08-09
**Status**: Accepted

## 背景

CI の Flutter バージョンは 3.38.5 に固定されていた。3.44.x に上げると
`ListTile`/`ExpansionTile` 系ウィジェットで新しい debug assertion
（`ListTile background color or ink splashes may be invisible`）が18件のテストで
発生し、原因調査を後回しにして固定運用していた（#45）。

固定運用を続けると、Flutter 本体・Firebase・riverpod など周辺エコシステム全体の
更新から取り残される。本 PR ではこの技術的負債の解消に加えて、依存関係全体を
最新化するかどうかを検討した。

このリポジトリは個人のハッカソン用プロダクトであり商用アプリではない。
「壊れたら作り直せばよい」という前提のもと、破壊的変更を理由に更新を避けるのではなく、
新しい設計判断（riverpod 3 の Notifier 統一、コード生成の廃止など）を実際に試す方を
選んだ。書き手が Claude であることも踏まえ、Claude にとって書きやすい・読みやすい形
（生成コードより手書きコードの方が中身をそのまま読めるなど）も判断材料に含めている。

## 決定

### 1. Flutter SDK を 3.44.9 に更新し、CI の固定バージョンも合わせる

`ListTile` アサーションの原因は `catalog_panel.dart` の `Container(color:)` が
`ListTile`/`ExpansionTile` の外側で不透明な背景を描いていたことだった
（`ListTile` はインク効果を最も近い `Material` 祖先に描画するため、間に不透明な
`Container` が挟まると Flutter 3.44 の新しい assertion に引っかかる）。
`Container` を `Material(color:)` に置き換えて解消した。19件の失敗テストはすべて
この1箇所が原因で、他の `ListTile` 系候補（`catalog_picker_field.dart` の
`ExpansionTile`、`SwitchListTile`）は実際には引っかかっていなかった。

CI の `flutter-version` は 3.44.9 に固定したままにする。`channel: stable` による
無固定運用は、CI が突然の破壊的変更を拾って赤くなるリスクの方が更新の手間より
大きいと判断したため（このリポジトリの開発体制はレビュー無しの単独運用であり、
CI の失敗に気づくタイミングが遅れやすい）。

### 2. riverpod のコード生成（riverpod_generator / build_runner）を廃止する

`@riverpod` アノテーションの使用箇所は `UserProfileNotifier` 1つだけで、
`build_runner` はこの1ファイルのためだけに依存関係に存在していた。間接依存の
`build_resolvers` / `build_runner_core` は pub.dev で discontinued 表示が出ている。

`UserProfileNotifier` を周囲の Notifier（`TimelineEventsNotifier` など）と同じ
手書きスタイル（`AsyncNotifier` + `AsyncNotifierProvider.autoDispose`）に書き換え、
`riverpod_generator` / `riverpod_annotation` / `build_runner` を依存から削除した。
生成コード（`.g.dart`）が1つ消え、間接依存が37個減った。

これにより CLAUDE.md §4 の「Riverpod のコード生成はほぼ使っていない」という
記述の例外が無くなり、「コード生成を使わない」がプロジェクトの原則になった。

### 3. flutter_riverpod を 3.4.2 に更新する

当初は「破壊的変更が大きい割にメリットが薄い」として riverpod 2 系維持を検討したが、
実際に破壊的変更の範囲を洗い出した結果、コストは見積もりよりかなり小さいと判明した
（`StateProvider` の実使用は `catalogSearchQueryProvider` 1箇所のみ。当初
「33箇所」と見積もったのは `authStateProvider` への部分一致によるカウントミスだった）。
riverpod 3 は Notifier 系を単一の基底クラス体系に統一し（`autoDispose` は
Provider 側のプロパティになった）、`valueOrNull` を `.value` に一本化するなど
API が単純化される方向の変更であり、「新しい設計を試す」という本 PR の方針とも合う
ため、更新することにした。

移行で対応した破壊的変更:

- `catalogSearchQueryProvider`（唯一の `StateProvider`）を `Notifier` ベースの
  `NotifierProvider` に置き換えた。`StateProvider` は riverpod 3 で legacy 扱いになる。
- `valueOrNull` の全18箇所を `.value` に置き換えた。意味は同じ（データがあれば
  それを返し、無ければ `null`）。
- `UserProfileNotifier` の基底クラスを `AutoDisposeAsyncNotifier` から
  `AsyncNotifier` に変更した（riverpod 3 では autoDispose 専用の基底クラスが
  廃止され、`AsyncNotifierProvider.autoDispose` という Provider 側のビルダーで
  表現するようになったため）。
- `Override` 型のエクスポート元が `package:flutter_riverpod/flutter_riverpod.dart`
  から `package:flutter_riverpod/misc.dart` に変わった。テストヘルパー
  （`test/support/pump.dart` など）の import を修正した。

**判明した罠**: riverpod 3 は `StreamProvider` の購読を、能動的な listener が
いない間は一時停止するようになった。`ProviderContainer` を直接使うテストで
`container.read(provider.future)` を単独で呼ぶだけだと、購読が開始される前に
一時停止され、override した `Stream.value(...)` が永遠に配信されずハングする
（`event_repository_test.dart` / `dependency_repository_test.dart` の計6箇所で発生、
`flutter test` が30秒タイムアウトで失敗した）。本番コードでは `ConsumerWidget` が
常に `ref.watch(authStateProvider)` するため影響しないが、テストでは
`container.listen(authStateProvider, (_, _) {})` で能動的な listener を張ってから
`.future` を待つ必要がある。`test/support/pump.dart` に `awaitAuthState()` ヘルパーを
追加して解消した。

### 4. Firebase・go_router・google_sign_in 等の依存を最新版に更新する

`firebase_core` / `firebase_auth` / `cloud_firestore` / `go_router` /
`google_fonts` / `flutter_lints` / `mocktail` / `flutter_launcher_icons` /
`cupertino_icons` / `uuid` を最新版に更新した。

`google_sign_in` は 6→7 で認証（identity）と認可（access token）の API が
分離される破壊的変更が入っていた。`GoogleSignIn()` コンストラクタと
`signIn()` メソッドが廃止され、`GoogleSignIn.instance` を `initialize()` した上で
`authenticate()` を呼ぶ形になった。`MobileAuthRepository` を新 API に書き換えた。
`GoogleSignInAuthentication` は v7 では `idToken` のみを持ち `accessToken` を
持たないが、Firebase の `GoogleAuthProvider.credential` は `idToken` のみでも
認証できるため、Web 版（`WebAuthRepository`、Firebase Auth のポップアップ実装）と
異なりモバイル版はそもそも `accessToken` を使っていなかった。

### 5. `新規パッケージの追加` の pub.dev Like 数基準を廃止する

CLAUDE.md §5 にあった「pub.dev の Like 数 500 以上、最終更新 6ヶ月以内を目安とする」
というルールの由来をユーザーから問われ、git 履歴を調査した。

このルールは `70db71f`（"claude code向けの設定"、Claude Code 導入時のエージェント
体制整備コミット）で、他の7行（Widget分割粒度・エラーハンドリング・null安全性・
命名規則・コメント・テストの粒度・MVPスコープ外の機能）とセットの
「判断に迷ったときのデフォルト方針」8行テーブルとして一括で追加されたものだった。
このテーブル全体が当時の Claude によるエージェント体制整備の一環として書かれ、
個別の背景説明や採用理由のコミットメッセージは無かった。その後 PR #29
（`0cdd5f9`、開発ルールの簡素化）で兄弟行のうち3行が削除されたが、
Like 数の行だけ空白調整以外の変更を受けずに生き残っていた。

このルール自体、プロジェクト自身の依存関係と矛盾する。`flutter_launcher_icons` は
2026年08月時点で pub.dev の Like 数が8000超だが最終更新は14ヶ月前であり、
「6ヶ月以内」を機械的に適用すると通らない。しかし実際にはこのパッケージは
このリポジトリで問題なく使われ続けている、成熟した実用ツールである。

ユーザーからも「Like数よりも、設計思想や勢いやコミュニティなどの筋の良さで
評価すべきでは」という指摘があり、同意した。Like数や更新頻度のような単一の
定量指標は、パッケージが「枯れていて安定している」のか「メンテナンスが
止まっている」のかを区別できない。判断には文脈（採用実績、issue の反応速度、
discontinued 表示の有無、代替の有無など）が要るため、数値基準をそのまま
残すよりも行ごと削除し、都度 Claude が判断する方針にした。数値の目安が
必要になった具体的な失敗事例が出てきたら、その時に改めてルール化する。

## 検討したが採らなかった案

- **flutter_riverpod を 2系に維持する**: 破壊的変更の初期見積り（`StateProvider`
  33箇所）が誤りだったことが判明し、実際のコストは低かったため見送った。
- **CI の Flutter バージョンを `channel: stable` にして固定を外す**: 単独運用の
  リポジトリでは CI の突然の赤化に気づきにくいため、固定を維持する方を選んだ。
- **pub.dev Like数基準を別の定量基準（例: 週間ダウンロード数）に置き換える**:
  単一の定量指標に頼る設計自体が問題だったため、置き換えではなく削除とした。

## 影響範囲

- `pubspec.yaml`: SDK 制約とすべての依存パッケージのバージョンを更新
- 削除: `riverpod_generator` / `riverpod_annotation` / `build_runner`、
  `lib/features/user_profile/user_profile.g.dart`
- `lib/features/catalog/presentation/catalog_panel.dart`: `Container` → `Material`
- `lib/features/user_profile/user_profile.dart`: 手書き `AsyncNotifier` に書き換え
- `lib/features/catalog/logic/catalog_provider.dart`: `catalogSearchQueryProvider` を
  `NotifierProvider` に置き換え
- `lib/features/auth/data/mobile_auth_repository.dart`: google_sign_in 7 系 API に書き換え
- `.valueOrNull` を使っていた18箇所を `.value` に置き換え
- `test/support/pump.dart`: `awaitAuthState()` ヘルパーを追加
- `analysis_options.yaml`: `build/**` を analyzer の除外対象に追加（Xcode の SPM
  解決で自動再生成される gitignore 済みディレクトリを誤って解析していたため）
- `CLAUDE.md`: §2 のコード生成コマンドを削除、§4 の Riverpod コード生成の記述を更新、
  §5 の「新規パッケージの追加」行を削除

## 関連

- #45（本 ADR が対応する Issue）
- ADR-021（TimelineView 統合。本 ADR の Flutter 3.44 化はその後続）
