import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'auth_repository.dart';

/// iOS / Android 向けの [AuthRepository] 実装
///
/// `google_sign_in` パッケージを使用してネイティブの Google 認証フローを呼び出し、
/// 取得したトークンで Firebase Auth に認証情報を渡す。
///
/// google_sign_in 7 系では認証（identity）と認可（access token）が分離され、
/// [GoogleSignIn.instance] はメソッド呼び出し前に必ず [GoogleSignIn.initialize]
/// の完了を待つ必要がある。ID トークンのみで Firebase の Google 認証には十分。
class MobileAuthRepository implements AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  Future<void>? _initialization;

  Future<void> _ensureInitialized() {
    return _initialization ??= _googleSignIn.initialize();
  }

  @override
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  @override
  Future<UserCredential> signInWithGoogle() async {
    await _ensureInitialized();

    final GoogleSignInAccount googleUser;
    try {
      googleUser = await _googleSignIn.authenticate();
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        throw Exception('Googleサインインがキャンセルされました');
      }
      rethrow;
    }

    final OAuthCredential credential = GoogleAuthProvider.credential(
      idToken: googleUser.authentication.idToken,
    );

    return await _auth.signInWithCredential(credential);
  }

  @override
  Future<void> signOut() async {
    await Future.wait([
      _auth.signOut(),
      _googleSignIn.signOut(),
    ]);
  }

  @override
  User? get currentUser => _auth.currentUser;
}
