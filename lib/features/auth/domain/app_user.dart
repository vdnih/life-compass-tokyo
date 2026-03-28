import 'package:flutter/foundation.dart';

/// 認証済みユーザーを表すエンティティ。
///
/// Firebase Authentication の [User] を受け取り、
/// アプリ内で扱うドメインモデルに変換したもの。
@immutable
class AppUser {
  /// Firebase が発行するユニーク ID。
  final String uid;

  /// Google アカウントの表示名（未設定の場合は null）。
  final String? displayName;

  /// Google アカウントのメールアドレス（未設定の場合は null）。
  final String? email;

  /// Google アカウントのプロフィール画像 URL（未設定の場合は null）。
  final String? photoUrl;

  const AppUser({
    required this.uid,
    this.displayName,
    this.email,
    this.photoUrl,
  });

  /// 指定フィールドだけを置き換えた新しいインスタンスを返す。
  AppUser copyWith({
    String? uid,
    String? displayName,
    String? email,
    String? photoUrl,
  }) {
    return AppUser(
      uid: uid ?? this.uid,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AppUser &&
        other.uid == uid &&
        other.displayName == displayName &&
        other.email == email &&
        other.photoUrl == photoUrl;
  }

  @override
  int get hashCode =>
      uid.hashCode ^
      displayName.hashCode ^
      email.hashCode ^
      photoUrl.hashCode;
}
