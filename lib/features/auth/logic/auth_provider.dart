import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/auth_repository.dart';
import '../data/web_auth_repository.dart';
import '../data/mobile_auth_repository.dart';

/// プラットフォームに応じた [AuthRepository] を提供するProvider
///
/// Web では [WebAuthRepository]、iOS/Android では [MobileAuthRepository] を返す。
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  if (kIsWeb) {
    return WebAuthRepository();
  }
  return MobileAuthRepository();
});

/// Firebase Auth の認証状態変更ストリームを提供するProvider
///
/// ログイン中は [User]、未認証は null を流す。
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});
