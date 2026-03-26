import 'package:flutter_test/flutter_test.dart';
import 'package:my_career_app/features/timeline/domain/life_event.dart';

void main() {
  group('EventCategory の仕様', () {
    test('仕事系カテゴリは isWork == true を返すこと', () {
      expect(EventCategory.joining.isWork, isTrue);
      expect(EventCategory.jobChange.isWork, isTrue);
      expect(EventCategory.promotion.isWork, isTrue);
      expect(EventCategory.retirement.isWork, isTrue);
      expect(EventCategory.maternityLeave.isWork, isTrue);
      expect(EventCategory.startup.isWork, isTrue);
      expect(EventCategory.certification.isWork, isTrue);
      expect(EventCategory.sideJob.isWork, isTrue);
    });

    test('プライベート系カテゴリは isWork == false を返すこと', () {
      expect(EventCategory.marriage.isWork, isFalse);
      expect(EventCategory.childbirth.isWork, isFalse);
      expect(EventCategory.childcareLeave.isWork, isFalse);
      expect(EventCategory.returnToWork.isWork, isFalse);
      expect(EventCategory.moving.isWork, isFalse);
      expect(EventCategory.travel.isWork, isFalse);
      expect(EventCategory.education.isWork, isFalse);
      expect(EventCategory.caregiving.isWork, isFalse);
    });

    test('各カテゴリは日本語ラベルを持つこと', () {
      expect(EventCategory.joining.label, '入社');
      expect(EventCategory.marriage.label, '結婚');
      expect(EventCategory.childbirth.label, '出産');
      expect(EventCategory.childcareLeave.label, '育休');
    });

    test('maternityLeave の isWork が true であること', () {
      expect(EventCategory.maternityLeave.isWork, isTrue);
    });

    test('maternityLeave の label が 産休 であること', () {
      expect(EventCategory.maternityLeave.label, '産休');
    });
  });

  group('EventStatus の仕様', () {
    test('各ステータスは日本語ラベルを持つこと', () {
      expect(EventStatus.recorded.label, '記録');
      expect(EventStatus.planned.label, '予定');
      expect(EventStatus.goal.label, '目標');
      expect(EventStatus.considering.label, '検討中');
    });

    test('isFuturePlan は recorded 以外で true を返すこと', () {
      expect(EventStatus.recorded.isFuturePlan, isFalse);
      expect(EventStatus.planned.isFuturePlan, isTrue);
      expect(EventStatus.goal.isFuturePlan, isTrue);
      expect(EventStatus.considering.isFuturePlan, isTrue);
    });
  });

  group('LifeEvent の機能一覧（仕様）', () {
    test('date文字列 ("yyyy-MM") から正しい DateTime を取得できること', () {
      const event = LifeEvent(
        id: 'test-id',
        date: '2023-08',
        title: 'テスト',
        description: 'テスト詳細',
        category: EventCategory.joining,
      );

      expect(event.dateTime.year, 2023);
      expect(event.dateTime.month, 8);
    });

    test('endDate文字列 ("yyyy-MM") から正しい DateTime を取得できること', () {
      const event = LifeEvent(
        id: 'test-id',
        date: '2023-08',
        endDate: '2025-12',
        title: 'テスト',
        description: 'テスト詳細',
        category: EventCategory.joining,
      );

      expect(event.endDateTime, isNotNull);
      expect(event.endDateTime!.year, 2025);
      expect(event.endDateTime!.month, 12);
    });

    test('endDate が未指定の場合は null を返すこと', () {
      const event = LifeEvent(
        id: 'test-id',
        date: '2023-08',
        title: 'テスト',
        description: 'テスト詳細',
        category: EventCategory.joining,
      );

      expect(event.endDateTime, isNull);
    });

    test('endDate が設定されている場合、hasDuration は true を返すこと', () {
      const event = LifeEvent(
        id: 'test-id',
        date: '2023-08',
        endDate: '2024-03',
        title: 'テスト',
        description: '詳細',
        category: EventCategory.joining,
      );

      expect(event.hasDuration, isTrue);
    });

    test('endDate が未指定の場合、hasDuration は false を返すこと', () {
      const event = LifeEvent(
        id: 'test-id',
        date: '2023-08',
        title: 'テスト',
        description: '詳細',
        category: EventCategory.joining,
      );

      expect(event.hasDuration, isFalse);
    });

    test('isWork は category.isWork を返すこと', () {
      const workEvent = LifeEvent(
        id: 'test-id-work',
        date: '2023-08',
        title: '入社',
        description: '',
        category: EventCategory.joining,
      );
      const privateEvent = LifeEvent(
        id: 'test-id-private',
        date: '2023-08',
        title: '結婚',
        description: '',
        category: EventCategory.marriage,
      );

      expect(workEvent.isWork, isTrue);
      expect(privateEvent.isWork, isFalse);
    });

    test('デフォルトのステータスは EventStatus.recorded であること', () {
      const event = LifeEvent(
        id: 'test-id',
        date: '2023-08',
        title: 'テスト',
        description: '',
        category: EventCategory.joining,
      );

      expect(event.status, EventStatus.recorded);
    });

    test('将来計画イベントの isFuturePlan が true を返すこと', () {
      const event = LifeEvent(
        id: 'test-id',
        date: '2028-04',
        title: '起業',
        description: '',
        category: EventCategory.startup,
        status: EventStatus.goal,
      );

      expect(event.isFuturePlan, isTrue);
    });

    test('copyWith メソッドで一部のプロパティを変更した新しいインスタンスを生成できること', () {
      const event = LifeEvent(
        id: 'test-id',
        date: '2023-08',
        title: '元のタイトル',
        description: '元の詳細',
        category: EventCategory.joining,
      );

      final updated = event.copyWith(
        title: '変更後のタイトル',
        category: EventCategory.promotion,
      );

      expect(updated.title, '変更後のタイトル');
      expect(updated.category, EventCategory.promotion);
      expect(updated.date, '2023-08');
      expect(updated.description, '元の詳細');
      expect(updated.status, EventStatus.recorded);
    });

    test('copyWith メソッドで status を変更できること', () {
      const event = LifeEvent(
        id: 'test-id',
        date: '2028-04',
        title: '起業',
        description: '',
        category: EventCategory.startup,
      );

      final updated = event.copyWith(status: EventStatus.goal);

      expect(updated.status, EventStatus.goal);
    });

    test('同じプロパティを持つ2つのインスタンスは等しいこと', () {
      const event1 = LifeEvent(
        id: 'test-id',
        date: '2023-08',
        title: 'テスト',
        description: '詳細',
        category: EventCategory.joining,
      );
      const event2 = LifeEvent(
        id: 'test-id',
        date: '2023-08',
        title: 'テスト',
        description: '詳細',
        category: EventCategory.joining,
      );

      expect(event1, equals(event2));
    });

    test('デフォルトの isGoal は false であること', () {
      const event = LifeEvent(
        id: 'test-id',
        date: '2023-08',
        title: 'テスト',
        description: '',
        category: EventCategory.joining,
      );

      expect(event.isGoal, isFalse);
    });

    test('isGoal を true に設定できること', () {
      const event = LifeEvent(
        id: 'test-id',
        date: '2028-06',
        title: 'ゴールイベント',
        description: '',
        category: EventCategory.childbirth,
        isGoal: true,
      );

      expect(event.isGoal, isTrue);
    });

    test('goalId を設定できること', () {
      const event = LifeEvent(
        id: 'test-id',
        date: '2028-06',
        title: '関連イベント',
        description: '',
        category: EventCategory.jobChange,
        goalId: 'goal-123',
      );

      expect(event.goalId, 'goal-123');
    });

    test('デフォルトの goalId は null であること', () {
      const event = LifeEvent(
        id: 'test-id',
        date: '2023-08',
        title: 'テスト',
        description: '',
        category: EventCategory.joining,
      );

      expect(event.goalId, isNull);
    });

    test('copyWith メソッドで isGoal を変更できること', () {
      const event = LifeEvent(
        id: 'test-id',
        date: '2028-06',
        title: '目標',
        description: '',
        category: EventCategory.childbirth,
      );

      final updated = event.copyWith(isGoal: true);

      expect(updated.isGoal, isTrue);
    });

    test('copyWith メソッドで goalId を変更できること', () {
      const event = LifeEvent(
        id: 'test-id',
        date: '2028-06',
        title: '関連イベント',
        description: '',
        category: EventCategory.jobChange,
      );

      final updated = event.copyWith(goalId: 'goal-456');

      expect(updated.goalId, 'goal-456');
    });
  });
}
