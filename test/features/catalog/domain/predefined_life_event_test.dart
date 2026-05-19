import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_career_app/features/catalog/domain/predefined_life_event.dart';

void main() {
  group('PredefinedLifeEvent の仕様', () {
    test('const コンストラクタで生成できること', () {
      const event = PredefinedLifeEvent(
        id: 'test-event',
        label: 'テストイベント',
        group: LifeEventGroup.marriage,
        icon: Icons.favorite,
        color: Color(0xFFD4698F),
        hardRules: [],
        softRules: [],
      );

      expect(event.id, 'test-event');
      expect(event.label, 'テストイベント');
      expect(event.group, LifeEventGroup.marriage);
    });

    test('hardRules が空リストのとき正しく扱えること', () {
      const event = PredefinedLifeEvent(
        id: 'test-event',
        label: 'テストイベント',
        group: LifeEventGroup.career,
        icon: Icons.work,
        color: Color(0xFF5B7FD4),
        hardRules: [],
        softRules: [],
      );

      expect(event.hardRules, isEmpty);
    });

    test('softRules が空リストのとき正しく扱えること', () {
      const event = PredefinedLifeEvent(
        id: 'test-event',
        label: 'テストイベント',
        group: LifeEventGroup.childbirth,
        icon: Icons.child_care,
        color: Color(0xFFE87EA1),
        hardRules: [],
        softRules: [],
      );

      expect(event.softRules, isEmpty);
    });

    test('hardRules と softRules を持つイベントを生成できること', () {
      const event = PredefinedLifeEvent(
        id: 'wedding-ceremony',
        label: '結婚式',
        group: LifeEventGroup.marriage,
        icon: Icons.celebration,
        color: Color(0xFFD4698F),
        defaultBudgetYen: 3000000,
        hardRules: [
          HardPrecedence(
            predecessorCatalogId: 'venue-decision',
            message: '結婚式場決定の後に置かれるイベントの目安です',
          ),
        ],
        softRules: [
          SoftPrecedence(
            predecessorCatalogId: 'venue-decision',
            recommendedMinMonthsAfter: 6,
            message: '式場決定から6ヶ月以上の準備期間が一般的な目安です',
          ),
        ],
      );

      expect(event.hardRules.length, 1);
      expect(event.softRules.length, 1);
      expect(event.defaultBudgetYen, 3000000);
    });

    test('defaultDurationMonths が null のとき単発イベントとして扱えること', () {
      const event = PredefinedLifeEvent(
        id: 'test-event',
        label: 'テスト',
        group: LifeEventGroup.money,
        icon: Icons.savings,
        color: Color(0xFFCCA87A),
        hardRules: [],
        softRules: [],
      );

      expect(event.defaultDurationMonths, isNull);
    });

    test('defaultDurationMonths を設定できること', () {
      const event = PredefinedLifeEvent(
        id: 'pregnancy',
        label: '妊娠',
        group: LifeEventGroup.childbirth,
        icon: Icons.pregnant_woman,
        color: Color(0xFFE87EA1),
        defaultDurationMonths: 10,
        hardRules: [],
        softRules: [],
      );

      expect(event.defaultDurationMonths, 10);
    });
  });

  group('LifeEventGroup.label の仕様', () {
    test('marriage の label が「結婚」であること', () {
      expect(LifeEventGroup.marriage.label, '結婚');
    });

    test('childbirth の label が「出産」であること', () {
      expect(LifeEventGroup.childbirth.label, '出産');
    });

    test('career の label が「キャリア」であること', () {
      expect(LifeEventGroup.career.label, 'キャリア');
    });

    test('lifestyle の label が「住まい」であること', () {
      expect(LifeEventGroup.lifestyle.label, '住まい');
    });

    test('travel の label が「旅行」であること', () {
      expect(LifeEventGroup.travel.label, '旅行');
    });

    test('learning の label が「学び」であること', () {
      expect(LifeEventGroup.learning.label, '学び');
    });

    test('money の label が「お金」であること', () {
      expect(LifeEventGroup.money.label, 'お金');
    });

    test('すべてのグループが日本語ラベルを持つこと', () {
      for (final group in LifeEventGroup.values) {
        expect(group.label, isNotEmpty);
      }
    });
  });

  group('HardPrecedence の仕様', () {
    test('const コンストラクタで生成できること', () {
      const rule = HardPrecedence(
        predecessorCatalogId: 'propose',
        message: 'プロポーズの後に置かれるイベントの目安です',
      );

      expect(rule.predecessorCatalogId, 'propose');
      expect(rule.message, 'プロポーズの後に置かれるイベントの目安です');
    });

    test('minMonthsAfter が null のとき期間制約なしとして扱えること', () {
      const rule = HardPrecedence(
        predecessorCatalogId: 'propose',
        message: 'テスト',
      );

      expect(rule.minMonthsAfter, isNull);
    });

    test('minMonthsAfter を設定できること', () {
      const rule = HardPrecedence(
        predecessorCatalogId: 'wedding-ceremony',
        minMonthsAfter: 12,
        message: '結婚式から12ヶ月後の1周年記念です',
      );

      expect(rule.minMonthsAfter, 12);
    });
  });

  group('SoftPrecedence の仕様', () {
    test('const コンストラクタで生成できること', () {
      const rule = SoftPrecedence(
        predecessorCatalogId: 'dating-start',
        recommendedMinMonthsAfter: 6,
        message: 'お付き合い開始から6ヶ月以上経ってからの同棲が一般的な目安です',
      );

      expect(rule.predecessorCatalogId, 'dating-start');
      expect(rule.recommendedMinMonthsAfter, 6);
    });
  });
}
