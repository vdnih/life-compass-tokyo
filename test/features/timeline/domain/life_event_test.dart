import 'package:flutter_test/flutter_test.dart';
import 'package:my_career_app/features/timeline/domain/life_event.dart';

void main() {
  group('EventCategory の仕様', () {
    test('仕事系カテゴリは isWork == true を返すこと', () {
      expect(EventCategory.joining.isWork, isTrue);
      expect(EventCategory.jobChange.isWork, isTrue);
      expect(EventCategory.promotion.isWork, isTrue);
      expect(EventCategory.retirement.isWork, isTrue);
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
      final event = LifeEvent(
        date: '2023-08',
        title: 'テスト',
        description: 'テスト詳細',
        category: EventCategory.joining,
      );

      expect(event.dateTime.year, 2023);
      expect(event.dateTime.month, 8);
    });

    test('endDate文字列 ("yyyy-MM") から正しい DateTime を取得できること', () {
      final event = LifeEvent(
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
      final event = LifeEvent(
        date: '2023-08',
        title: 'テスト',
        description: 'テスト詳細',
        category: EventCategory.joining,
      );

      expect(event.endDateTime, isNull);
    });

    test('endDate が設定されている場合、hasDuration は true を返すこと', () {
      final event = LifeEvent(
        date: '2023-08',
        endDate: '2024-03',
        title: 'テスト',
        description: '詳細',
        category: EventCategory.joining,
      );

      expect(event.hasDuration, isTrue);
    });

    test('endDate が未指定の場合、hasDuration は false を返すこと', () {
      final event = LifeEvent(
        date: '2023-08',
        title: 'テスト',
        description: '詳細',
        category: EventCategory.joining,
      );

      expect(event.hasDuration, isFalse);
    });

    test('isWork は category.isWork を返すこと', () {
      final workEvent = LifeEvent(
        date: '2023-08',
        title: '入社',
        description: '',
        category: EventCategory.joining,
      );
      final privateEvent = LifeEvent(
        date: '2023-08',
        title: '結婚',
        description: '',
        category: EventCategory.marriage,
      );

      expect(workEvent.isWork, isTrue);
      expect(privateEvent.isWork, isFalse);
    });

    test('デフォルトのステータスは EventStatus.recorded であること', () {
      final event = LifeEvent(
        date: '2023-08',
        title: 'テスト',
        description: '',
        category: EventCategory.joining,
      );

      expect(event.status, EventStatus.recorded);
    });

    test('将来計画イベントの isFuturePlan が true を返すこと', () {
      final event = LifeEvent(
        date: '2028-04',
        title: '起業',
        description: '',
        category: EventCategory.startup,
        status: EventStatus.goal,
      );

      expect(event.isFuturePlan, isTrue);
    });

    test('copyWith メソッドで一部のプロパティを変更した新しいインスタンスを生成できること', () {
      final event = LifeEvent(
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
      final event = LifeEvent(
        date: '2028-04',
        title: '起業',
        description: '',
        category: EventCategory.startup,
      );

      final updated = event.copyWith(status: EventStatus.goal);

      expect(updated.status, EventStatus.goal);
    });

    test('同じプロパティを持つ2つのインスタンスは等しいこと', () {
      final event1 = LifeEvent(
        date: '2023-08',
        title: 'テスト',
        description: '詳細',
        category: EventCategory.joining,
      );
      final event2 = LifeEvent(
        date: '2023-08',
        title: 'テスト',
        description: '詳細',
        category: EventCategory.joining,
      );

      expect(event1, equals(event2));
    });
  });
}
