import 'package:flutter_test/flutter_test.dart';
import 'package:my_career_app/features/auth/domain/app_user.dart';

void main() {
  const user = AppUser(
    uid: 'uid-1',
    displayName: 'Taro',
    email: 'taro@example.com',
    photoUrl: 'https://example.com/photo.jpg',
  );

  group('AppUser equality', () {
    test('同じフィールドを持つインスタンスは等しい', () {
      const same = AppUser(
        uid: 'uid-1',
        displayName: 'Taro',
        email: 'taro@example.com',
        photoUrl: 'https://example.com/photo.jpg',
      );
      expect(user, equals(same));
    });

    test('uid が異なるインスタンスは等しくない', () {
      const other = AppUser(uid: 'uid-2', displayName: 'Taro');
      expect(user, isNot(equals(other)));
    });

    test('displayName が異なるインスタンスは等しくない', () {
      const other = AppUser(uid: 'uid-1', displayName: 'Hanako');
      expect(user, isNot(equals(other)));
    });
  });

  group('AppUser hashCode', () {
    test('等しいインスタンスは同じ hashCode を持つ', () {
      const same = AppUser(
        uid: 'uid-1',
        displayName: 'Taro',
        email: 'taro@example.com',
        photoUrl: 'https://example.com/photo.jpg',
      );
      expect(user.hashCode, equals(same.hashCode));
    });
  });

  group('AppUser.copyWith', () {
    test('displayName を更新した新しいインスタンスを返す', () {
      final updated = user.copyWith(displayName: 'Hanako');
      expect(updated.displayName, equals('Hanako'));
      expect(updated.uid, equals('uid-1'));
      expect(updated.email, equals('taro@example.com'));
    });

    test('引数なしの場合は同じ値を持つ新しいインスタンスを返す', () {
      final copy = user.copyWith();
      expect(copy, equals(user));
      expect(identical(copy, user), isFalse);
    });

    test('元のインスタンスは変更されない', () {
      user.copyWith(displayName: 'Changed');
      expect(user.displayName, equals('Taro'));
    });
  });

  group('AppUser null フィールド', () {
    test('省略可能フィールドが null のインスタンスを生成できる', () {
      const minimal = AppUser(uid: 'uid-min');
      expect(minimal.displayName, isNull);
      expect(minimal.email, isNull);
      expect(minimal.photoUrl, isNull);
    });
  });
}
