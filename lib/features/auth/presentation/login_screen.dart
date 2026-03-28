import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../logic/auth_state_provider.dart';

/// Google Sign-In ログイン画面。
class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authAsync = ref.watch(authNotifierProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.timeline_rounded,
                  size: 72,
                  color: AppTheme.primary,
                ),
                const SizedBox(height: 24),
                Text(
                  'わたしのライフプラン',
                  style: Theme.of(context).textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  '人生の計画を、あなたらしく。',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 64),
                if (authAsync.isLoading)
                  const CircularProgressIndicator(
                    color: AppTheme.primary,
                  )
                else
                  _GoogleSignInButton(
                    onPressed: () => ref
                        .read(authNotifierProvider.notifier)
                        .signInWithGoogle(),
                  ),
                if (authAsync.hasError) ...[
                  const SizedBox(height: 16),
                  Text(
                    'サインインに失敗しました。\nもう一度お試しください。',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.error,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GoogleSignInButton extends StatelessWidget {
  const _GoogleSignInButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        side: BorderSide(color: Colors.grey.shade300),
        foregroundColor: Colors.black87,
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _GoogleLogo(),
          SizedBox(width: 12),
          Text(
            'Googleでサインイン',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// Google の "G" ロゴを描画する Widget。
///
/// ネットワーク不要で使えるようにカスタムペインタで描画する。
class _GoogleLogo extends StatelessWidget {
  const _GoogleLogo();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 24,
      height: 24,
      child: CustomPaint(painter: _GoogleLogoPainter()),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // 背景円
    canvas.drawCircle(center, radius, Paint()..color = Colors.white);

    // G の文字を簡略化した円弧と塗りで描画
    const colors = [
      Color(0xFF4285F4), // 青
      Color(0xFF34A853), // 緑
      Color(0xFFFBBC05), // 黄
      Color(0xFFEA4335), // 赤
    ];

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.18
      ..strokeCap = StrokeCap.butt;

    const sweepAngles = [
      [0.0, 1.6],
      [1.6, 1.6],
      [3.2, 1.0],
      [4.2, 2.1],
    ];

    for (var i = 0; i < colors.length; i++) {
      paint.color = colors[i];
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius * 0.7),
        sweepAngles[i][0],
        sweepAngles[i][1],
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
