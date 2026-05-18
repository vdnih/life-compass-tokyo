# ADR-013: 予算プリセット設計（規定カタログ defaultBudget + LifeEvent.budget 上書き）

**Date**: 2026-05-12
**Status**: 採用済み

## 背景

PDR-005 で予算機能の新設が決定された。規定ライフイベント（結婚式 / 新婚旅行 / 出産費用 / 海外旅行 など）には
おおよその中央値が存在し、ユーザーはそれを起点に自分のプランの金額感を捉えたい。

検討した選択肢:

1. **金額をユーザーがゼロから入力**
   - Pros: シンプル
   - Cons: 「結婚式って大体いくらだろう」というユーザーの最初の疑問に答えられない
2. **規定カタログに `defaultBudgetYen` をプリセットし、`LifeEvent.budgetYen` で上書き**
   - Pros: ユーザーは起点を得られ、必要に応じて自分の値に調整できる
   - Cons: プリセットが「正解」として受け取られるリスク（Value 1: Compass, not a Mirror への配慮が必要）

## 決定

**規定カタログに `defaultBudgetYen: int?` をプリセットし、`LifeEvent.budgetYen: int?` で上書きできる構造を採用する**。

```dart
class PredefinedLifeEvent {
  // ...
  final int? defaultBudgetYen; // 中央値（円）。null = 予算概念がないイベント
}

class LifeEvent {
  // ...
  final int? budgetYen; // null のとき catalog.defaultBudgetYen を表示
}
```

### 表示方針

- 各 EventCard に `¥XXX万` を控えめに表示。`budgetYen` が null なら `defaultBudgetYen` を、それも null なら非表示。
- AppBar 右に「合計予算 ¥XXX万」を表示。`budgetYen ?? defaultBudgetYen ?? 0` の総和。
- 編集UI: EditEventDialog 内でテキスト入力 or スライダー。空欄にすると「プリセットを使う」状態に戻る。

### プリセット金額の決定方針

SPEC §4 のカタログ表に中央値（**目安**）を明記する。20代後半〜30代前半女性の実態に近い金額レンジを参照（例: ゼクシィ結婚トレンド調査、出産費用の保険適用後実費、海外旅行の平均単価等）。

「ざっくり目安」であることをSPEC §4 冒頭に明示し、Value 1: Compass, not a Mirror に配慮する。

## 理由

- **Compass, not a Mirror への対応**:
  - プリセットは「平均的な金額の目安」として提示し、ランキングや他者比較は行わない。
  - 編集UIには「これは目安です。あなたの計画に合わせて変更できます」程度の注記を添える（Wave 3 で実装）。
- **Living Plan との整合**:
  - 編集 / 削除は1タップで可能。プリセットへの復帰も容易（フィールドを空にするだけ）。
- **データモデルの簡潔さ**:
  - 通貨は円のみ（JPY固定）。MVPで多通貨対応は不要（YAGNI）。
  - 単位は円（整数）。100万円 = 1_000_000。表示時に「万円」へ丸める。
- **永続化方針**:
  - `LifeEvent.budgetYen` は Firestore に保存する（ユーザー固有の値だから）。
  - `defaultBudgetYen` は Firestore に保存しない。カタログ定義はアプリ内ハードコード（ADR-004 / ADR-010 と同方針）。
  - したがって `budgetYen` が null のままなら DB には null として保存され、UI 表示時にカタログから補う。

## Firestore スキーマへの影響

`users/{userId}/events/{eventId}` に以下を追加:

- `budgetYen: Number?` - ユーザー上書き予算（円）。未設定なら null

既存のセキュリティルール（owner-only）は変更不要。バリデーション（負数禁止）はクライアント側で行う。

## 影響範囲

- `lib/features/timeline/domain/life_event.dart`: `budgetYen` 追加
- `lib/features/catalog/domain/predefined_life_event.dart`: `defaultBudgetYen` 追加
- `lib/features/timeline/presentation/widgets/event_card.dart`: 予算表示行追加
- `lib/features/timeline/presentation/timeline_screen.dart` または AppBar Widget: 合計予算サマリ表示
- `lib/features/timeline/presentation/edit_event_dialog.dart`: 予算編集フィールド追加
- 新規Provider: `lib/features/timeline/logic/budget_summary_provider.dart`（合計算出）
- `docs/FIREBASE_ARCHITECTURE.md`: events.budgetYen 追加
- `docs/SPEC.md` §4: 各カタログ行に予算プリセット円を明記

## 関連

- ADR-004: ゴールテンプレートのハードコード（同じく静的データの管理方針）
- ADR-010: EventCategory 廃止（規定カタログへの移行）
- PDR-005: ピボット背景
- PRODUCT_VISION.md Value 1: Compass, not a Mirror
