import 'package:flutter_test/flutter_test.dart';
import 'package:my_career_app/features/timeline/domain/life_event.dart';
import 'package:my_career_app/features/timeline/domain/year_month.dart';

void main() {
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

  group('LifeEvent の機能一覧（v6.0 catalogId 方式）', () {
    test('catalogId フィールドが正しく保存されること', () {
      const event = LifeEvent(
        id: 'test-id',
        date: '2023-08',
        title: 'テスト',
        description: '',
        catalogId: 'joining-company',
      );

      expect(event.catalogId, 'joining-company');
    });

    test('budgetYen が null の場合も toJson/fromJson で正しく処理されること', () {
      const event = LifeEvent(
        id: 'test-id',
        date: '2023-08',
        title: 'テスト',
        description: '',
        catalogId: 'joining-company',
      );

      final json = event.toJson();
      final restored = LifeEvent.fromJson(json);

      expect(restored.budgetYen, isNull);
    });

    test('budgetYen を設定できること', () {
      const event = LifeEvent(
        id: 'test-id',
        date: '2023-08',
        title: 'テスト',
        description: '',
        catalogId: 'wedding-ceremony',
        budgetYen: 3000000,
      );

      expect(event.budgetYen, 3000000);
    });

    test('budgetYen が toJson/fromJson でラウンドトリップすること', () {
      const event = LifeEvent(
        id: 'test-id',
        date: '2023-08',
        title: 'テスト',
        description: '',
        catalogId: 'wedding-ceremony',
        budgetYen: 3000000,
      );

      final json = event.toJson();
      final restored = LifeEvent.fromJson(json);

      expect(restored.budgetYen, 3000000);
    });

    test('catalogId が toJson/fromJson でラウンドトリップすること', () {
      const event = LifeEvent(
        id: 'test-id',
        date: '2023-08',
        title: 'テスト',
        description: '',
        catalogId: 'job-change',
      );

      final json = event.toJson();
      final restored = LifeEvent.fromJson(json);

      expect(restored.catalogId, 'job-change');
    });

    test('date文字列 ("yyyy-MM") から YearMonth を取得できること', () {
      const event = LifeEvent(
        id: 'test-id',
        date: '2023-08',
        title: 'テスト',
        description: 'テスト詳細',
        catalogId: 'joining-company',
      );

      expect(event.yearMonth, const YearMonth(2023, 8));
    });

    test('endDate が設定されている場合、hasDuration は true を返すこと', () {
      const event = LifeEvent(
        id: 'test-id',
        date: '2023-08',
        endDate: '2024-03',
        title: 'テスト',
        description: '詳細',
        catalogId: 'childcare-leave',
      );

      expect(event.hasDuration, isTrue);
    });

    test('endDate が未指定の場合、hasDuration は false を返すこと', () {
      const event = LifeEvent(
        id: 'test-id',
        date: '2023-08',
        title: 'テスト',
        description: '詳細',
        catalogId: 'joining-company',
      );

      expect(event.hasDuration, isFalse);
    });

    test('デフォルトのステータスは EventStatus.recorded であること', () {
      const event = LifeEvent(
        id: 'test-id',
        date: '2023-08',
        title: 'テスト',
        description: '',
        catalogId: 'joining-company',
      );

      expect(event.status, EventStatus.recorded);
    });

    test('将来計画イベントの isFuturePlan が true を返すこと', () {
      const event = LifeEvent(
        id: 'test-id',
        date: '2028-04',
        title: '起業',
        description: '',
        catalogId: 'entrepreneurship',
        status: EventStatus.goal,
      );

      expect(event.isFuturePlan, isTrue);
    });

    test('copyWith メソッドで catalogId を変更できること', () {
      const event = LifeEvent(
        id: 'test-id',
        date: '2023-08',
        title: '元のタイトル',
        description: '元の詳細',
        catalogId: 'joining-company',
      );

      final updated = event.copyWith(catalogId: 'job-change');

      expect(updated.catalogId, 'job-change');
      expect(updated.date, '2023-08');
    });

    test('copyWith メソッドで budgetYen を変更できること', () {
      const event = LifeEvent(
        id: 'test-id',
        date: '2023-08',
        title: 'テスト',
        description: '',
        catalogId: 'wedding-ceremony',
      );

      final updated = event.copyWith(budgetYen: 500000);

      expect(updated.budgetYen, 500000);
    });

    test('同じプロパティを持つ2つのインスタンスは等しいこと', () {
      const event1 = LifeEvent(
        id: 'test-id',
        date: '2023-08',
        title: 'テスト',
        description: '詳細',
        catalogId: 'joining-company',
      );
      const event2 = LifeEvent(
        id: 'test-id',
        date: '2023-08',
        title: 'テスト',
        description: '詳細',
        catalogId: 'joining-company',
      );

      expect(event1, equals(event2));
    });

    test('デフォルトの isGoal は false であること', () {
      const event = LifeEvent(
        id: 'test-id',
        date: '2023-08',
        title: 'テスト',
        description: '',
        catalogId: 'joining-company',
      );

      expect(event.isGoal, isFalse);
    });

    test('goalId を設定できること', () {
      const event = LifeEvent(
        id: 'test-id',
        date: '2028-06',
        title: '関連イベント',
        description: '',
        catalogId: 'job-change',
        goalId: 'goal-123',
      );

      expect(event.goalId, 'goal-123');
    });
  });
}
