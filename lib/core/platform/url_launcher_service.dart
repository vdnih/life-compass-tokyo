import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart' as launcher;

/// 外部URLをブラウザで開く抽象（ADR-026）。
///
/// テストで実際にブラウザを起動しないよう、ウィジェット側は必ずこの抽象
/// 経由で呼び出す。ウィジェットテストは [urlLauncherProvider] をフェイクで
/// override し、実際に開かれたかではなく「呼ばれたか」（配線）だけを見る。
abstract class UrlLauncher {
  Future<void> open(String url);
}

class DefaultUrlLauncher implements UrlLauncher {
  const DefaultUrlLauncher();

  @override
  Future<void> open(String url) async {
    final uri = Uri.parse(url);
    await launcher.launchUrl(uri, webOnlyWindowName: '_blank');
  }
}

final urlLauncherProvider = Provider<UrlLauncher>(
  (ref) => const DefaultUrlLauncher(),
);
