import 'package:firebase_auth/firebase_auth.dart';
import 'auth_repository.dart';

/// Web 向けの [AuthRepository] 実装
///
/// Firebase Auth の `signInWithPopup` を使用してポップアップウィンドウで Google 認証を行う。
/// google_sign_in パッケージは不要。
class WebAuthRepository implements AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  @override
  Future<UserCredential> signInWithGoogle() async {
    final GoogleAuthProvider googleProvider = GoogleAuthProvider();
    googleProvider.addScope('email');
    googleProvider.addScope('profile');
    // ブラウザに Google セッションが残っていても毎回アカウント選択を挟む。
    // 無指定だとそのセッションでサイレンスサインインし、意図しないアカウントに
    // 入ってしまう（実際に自動操作テスト中に発生した事故）。
    googleProvider.setCustomParameters({'prompt': 'select_account'});
    return await _auth.signInWithPopup(googleProvider);
  }

  @override
  Future<void> signOut() => _auth.signOut();

  @override
  User? get currentUser => _auth.currentUser;
}
