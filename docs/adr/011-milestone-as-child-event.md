# ADR-011: マイルストーンを LifeEvent の子要素として表現する

**Date**: 2026-05-12
**Status**: 採用済み

## 背景

PDR-005 で「マイルストーン（例: 結婚式に対する『式場選び期間』『式場決定』『衣装合わせ』）」を
タイムライン上に表現することが決定された。マイルストーンを **どのデータ構造で表現するか** を決める必要がある。

検討した選択肢:

1. **新規 `Milestone` モデルを別コレクションで作る**
   - Pros: 親イベントの軽量化、専用属性を持たせやすい
   - Cons: スキーマが2系統に分かれ、依存関係 / カスケード移動 / 制約チェックのロジックも2系統に分岐する
2. **`LifeEvent` に `parentEventId: String?` を追加し、子要素として表現する**
   - Pros: 既存のCRUD / カスケード移動 / 依存関係 / 描画ロジックをすべて再利用できる
   - Cons: 「マイルストーンはイベントの一部」「親と子は粒度が違う」を `kind` フラグで区別する必要がある

## 決定

**`LifeEvent` に `parentEventId: String?` と `kind: EventKind`（`event` | `milestone`）を追加し、
マイルストーンを子要素として同一モデルで表現する**。

- `parentEventId` が null のものを **親イベント（event）** とし、タイムライン上にカードで表示する。
- `parentEventId` が設定されているものを **マイルストーン（milestone）** とし、親カード直下に小さく横並びで表示する。
- マイルストーンは規定カタログの `MilestoneTemplate` から生成され、`offsetMonthsFromParent` で
  親の日付からの相対位置を持つ。
- 親イベントを移動すると、子マイルストーンは相対オフセットを保ったまま追従する
  （カスケード移動ロジックの拡張）。

## 理由

- **モデルの一元化**: 既存の `LifeEvent` ベースのRepository / Provider / カスケード移動 / 依存関係 / Firestoreスキーマ /
  セキュリティルールを完全に再利用できる。
- **粒度の柔軟性**: 「式場選び」は厳密にはイベント（期間を持つ）だが、ユーザーから見れば「結婚式に向けた一里塚」。
  「イベントとマイルストーンは本質的に同種だが表示と粒度が違うだけ」という設計判断と整合する。
- **First-class Citizen との整合**: マイルストーンを独立した別モデルにすると「親が本体、子はおまけ」という暗黙の
  ヒエラルキーが生まれる。同一モデルにすることで、ユーザーは子マイルストーンを単独イベントとして
  自由に編集 / 昇格 / 切り離しできる。
- **Living Plan との整合**: ユーザーがマイルストーンを親から切り離して独立イベントにしたり、
  逆に既存イベントを別イベントの子として吸収させるなどの「再構成」を、`parentEventId` の付け替えだけで実現できる。

## Firestore スキーマへの影響

`users/{userId}/events/{eventId}` に以下を追加:

- `parentEventId: String?` - 親イベントID（null = 親）
- `kind: String` - "event" | "milestone"

既存のセキュリティルール（`users/{userId}/events/**` の owner-only アクセス）は変更不要。
親 / 子の整合性チェック（親が存在するか、循環していないか）はクライアント側で行う（ADR-005 と同方針）。

## 影響範囲

- `lib/features/timeline/domain/life_event.dart`: `parentEventId` / `kind` 追加
- `lib/features/timeline/logic/cascade_move_provider.dart`: 親移動時に子マイルストーンを追従させる
- `lib/features/timeline/logic/timeline_events_provider.dart`: 親削除時に子マイルストーンも連動削除（または昇格）するロジック
- `lib/features/timeline/presentation/widgets/year_month_timeline.dart` / `year_timeline.dart`: 親カード直下に子マイルストーンを描画
- 新規Widget: `MilestoneChip`（仮称、Wave 3 で実装）
- `docs/FIREBASE_ARCHITECTURE.md`: events スキーマに `parentEventId` / `kind` 追加
- `docs/SPEC.md` §4: 各規定イベントの「既定マイルストーン」列で `MilestoneTemplate` を列挙

## 関連

- ADR-001 / ADR-003: 既存スキーマ設計
- PDR-005: ピボット背景
