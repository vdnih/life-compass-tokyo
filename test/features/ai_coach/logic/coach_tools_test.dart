import 'package:flutter_test/flutter_test.dart';
import 'package:my_career_app/features/ai_coach/logic/coach_tools.dart';
import 'package:my_career_app/features/catalog/data/predefined_catalog_registry.dart';
import 'package:my_career_app/features/open_data/data/institutional_limits.dart';
import 'package:my_career_app/features/timeline/data/goal_template_data.dart';

void main() {
  group('buildCoachToolDeclarations', () {
    final declarations = buildCoachToolDeclarations();

    test('applyGoalTemplate / addEventFromCatalog / getInstitutionalLimit の3件のみを公開すること', () {
      expect(
        declarations.map((d) => d.name),
        unorderedEquals([
          'applyGoalTemplate',
          'addEventFromCatalog',
          'getInstitutionalLimit',
        ]),
      );
    });

    /// [FunctionDeclaration] は `parameters` を公開 getter として持たないため
    /// （`toJson()` 経由でのみアクセスできる）、生成した OpenAPI 形式の JSON から
    /// 該当パラメータの `enum` 配列を取り出す。
    List<String> enumValuesOf(String functionName, String paramName) {
      final decl = declarations.firstWhere((d) => d.name == functionName);
      final json = decl.toJson();
      final params = json['parameters'] as Map<String, Object?>;
      final properties = params['properties'] as Map<String, Object?>;
      final schema = properties[paramName] as Map<String, Object?>;
      return (schema['enum'] as List).cast<String>();
    }

    test('applyGoalTemplate の templateId enum が GoalTemplateRegistry と一致すること', () {
      expect(
        enumValuesOf('applyGoalTemplate', 'templateId'),
        unorderedEquals(GoalTemplateRegistry.templates.map((t) => t.id)),
      );
    });

    test('addEventFromCatalog の catalogId enum が PredefinedCatalogRegistry と一致すること', () {
      expect(
        enumValuesOf('addEventFromCatalog', 'catalogId'),
        unorderedEquals(PredefinedCatalogRegistry.all.map((e) => e.id)),
      );
    });

    test('getInstitutionalLimit の catalogId enum が institutionalLimits の catalogId 集合と一致すること', () {
      expect(
        enumValuesOf('getInstitutionalLimit', 'catalogId'),
        unorderedEquals(institutionalLimits.map((l) => l.catalogId).toSet()),
      );
    });
  });

  group('institutionalLimitResponsesFor', () {
    test('該当する catalogId の全件を返すこと（1つの catalogId に複数件ありうる）', () {
      final childbirthLimits =
          institutionalLimits.where((l) => l.catalogId == 'childbirth').length;
      expect(childbirthLimits, greaterThan(1));

      final responses = institutionalLimitResponsesFor('childbirth');
      expect(responses.length, childbirthLimits);
    });

    test('各レスポンスが message と出典（sourceName/sourcePublisher）を持つこと', () {
      final responses = institutionalLimitResponsesFor('childcare-leave');
      expect(responses, isNotEmpty);
      for (final r in responses) {
        expect(r['message'], isA<String>());
        expect(r['sourceName'], isA<String>());
        expect(r['sourcePublisher'], isA<String>());
      }
    });

    test('未知の catalogId には空リストを返すこと', () {
      expect(institutionalLimitResponsesFor('no-such-catalog-id'), isEmpty);
    });

    test('制度上限の message に「平均」という語を含まないこと（PDR-008）', () {
      // AI は getInstitutionalLimit の結果だけを制度の根拠にする
      // （coach_prompt.dart）。B1（制度上限）のメッセージに「平均」という
      // 語が紛れ込むと、AI がそれを平均値であるかのように話しかねない。
      for (final limit in institutionalLimits) {
        expect(limit.message, isNot(contains('平均')));
      }
    });
  });
}
