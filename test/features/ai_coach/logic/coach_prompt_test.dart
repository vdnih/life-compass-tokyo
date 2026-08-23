import 'package:flutter_test/flutter_test.dart';
import 'package:my_career_app/features/ai_coach/logic/coach_prompt.dart';

void main() {
  group('buildCoachSystemPrompt', () {
    test('渡した todayYearMonth をそのまま埋め込むこと', () {
      final prompt = buildCoachSystemPrompt(todayYearMonth: '2027-04');
      expect(prompt, contains('2027-04'));
    });

    test('getInstitutionalLimit の結果のみを制度の根拠にする旨を明記すること', () {
      final prompt = buildCoachSystemPrompt(todayYearMonth: '2027-04');
      expect(prompt, contains('getInstitutionalLimit'));
    });

    test('平均値・比較を口にしない方針（PDR-008 Value 1）を明記すること', () {
      final prompt = buildCoachSystemPrompt(todayYearMonth: '2027-04');
      expect(prompt, contains('比較'));
      expect(prompt, contains('平均'));
    });
  });
}
