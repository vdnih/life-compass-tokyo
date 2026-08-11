# ADR-023: マージ方針を Squash and merge に変更する

**Date**: 2026-08-11
**Status**: Accepted

## 背景

CLAUDE.md §6 には「マージは regular merge（squash しない）。コミット粒度を `main` の履歴にそのまま残す。ADR が過去のコミットハッシュ（例: `docs/adr/015-firebase-config-as-code.md` の `07b4c15`）を直接参照する慣習があり、squash すると参照先が潰れる」というルールがあった。

一方で `projects/` 配下の他プロダクト（`decss` など）は元々 squash merge を使っており、`my_career_app` だけが regular merge という運用差があった。全プロダクトを「一人 + Claude」で開発しており要件に差はないため、マージ方針をプロダクト横断で統一することにした（横断メタ情報は `projects/CLAUDE.md`）。

regular merge を維持したい理由だった「ADR がコミットハッシュを参照する」問題は、GitHub 側のリポジトリ設定を確認したところ解消できることが分かった。このリポジトリの squash マージ設定は `squash_merge_commit_message=COMMIT_MESSAGES` になっており、squash してもブランチ側の個々のコミットメッセージは squash コミットの本文にそのまま残る。つまり「コミット粒度の記録」自体は squash しても失われない。

## 決定

- PR のマージは **Squash and merge** に統一する。
- commit は引き続き論理的な作業単位ごとに切る（squash 本文に残るため、粒度を分ける意味は失われない）。
- 経緯を残す文書（ADR 含む）で過去の変更を参照する際は、コミットハッシュではなく **PR 番号**（例: `#42`）を使う。squash 前のブランチ側コミットハッシュは squash 後の `main` からは辿れなくなるが、PR ページ自体はハッシュに関わらず永続的に残る。
- 既存の `docs/adr/015-firebase-config-as-code.md` のハッシュ参照（`07b4c15`）はそのまま残す。これは既にマージ済みのコミットであり、本方針変更の影響を受けない（今後 squash された PR の中身を後から参照する必要が生じた場合は、そのコミットが属していた PR 番号を探す）。

## 検討したが採らなかった案

- **regular merge を維持する**: `main` の履歴に個々のコミットがそのまま残るのは分かりやすいが、squash でも本文にメッセージが残る以上、実質的な情報損失はない。一方で `main` の履歴に試行錯誤のコミットが混じらない squash merge の方が「1 PR = 1 Issue の解決」として読みやすく、他プロダクトとの運用差もなくなる。

## 影響範囲

- `CLAUDE.md` §6: 「マージは regular merge（squash しない）」の記述を Squash and merge に変更し、経緯参照は PR 番号を使うよう追記。
- 新規: `docs/adr/023-squash-merge-policy.md`（本 ADR）

## 関連

- `projects/CLAUDE.md`（`## Git 運用（全プロダクト共通）` として横断方針を記載）
- `docs/adr/015-firebase-config-as-code.md`（既存のハッシュ参照。書き換え対象外）
