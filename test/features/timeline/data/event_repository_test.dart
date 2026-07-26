import 'package:flutter_test/flutter_test.dart';
import 'package:my_career_app/features/timeline/data/event_repository.dart';

import '../../../support/builders.dart';

void main() {
  group('InMemoryEventRepository', () {
    late InMemoryEventRepository repository;

    setUp(() {
      repository = InMemoryEventRepository();
    });

    test('初期状態でゲスト向けのサンプルイベントを返すこと', () async {
      final events = await repository.fetchEvents();

      expect(events, isNotEmpty);
    });

    test('保存したイベントが取得結果に含まれること', () async {
      final event = buildLifeEvent(id: 'new-1', title: '新しいイベント');

      await repository.saveEvent(event);

      expect(await repository.fetchEvents(), contains(event));
    });

    test('削除したイベントが取得結果から除かれること', () async {
      final event = buildLifeEvent(id: 'new-1');
      await repository.saveEvent(event);

      await repository.deleteEvent(event);

      expect(await repository.fetchEvents(), isNot(contains(event)));
    });

    test('更新すると同じidのイベントが置き換わること', () async {
      final event = buildLifeEvent(id: 'new-1', title: '変更前');
      await repository.saveEvent(event);

      await repository.updateEvent(event.copyWith(title: '変更後'));

      final events = await repository.fetchEvents();
      final updated = events.firstWhere((e) => e.id == 'new-1');
      expect(updated.title, '変更後');
      expect(
        events.where((e) => e.id == 'new-1'),
        hasLength(1),
        reason: '更新で件数が増えないこと',
      );
    });

    test('存在しないidの更新は何も起こさないこと', () async {
      final before = await repository.fetchEvents();

      await repository.updateEvent(buildLifeEvent(id: 'not-exist'));

      expect(await repository.fetchEvents(), equals(before));
    });

    test('取得結果を直接変更できないこと', () async {
      final events = await repository.fetchEvents();

      expect(
        () => events.add(buildLifeEvent(id: 'x')),
        throwsUnsupportedError,
      );
    });
  });
}
