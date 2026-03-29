import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../user_profile.dart';

/// ユーザープロフィールの永続化を担うリポジトリインターフェース
abstract class UserRepository {
  /// 指定ユーザーのプロフィールを取得する。存在しない場合は null を返す。
  Future<UserProfile?> fetchProfile(String userId);

  /// ユーザープロフィールを保存する（新規作成・上書きどちらも対応）
  Future<void> saveProfile(String userId, UserProfile profile);

  /// 指定ユーザーのプロフィールが Firestore に存在するか確認する
  Future<bool> profileExists(String userId);
}

/// Firestore を使用した [UserRepository] 実装
class FirestoreUserRepository implements UserRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> _userDoc(String userId) =>
      _db.collection('users').doc(userId);

  @override
  Future<UserProfile?> fetchProfile(String userId) async {
    final doc = await _userDoc(userId).get();
    if (!doc.exists) return null;

    final data = doc.data()!;
    final birthDateStr = data['birthDate'] as String?;

    return UserProfile(
      name: (data['name'] as String?) ?? '',
      birthDate: birthDateStr != null ? DateTime.parse(birthDateStr) : null,
    );
  }

  @override
  Future<void> saveProfile(String userId, UserProfile profile) async {
    await _userDoc(userId).set(
      {
        'name': profile.name,
        'birthDate': profile.birthDate != null
            ? '${profile.birthDate!.year.toString().padLeft(4, '0')}'
                '-${profile.birthDate!.month.toString().padLeft(2, '0')}'
                '-${profile.birthDate!.day.toString().padLeft(2, '0')}'
            : null,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  @override
  Future<bool> profileExists(String userId) async {
    final doc = await _userDoc(userId).get();
    return doc.exists;
  }
}

/// [UserRepository] を提供するProvider
final userRepositoryProvider = Provider<UserRepository>((ref) {
  return FirestoreUserRepository();
});
