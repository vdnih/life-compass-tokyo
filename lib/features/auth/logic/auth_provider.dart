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

/// 認証状態がまだ解決していない間 true を返すProvider
///
/// [authStateProvider] は `AsyncLoading` から始まり、`.value == null` だけでは
/// 「未認証」と「まだ解決していない」を区別できない（ADR-020, #39）。この窓で
/// ゲストとして書き込むと、解決後に Firestore 実装へ切り替わった時点でその内容が
/// 失われる。根治（[TimelineEventsNotifier.build] 等で解決を待つ）は #39 に譲り、
/// ここでは書き込み導線を一時的に閉じることで実害だけを防ぐ。
final authPendingProvider = Provider<bool>(
  (ref) => ref.watch(authStateProvider).isLoading,
);
