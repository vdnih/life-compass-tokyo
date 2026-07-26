# ADR-014: 開発プロセスとドキュメント体系の簡素化

**Date**: 2026-07-26
**Status**: 採用済み

## 背景

`CLAUDE.md`（234行）は 2026年3月時点の「Sub Agent に細かく役割を規定すれば自律開発が回る」という前提で
書かれていた。その後の運用で、規定の大半が機能していないか、実態と食い違っていることが分かった。

- **エージェント体制の過剰規定**: 3ロール（architect / implementer / qa）+ ファイル所有権のネガティブリスト +
  2フェーズ実行モデルを定義していたが、Claude Code 本体のハーネス（Explore / Plan エージェント、権限モード、
  plan mode）で同等以上のことができる。さらに `.claude/agents/*.md` は3つとも `Read, Write, Bash` を
  持っており、所有権の規定に強制力が無かった。
- **エージェント定義が誤情報源になっていた**: 存在しない `docs/ARCHITECTURE.md` を参照し、`pubspec.yaml` に
  無い Freezed の使用を必須と規定していた。従うと確実に誤る状態だった。
- **Git 運用が実体と不一致**: 作業ブランチを `dev` と規定していたが、実際は feature ブランチ → PR → `main`。
  `dev` は一度も `main` にマージされていない。
- **ドキュメントの半分が化石化**: `qa_report.md` / `test_scenarios.md` / `WBS.md` は 2026年3月以降更新されず、
  廃止済みの `EventCategory` / `WorkSubCategory` を前提に書かれていた。`feature_registry.md` は更新義務
  （旧 CLAUDE.md §9）が守られず実装と乖離していた。
- **監査ログと ADR / PR の重複**: `docs/audit_log.md` は維持されていたが、記録内容は PR 説明と ADR で
  代替できるものがほとんどで、三重に書く運用コストが発生していた。

一人で開発しているという前提に立てば、必要なのは「役割分担のルール」ではなく「なぜそうしたかが後から辿れること」
だけである。

## 決定

1. **Sub Agent 定義（`.claude/agents/architect.md` / `implementer.md` / `qa.md`）を廃止する。**
   Claude Code 標準のエージェントとハーネスに任せる。
2. **`docs/audit_log.md` への追記を終了する。** 開発の経緯は以下に一本化する。
   - **PR 説明**（なぜ変更したか・何をしたか・検討したが採らなかった案・どう検証したか）
   - **ADR**（後戻りしにくい技術判断）/ **PDR**（機能の要否・優先順位の判断）
   - 判断を覆した場合は元の ADR / PDR に `Superseded by` を追記し、覆した理由を併記する。
3. **停滞していたドキュメントを `docs/archive/` へ退避する。**
   対象: `audit_log.md` / `feature_registry.md` / `TESTING_POLICY.md` / `qa_report.md` /
   `test_scenarios.md` / `WBS.md`。削除ではなく移動とし、当時の検討内容は残す。
4. **`CLAUDE.md` に「増えるもの・変わるもの」を書かない方針とする。**
   カタログ件数・ファイル行数・具体的な行番号は書かず、単一情報源（コードやテストのアサーション）への
   ポインタだけを書く。同じ数値を2箇所で管理しない。
5. **Git 運用を実体に合わせる。** feature ブランチ → PR → `main`。`dev` ブランチの規定は廃止。
6. **CI に品質ゲートを追加する。** これまで GitHub Actions はビルドとデプロイのみを実行しており、
   `flutter analyze` も `flutter test` も走っていなかった。`.github/workflows/ci.yml` を新設して
   PR の必須ゲートとする。

## 理由

- ルールの情報源を `CLAUDE.md` 1箇所に集約することで、規定同士の食い違い（エージェント定義 vs CLAUDE.md vs
  設計ドキュメント）が構造的に起きなくなる。
- 経緯の記録先を PR と ADR に絞ることで、記録が変更そのものに紐づく。監査ログのように「書き忘れると欠落し、
  日付が手書きで実際のコミット日とずれる」という問題が起きない。
- 変動する情報を CLAUDE.md から排除することで、ドキュメントが陳腐化する主要因を断つ。

## 影響範囲

- `CLAUDE.md`（全面書き換え。234行 → 約130行）
- `.claude/agents/`（削除）、`.claude/launch.json`（削除。VSCode 用ファイルの置き場所誤り）
- `.claude/settings.json`（新設。共有すべき permissions を git 管理下に移動）
- `docs/archive/`（新設）
- `.github/workflows/ci.yml`（新設）
- `README.md`（3行から実用的な内容に書き直し）
- `docs/SOFTWARE_ARCHITECTURE.md` / `docs/adr/001`（実装と食い違う記述の修正）
- `lib/` / `test/` 計11ファイル（`dart fix --apply` による const 系 lint の機械的修正）。
  CI ゲート追加時点で info レベルの指摘が78件蓄積しており、これを残したまま
  `flutter analyze` を必須にすると常に失敗するため、先に解消した。ロジックの変更は伴わない。

## 結果

**得るもの**

- 開発ルールの単一情報源化。守るべきことが「PR に経緯を書く / 重い判断は ADR に残す」の2点に集約された。
- ドキュメントのメンテナンスコスト減。維持できていなかった registry と監査ログの更新義務が消えた。
- CI による品質ゲート。これまで検知されなかった解析エラーやテスト失敗が PR 段階で止まる。

**失うもの**

- 実装レベルの日次ログ。監査ログにあった「どのファイルをどう変えたか」の粒度の記録は PR 説明と
  コミット差分で代替する。ADR より細かい判断は PR に残す運用になるため、PR 説明を省略しないことが前提となる。

## Follow-up（別タスク）

本 ADR ではドキュメントとプロセスのみを扱った。以下はコード側の課題として残っている。

1. **タイムラインウィジェットの重複解消** — `year_timeline.dart` と `year_month_timeline.dart` が
   ほぼ同一実装で並存しており、D&D の修正を常に両方へ入れる必要がある。
2. **feature ディレクトリ階層の統一** — `domain/` を持たない feature や、ほぼフラットな feature がある。
3. **テストの整備** — `auth` / `user_profile` / `core` にテストが無い。また本 ADR の作業に伴い、
   カタログ pivot 前の UI を前提にした `add_event_dialog_test.dart` の2件を削除した（代替は未作成）。

1〜3 の完了後に `docs/SOFTWARE_ARCHITECTURE.md` と `CLAUDE.md` の該当箇所を改めて整備する。
