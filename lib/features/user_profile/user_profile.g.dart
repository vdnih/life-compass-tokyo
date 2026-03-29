// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_profile.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$userProfileNotifierHash() =>
    r'46f383c2877bf4f592dec83028466fa270303a6e';

/// ユーザープロフィールの状態を管理する Notifier
///
/// 認証状態を監視し、ログイン時は Firestore からプロフィールをロードする。
/// 未認証の場合は null を返す（ゲストモード）。
///
/// Copied from [UserProfileNotifier].
@ProviderFor(UserProfileNotifier)
final userProfileNotifierProvider =
    AutoDisposeAsyncNotifierProvider<
      UserProfileNotifier,
      UserProfile?
    >.internal(
      UserProfileNotifier.new,
      name: r'userProfileNotifierProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$userProfileNotifierHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$UserProfileNotifier = AutoDisposeAsyncNotifier<UserProfile?>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
