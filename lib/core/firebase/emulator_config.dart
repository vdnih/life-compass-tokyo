import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// ローカル Firebase エミュレータへ接続する。
///
/// `main()` から [kDebugMode] のときだけ呼ばれる想定（エスケープハッチは
/// 設けない。ローカルで本番データが必要な場合は `flutter run --release` を使う）。
/// `firebase emulators:start` の起動が前提（ADR-024）。
///
/// ポート番号は sakeflow 等の他プロダクトと衝突しない値にずらしてある
/// （Firebase Emulator Suite の事実上のデフォルト 9099/8080/4000 は使わない）。
/// 同一マシンで複数プロダクトのエミュレータを同時に起動しっぱなしにできる。
Future<void> connectToEmulators() async {
  const host = 'localhost';
  await FirebaseAuth.instance.useAuthEmulator(host, 9199);
  FirebaseFirestore.instance.useFirestoreEmulator(host, 8180);
  debugPrint('🧪 Firebase エミュレータに接続しました（実データには一切触れません）');
}
