# ADR-015: Firebase 設定はリポジトリを正とし、コンソール直接編集を禁止する

**Date**: 2026-07-26
**Status**: Accepted

## 背景

`dev` ブランチにのみ `firestore.rules` / `firestore.indexes.json` / `firebase.json` の
`firestore` 設定が存在していたが、main 系列への作業移行の過程でリポジトリから失われ、
Firebase コンソールでの直接編集のみによって管理される状態になっていた（本人未確認のまま、
いつからこの状態だったかは不明）。`dev` ブランチを削除する前にこれを発見し、コンソールの
現行ルールとバイト単位で一致することを確認したうえでリポジトリへ復旧した（コミット `07b4c15`）。

この経緯を踏まえ、Firebase MCP ツールで実プロジェクトの状態を追加調査したところ、
以下も判明した:

- 使用している Firebase サービスは **Authentication / Firestore / Hosting の3つのみ**。
  Storage / RTDB / Functions / Analytics / Crashlytics / Messaging / Remote Config / App Check は
  いずれもプロジェクト側に設定が存在しない（`firebase_get_security_rules` が Storage / RTDB を
  「未プロビジョニング」として返す）。
- `docs/FIREBASE_ARCHITECTURE.md` の Firestore ロケーション記載（`asia-northeast1`）が誤りで、
  実際は `nam5`（北米マルチリージョン）で作成されていた。ロケーションは作成後変更不可のため、
  ドキュメントを実態に合わせて修正するほかない。
- Firestore の削除保護（Delete Protection）が無効だった。誤操作や誤った API 呼び出しで
  本番データベース全体を削除できてしまう状態。

## 決定

1. **`firestore.rules` / `firestore.indexes.json` / `firebase.json` をリポジトリの正とする。**
   変更は必ずこれらのファイル経由で行い、`firebase deploy --only firestore:rules,firestore:indexes`
   で反映する。**Firebase コンソールでの直接編集は行わない。**
2. **CI での自動デプロイ化は行わず、手動デプロイ運用を維持する。**
   ルール変更頻度が低く、かつセキュリティに直結する変更であるため、デプロイ前に人の目を
   通すプロセスをあえて残す（Hosting は変更頻度・影響範囲の性質が異なるため引き続き CI 自動化）。
3. **Firestore の削除保護を有効化する**（`DELETE_PROTECTION_ENABLED`）。無料でアプリの動作に
   影響しないため、リスク低減のためすぐに実施した。
4. **Point-in-Time Recovery（PITR）は有効化しない。** 継続的に費用が発生する機能であり、
   個人開発の現段階では見送る。将来、実データの重要性が増した時点で再検討する。

## 検討したが採らなかった案

- **CI での `firestore:rules` / `firestore:indexes` 自動デプロイ化**（Hosting と同様に
  `main` マージ時に自動反映）: ドリフトの構造的な原因を根本から断てる一方、レビューを経ない
  まま誤ったルールが本番に即反映されるリスクがある。ルール変更の頻度が低いことも踏まえ、
  今回は見送った。将来、変更頻度が増えるか、レビュープロセスを別途整備できた場合は再検討する。
- **PITR の有効化**: 上記の通り費用面から見送り。

## 影響範囲

- `firestore.rules` / `firestore.indexes.json` / `firebase.json`: リポジトリ管理を継続
- `docs/FIREBASE_ARCHITECTURE.md`: §4.1 / §4.3 / §7 を実態に合わせて修正（v7.2）。
  ルール本文のベタ書きを解消し `firestore.rules` を参照する形に変更、Storage ルールを
  「未実装ドラフト」と明記、ロケーション誤記を修正
- `CLAUDE.md` §4: 既存のルール記述（`07b4c15` で修正済み）と整合
- Firestore データベース設定（コンソール/gcloud側）: 削除保護を `ENABLED` に変更

## 関連

- CLAUDE.md §4「実装上の注意」の既存ルール
- `docs/FIREBASE_ARCHITECTURE.md` §7 デプロイ
