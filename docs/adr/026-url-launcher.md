# ADR-026: 外部リンクを開くために url_launcher を導入する

**Date**: 2026-08-23
**Status**: Accepted

## 背景

PDR-009 で、制度上限（B1、`lib/features/open_data/`）の出典URLをタップで開けるようにする方針を決めた。
`DataSource.url` は #96（PDR-008 実装）の時点から値として存在していたが、`lib/` のどこからも読まれておらず、
外部URLを開く仕組みがリポジトリに一切無かった（`launchUrl` の使用箇所ゼロ、`pubspec.yaml` に該当パッケージなし）。

Web が主要ターゲット（Firebase Hosting）だが、モバイル（`google_sign_in` 対応あり）も視野にある構成のため、
Web 専用の実装を直接書くと後でモバイル対応時に書き直しになる。

## 決定

`url_launcher`（公式 `flutter/packages` 配下、pub.dev の推奨パッケージ）を追加する。

呼び出し側は `lib/core/platform/url_launcher_service.dart` の `UrlLauncher` 抽象と
`urlLauncherProvider` を経由し、`url_launcher` を直接 import しない。理由は既存のテスト方針
（CLAUDE.md §5: ウィジェットテストは配線のみを見る）に合わせるため。ウィジェットテストで
実際にブラウザを起動せず、`urlLauncherProvider` をフェイクで override して「タップで呼ばれたか」
だけを検証する。

既定実装 `DefaultUrlLauncher` は `launchUrl(uri, webOnlyWindowName: '_blank')` を呼ぶ。
Web では新しいタブで開く（アプリのタブを奪わない）。

## 検討したが採らなかった案

1. **Web 限定で `package:web` / `dart:html` 相当を直接叩く**
   採らなかった理由: 実装は数行で済むが、モバイル対応が要るときに書き直しになる。
   `url_launcher` は既にクロスプラットフォームで、追加コストはほぼ無い。
2. **`Uri.parse` + `launchUrl` を呼び出し側（`constraint_warning.dart`）に直接書く**
   採らなかった理由: 抽象を挟まないとウィジェットテストで実ブラウザ起動を避けられない
   （CLAUDE.md のテスト方針「ウィジェットテストは配線のみ」に反する）。
