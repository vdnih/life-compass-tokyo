# ADR-010: EventCategory enum の廃止と catalogId への移行

**Date**: 2026-05-12
**Status**: 採用済み

## 背景

PDR-005 のピボットに伴い、これまでイベントの種別を表現してきた `EventCategory` enum（16値）の存在意義を再検討する必要が生じた。
従来の `EventCategory` は次の役割を担っていた。

- イベントの仕事 / プライベート区別（`isWork` プロパティ）
- 表示属性（アイコン・カラー）の決定キー
- 制約チェック C-01 / C-02 のマッチング条件
- ゴールテンプレート `TemplateEvent.category` の値

ピボット後は規定ライフイベントカタログが種別の中心となるため、`EventCategory` を維持するか
完全に置換するかを決定する必要がある。

## 決定

`EventCategory` enum を **完全廃止** し、`LifeEvent.catalogId: String`（規定カタログのID）に置換する。

- 仕事 / プライベートの区別は、カタログ側の `LifeEventGroup` enum で represent する。
- 表示属性（アイコン・カラー）は規定カタログ定義（`PredefinedLifeEvent.icon` / `.color`）から取得する。
- 制約チェックは catalogId ベースの hard / soft ルール（ADR-012 参照）に統一する。
- ゴールテンプレートの `TemplateEvent.category` を `catalogId` 参照に書き換える。

リリース前であるため、移行スクリプト・後方互換性の維持は行わない。

## 理由

- **二重管理の解消**: カテゴリと規定カタログが共存すると、同じ「結婚」でも `EventCategory.marriage` と
  `wedding-ceremony` / `marriage-registration` などの複数カタログ項目が混在し、整合性管理が困難になる。
- **粒度の不一致**: 規定カタログは「プロポーズ」「両家顔合わせ」「入籍」「結婚式」のように粒度細かく定義するため、
  16値の粗いカテゴリでは表現しきれない。
- **ADR-001 との関係**: ADR-001 は「`type` + `subCategory` の2フィールドを `category` 単一に統合」した判断。
  本ADRはその次のステップとして「`category` 単一フィールドをさらに `catalogId` に置換する」もので、
  方向性は一貫している（フィールド数を増やさない / 冗長な導出データを保存しない）。
- **ADR-004 との関係**: 規定カタログ自体もFirestoreには保存せずアプリ内にハードコードする。
  ADR-004（ゴールテンプレートのハードコード）と同じ方針を踏襲する。
- **YAGNI**: カタログの動的編集機能（管理画面・CMS）は現状要件にないため、リポジトリ抽象化はしない。
  `static const` ベースのレジストリで十分。

## 影響範囲

- `lib/features/timeline/domain/life_event.dart`: `EventCategory` 削除、`catalogId` / `parentEventId` / `kind` / `budgetYen` 追加
- `lib/features/timeline/domain/goal_template.dart`: `TemplateEvent.category` → `catalogId`
- `lib/features/timeline/data/goal_template_data.dart`: 既存テンプレートの値を catalogId に置換
- `lib/features/timeline/presentation/widgets/event_style.dart`: `categoryColor()` / `categoryIcon()` を `catalogColor()` / `catalogIcon()` に置換
- `lib/features/timeline/logic/constraint_checker_provider.dart`: C-01 / C-02 のマッチを catalogId ベースに移行
- 新規: `lib/features/catalog/` 配下の規定カタログ定義一式
- `docs/FIREBASE_ARCHITECTURE.md`: events.category フィールドを削除、catalogId 追加
- `docs/SPEC.md`: §1 カテゴリ表を削除、§4 規定カタログ表を新設

## 関連

- ADR-001: イベント種別を category 単一フィールドに統合
- ADR-004: ゴールテンプレートのハードコード
- PDR-005: 規定ライフイベントカタログD&D方式へのピボット
