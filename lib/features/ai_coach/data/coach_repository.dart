import '../domain/coach_turn.dart';

/// Function Calling の1回の呼び出しを実行し、Gemini に返す Function Response
/// （`Map<String, Object?>`）を返す。
///
/// 呼び出し元（[ChatController]）がタイムライン操作の Provider を実際に叩き、
/// 追加されたイベント・依存関係を集計する。[CoachRepository] 実装は Provider
/// に依存しないよう、実行そのものはこのコールバックに委譲する。
typedef ToolExecutor = Future<Map<String, Object?>> Function(
  String name,
  Map<String, Object?> args,
);

/// AI コーチとの対話を仲介するリポジトリの抽象。
///
/// テストでは Fake 実装に差し替え、実 API を叩かない（CLAUDE.md §5）。
abstract class CoachRepository {
  /// [text] を送信し、必要な Function Calling を [executeTool] 経由で
  /// 実行しながら最終応答を返す。
  Future<CoachTurn> send(String text, {required ToolExecutor executeTool});
}
