# ADR-001: イベント種別を category 単一フィールドに統合

**Date**: 2026-03-10
**Status**: Superseded by [ADR-010](./010-remove-event-category-enum.md)（2026-05-12）

> ここで導入した `EventCategory` enum は、規定ライフイベントカタログへのピボット（PDR-005）に伴い
> ADR-010 で廃止され、`catalogId` による参照に置き換えられた。以下は当時の判断の記録である。

## 背景

イベントの種別管理として、当初は `type`（work/private）と `subCategory` の2フィールド方式を設計していた。

## 決定

単一の `EventCategory` enum で仕事/プライベートの区分（`isWork`）とカテゴリの両方を表現する。Firestoreのフィールドも `category` 1フィールドに統合する。`isWork` の情報はアプリ側で `EventCategory.isWork` プロパティから導出するため、DBに保存しない。

## 理由

- フィールド数が削減され、データモデルがより簡潔になる
- `isWork` は `category` から導出可能な冗長データであり、DBへの保存は整合性リスクを生む
- 実装時に `type` + `subCategory` の2フィールド方式の扱いが煩雑だったため、実装に合わせてモデルを修正した

## 影響範囲

- `lib/features/timeline/domain/` 配下のデータモデル
- `docs/FIREBASE_ARCHITECTURE.md` のFirestoreスキーマ定義
