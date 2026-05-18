# ADR-012: 依存関係に強度（hard / soft）を導入する

**Date**: 2026-05-12
**Status**: 採用済み

## 背景

PDR-005 で「規定イベントごとに **強い前後関係（必須）** と **弱い前後関係（推奨）** を事前定義し、
ドロップ時にリアルタイムで赤（hard違反）/ 黄（soft違反）のフィードバックを出す」ことが決定された。

既存の `EventDependency` モデルは `DependencyType`（prerequisite / consequence / deadline / sync）と
`offsetMonths` を持つが、**「絶対に成立しない順序か / 推奨にとどめるか」を区別する手段がない**。
すべての違反が同じ重みで表示されると、ユーザーは「式場決定の6ヶ月後の結婚式」という慣習的な目安と
「入籍はプロポーズの後」という論理的な前後を区別できない。

## 決定

`EventDependency` に **`strength: DependencyStrength`**（`hard` | `soft`）を追加する。

```dart
enum DependencyStrength {
  hard, // 物理的・法的・論理的に成立しない順序の前提
  soft, // 慣習・準備期間として推奨される前提
}
```

### 分類基準

| 強度 | 定義 | 例 |
|---|---|---|
| **hard** | 物理的・法的・論理的にその順序でしか起こり得ない | プロポーズ → 入籍 / 妊娠 → 出産 / 出産 → 産休 / 出産 → 育休 / 育休 → 復職 / 入社 → 退職 |
| **soft** | 慣習・準備・経験則として推奨される経過月数があるが、違反しても物理的には成立する | 式場決定 → 結婚式（6ヶ月以上推奨）/ 出産1年前までの転職 / 結婚意思共有 → プロポーズ |

### UI フィードバック

- **hard 違反**: カード枠を赤、メッセージ「{X}の後に置かれるイベントの目安です」（事実提供口調、ADR-005と同方針）
- **soft 違反**: カード枠を黄、メッセージ「{X}から{N}ヶ月以上が一般的な目安です」
- **どちらも配置はブロックしない**（Value 4: Empowerment, not Direction）

## 理由

- **ユーザーの直感に合う粒度**: 「絶対 / 推奨」の2段階は、人間が制約を頭の中で扱う粒度と一致する。
  3段階以上に細分化すると色設計・メッセージ設計が複雑化し、Value 4 の事実提供口調を維持しにくい。
- **既存の `DependencyType` との直交**: type は「依存の意味（前提 / 結果 / 期限 / 連動）」を表すのに対し、
  strength は「違反の重さ」を表す。直交した2軸で組み合わせ自由（例: prerequisite × hard、deadline × soft）。
- **Empowerment, not Direction との整合**: hard でもブロックせず警告のみ。色とメッセージで情報量を変えるだけ。
  ユーザーが「あえて hard を破る」選択肢を残す。
- **C-01 / C-02 との統合**: 既存の C-01（転職→出産1年以内）/ C-02（出産1年前までの転職目安）は
  本質的に soft ルールである。SPEC §4 のカタログ定義に統合し、`constraint_checker_provider` を
  カタログ静的ルールを参照する形に書き換える。

## メッセージ文言の基準（再確認）

PRODUCT_VISION.md Value 4 / SPEC v1.1 のメッセージ文言基準を継承する。

- 使う: 「〜の目安です」「〜が確保できると◯◯しやすくなります」「一般的には〜が多いです」
- 使わない: 「〜すべき」「〜が必要」「リミット」「〜しておく」「〜できません」「ブロック」

## Firestore スキーマへの影響

`users/{userId}/dependencies/{dependencyId}` に以下を追加:

- `strength: String` - "hard" | "soft"

既存ドキュメントには値が無いため、Repository層で読み込み時に既定値 `soft` を補う
（リリース前のため移行は不要だが、防御的に実装する）。

## 影響範囲

- `lib/features/timeline/domain/event_dependency.dart`: `strength` フィールド追加
- `lib/features/timeline/logic/constraint_checker_provider.dart`: hard / soft を区別して返す。C-01 / C-02 をカタログ静的ルールに統合
- `lib/features/timeline/logic/cascade_move_provider.dart`: hard はカスケード優先、soft は警告のみ
- `lib/features/timeline/presentation/widgets/constraint_warning.dart`: 赤 / 黄の色分け
- `docs/FIREBASE_ARCHITECTURE.md`: dependencies.strength を追加
- `docs/SPEC.md` §4: 各カタログ行に hard 先行 / soft 先行を明記

## 関連

- ADR-002: 制約チェック結果の非永続化
- ADR-005: 制約チェックのクライアントサイド実行
- ADR-010: EventCategory 廃止
- PDR-005: ピボット背景
