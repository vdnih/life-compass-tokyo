import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../auth/logic/auth_provider.dart';
import 'data/user_repository.dart';

/// ユーザープロフィールを表すデータクラス
class UserProfile {
  final String name;
  final DateTime? birthDate;

  UserProfile({required this.name, this.birthDate});

  /// 現在日時での年齢
  int? get age => calculateAgeAt(DateTime.now());

  /// 指定日時での年齢を計算する
  int? calculateAgeAt(DateTime date) {
    if (birthDate == null) return null;
    int age = date.year - birthDate!.year;
    if (date.month < birthDate!.month ||
        (date.month == birthDate!.month && date.day < birthDate!.day)) {
      age--;
    }
    return age;
  }

  UserProfile copyWith({String? name, DateTime? birthDate}) {
    return UserProfile(
      name: name ?? this.name,
      birthDate: birthDate ?? this.birthDate,
    );
  }
}

/// ユーザープロフィールの状態を管理する Notifier
///
/// 認証状態を監視し、ログイン時は Firestore からプロフィールをロードする。
/// 未認証の場合は null を返す（ゲストモード）。
class UserProfileNotifier extends AsyncNotifier<UserProfile?> {
  @override
  Future<UserProfile?> build() async {
    final user = await ref.watch(authStateProvider.future);
    if (user == null) return null;

    final repo = ref.read(userRepositoryProvider);
    return repo.fetchProfile(user.uid);
  }

  /// 既存ユーザーのプロフィールを更新し Firestore に保存する
  Future<void> updateProfile({String? name, DateTime? birthDate}) async {
    final user = ref.read(authStateProvider).value;
    if (user == null) return;

    final current = state.value;
    final updated = UserProfile(
      name: name ?? current?.name ?? '',
      birthDate: birthDate ?? current?.birthDate,
    );

    state = AsyncData(updated);

    final repo = ref.read(userRepositoryProvider);
    await repo.saveProfile(user.uid, updated);
  }

  /// 新規ユーザーのプロフィールを初期設定して Firestore に保存する
  Future<void> setupNewUserProfile({
    required String name,
    DateTime? birthDate,
  }) async {
    final user = ref.read(authStateProvider).value;
    if (user == null) return;

    final profile = UserProfile(name: name, birthDate: birthDate);
    final repo = ref.read(userRepositoryProvider);
    await repo.saveProfile(user.uid, profile);
    state = AsyncData(profile);
  }
}

/// ユーザープロフィールの状態を提供するProvider
final userProfileNotifierProvider =
    AsyncNotifierProvider.autoDispose<UserProfileNotifier, UserProfile?>(
  UserProfileNotifier.new,
);
