import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../timeline/domain/year_month.dart';
import '../domain/coach_turn.dart';
import '../logic/coach_prompt.dart';
import '../logic/coach_tools.dart';
import 'coach_repository.dart';

/// 1メッセージあたりの Function Calling ラウンド上限。
///
/// モデルが結果を見て追加の関数呼び出しを要求し続けるケースへの歯止め
/// （コスト・無限ループ対策）。
const _maxFunctionCallRounds = 3;

/// `firebase_ai`（Gemini, Agent Platform バックエンド）への唯一の依存点。
///
/// バックエンドは Vertex AI の後継である Agent Platform を使う
/// （`FirebaseAI.agentPlatform()`。`vertexAI()` は非推奨）。モデルは
/// Function Calling に対応した `gemini-3.7-flash`。
///
/// [ChatSession] を保持することで会話履歴を維持する。セッションは
/// アプリ実行中のみ（メモリ内）で、永続化はしない。
class GeminiCoachRepository implements CoachRepository {
  ChatSession? _chat;

  ChatSession _ensureChat() {
    final existing = _chat;
    if (existing != null) return existing;

    final today = YearMonth.fromDateTime(DateTime.now()).toString();
    final model = FirebaseAI.agentPlatform().generativeModel(
      model: 'gemini-3.7-flash',
      systemInstruction: Content.system(
        buildCoachSystemPrompt(todayYearMonth: today),
      ),
      tools: [Tool.functionDeclarations(buildCoachToolDeclarations())],
    );
    return _chat = model.startChat();
  }

  @override
  Future<CoachTurn> send(
    String text, {
    required ToolExecutor executeTool,
  }) async {
    final chat = _ensureChat();
    var response = await chat.sendMessage(Content.text(text));

    for (var round = 0; round < _maxFunctionCallRounds; round++) {
      final calls = response.functionCalls.toList();
      if (calls.isEmpty) break;

      // モデルは複数の関数を同時に呼ぶことも、結果を見て追加で呼び直す
      // こともあるため、1件だけ処理する実装にしない。
      final results = <FunctionResponse>[];
      for (final call in calls) {
        final result = await executeTool(call.name, call.args);
        results.add(FunctionResponse(call.name, result, id: call.id));
      }
      response = await chat.sendMessage(Content.functionResponses(results));
    }

    return CoachTurn(
      responseText: response.text ?? 'うまく応答を作れませんでした。もう一度お試しください。',
    );
  }
}

final coachRepositoryProvider = Provider<CoachRepository>((ref) {
  return GeminiCoachRepository();
});
