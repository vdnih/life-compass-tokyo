import 'package:firebase_auth/firebase_auth.dart';

/// 認証処理を抽象化するリポジトリインターフェース
///
/// Web と Mobile でサインイン方法が異なるため、プラットフォームごとに実装を分離する。
abstract class AuthRepository {
  /// 認証状態の変更を監視するストリーム
  Stream<User?> get authStateChanges;

  /// Google アカウントでサインインする
  Future<UserCredential> signInWithGoogle();

  /// サインアウトする
  Future<void> signOut();

  /// 現在のログインユーザー（未認証の場合は null）
  User? get currentUser;
}
