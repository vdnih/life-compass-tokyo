import 'package:flutter/foundation.dart';

/// AI コーチとの1往復（ユーザー発話 → AI 応答）の結果。
///
/// [CoachRepository] はタイムライン操作の Provider を知らない
/// （Function Calling の実行は [ToolExecutor] コールバック経由で
/// 呼び出し元に委譲する）ため、ここに持つのは表示用のテキストのみ。
/// 追加されたイベント・依存関係の集計は呼び出し元（`ChatController`）が行い、
/// `ChatSendResult` として持つ。
@immutable
class CoachTurn {
  /// チャットに表示する AI の最終応答テキスト
  final String responseText;

  const CoachTurn({required this.responseText});
}
