import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// ローカル Firebase エミュレータへ接続する。
///
/// `main()` から [kDebugMode] のときだけ呼ばれる想定（エスケープハッチは
/// 設けない。ローカルで本番データが必要な場合は `flutter run --release` を使う）。
/// `firebase emulators:start` の起動が前提（ADR-024）。
///
/// ポート番号は Firebase の標準デフォルト（auth: 9099, firestore: 8080,
/// storage: 9199, ui: 4000 ...）全体に一律 +10000 したもの。プロダクト単位で
/// この帯を割り当てる規約（`_hub/CLAUDE.md`）に従う。他プロダクト
/// （sakeflow は標準デフォルトをそのまま使用）と同一マシンでエミュレータを
/// 同時に起動しっぱなしにできる。
Future<void> connectToEmulators() async {
  const host = 'localhost';
  await FirebaseAuth.instance.useAuthEmulator(host, 19099);
  FirebaseFirestore.instance.useFirestoreEmulator(host, 18080);
  debugPrint('🧪 Firebase エミュレータに接続しました（実データには一切触れません）');
}
