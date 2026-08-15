import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// ローカル Firebase エミュレータへ接続する。
///
/// `main()` から [kDebugMode] のときだけ呼ばれる想定（エスケープハッチは
/// 設けない。ローカルで本番データが必要な場合は `flutter run --release` を使う）。
/// `firebase emulators:start` の起動が前提（ADR-024）。
Future<void> connectToEmulators() async {
  const host = 'localhost';
  await FirebaseAuth.instance.useAuthEmulator(host, 9099);
  FirebaseFirestore.instance.useFirestoreEmulator(host, 8080);
  debugPrint('🧪 Firebase エミュレータに接続しました（実データには一切触れません）');
}
