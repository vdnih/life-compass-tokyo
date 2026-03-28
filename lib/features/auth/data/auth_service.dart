import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Firebase Authentication の操作を抽象化するサービスインターフェース
abstract class AuthService {
  /// 認証状態の変化ストリーム
  Stream<User?> get authStateChanges;

  /// メールとパスワードでサインイン
  Future<void> signIn(String email, String password);

  /// メールとパスワードでサインアップ（新規アカウント作成）
  Future<void> signUp(String email, String password);

  /// サインアウト
  Future<void> signOut();
}

/// Firebase Authentication を使用した [AuthService] の実装
class FirebaseAuthService implements AuthService {
  final FirebaseAuth _auth;

  FirebaseAuthService({FirebaseAuth? auth}) : _auth = auth ?? FirebaseAuth.instance;

  @override
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  @override
  Future<void> signIn(String email, String password) async {
    await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  @override
  Future<void> signUp(String email, String password) async {
    await _auth.createUserWithEmailAndPassword(email: email, password: password);
  }

  @override
  Future<void> signOut() async {
    await _auth.signOut();
  }
}

/// [AuthService] を提供するProvider
final authServiceProvider = Provider<AuthService>((ref) {
  return FirebaseAuthService();
});
