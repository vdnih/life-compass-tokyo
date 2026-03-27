import 'package:flutter_test/flutter_test.dart';
import 'package:my_career_app/features/timeline/domain/goal_template.dart';
import 'package:my_career_app/features/timeline/domain/life_event.dart';

void main() {
  group('GoalTemplate の仕様', () {
    test('正しいパラメータで GoalTemplate が生成されること', () {
      const template = GoalTemplate(
        id: 'template-childbirth',
        name: '出産',
        description: '出産を目指したライフプランテンプレート',
        goalCategory: EventCategory.childbirth,
        relatedEvents: [],
      );

      expect(template.id, 'template-childbirth');
      expect(template.name, '出産');
      expect(template.description, '出産を目指したライフプランテンプレート');
      expect(template.goalCategory, EventCategory.childbirth);
      expect(template.relatedEvents, isEmpty);
    });

    test('relatedEvents を含む GoalTemplate が生成されること', () {
      const template = GoalTemplate(
        id: 'template-jobchange',
        name: '転職',
        description: '転職を目標としたテンプレート',
        goalCategory: EventCategory.jobChange,
        relatedEvents: [
          TemplateEvent(
            titleTemplate: '転職活動開始',
            category: EventCategory.jobChange,
            offsetMonthsFromGoal: -6,
          ),
        ],
      );

      expect(template.relatedEvents.length, 1);
      expect(template.relatedEvents.first.titleTemplate, '転職活動開始');
    });
  });

  group('TemplateEvent の仕様', () {
    test('ゴール前のイベントは負の offsetMonthsFromGoal を持つこと', () {
      const event = TemplateEvent(
        titleTemplate: '転職活動開始',
        category: EventCategory.jobChange,
        offsetMonthsFromGoal: -6,
      );

      expect(event.offsetMonthsFromGoal, -6);
      expect(event.offsetMonthsFromGoal.isNegative, isTrue);
    });

    test('ゴール後のイベントは正の offsetMonthsFromGoal を持つこと', () {
      const event = TemplateEvent(
        titleTemplate: '育休開始',
        category: EventCategory.childcareLeave,
        offsetMonthsFromGoal: 1,
      );

      expect(event.offsetMonthsFromGoal, 1);
      expect(event.offsetMonthsFromGoal > 0, isTrue);
    });

    test('durationMonths が指定された TemplateEvent が生成されること', () {
      const event = TemplateEvent(
        titleTemplate: '産休',
        category: EventCategory.maternityLeave,
        offsetMonthsFromGoal: -2,
        durationMonths: 8,
      );

      expect(event.durationMonths, 8);
    });

    test('デフォルトの durationMonths は null であること', () {
      const event = TemplateEvent(
        titleTemplate: '転職活動',
        category: EventCategory.jobChange,
        offsetMonthsFromGoal: -3,
      );

      expect(event.durationMonths, isNull);
    });

    test('ゴールイベント自体のオフセットは 0 であること', () {
      const event = TemplateEvent(
        titleTemplate: '出産',
        category: EventCategory.childbirth,
        offsetMonthsFromGoal: 0,
      );

      expect(event.offsetMonthsFromGoal, 0);
    });
  });
}
