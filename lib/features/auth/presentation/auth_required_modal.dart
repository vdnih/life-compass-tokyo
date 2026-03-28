import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';

/// 未認証ユーザーが書き込み操作を試みた際に表示する認証要求モーダルを表示する
void showAuthRequiredModal(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) => const _AuthRequiredContent(),
  );
}

class _AuthRequiredContent extends StatelessWidget {
  const _AuthRequiredContent();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ドラッグハンドル
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          const Icon(Icons.lock_outline, size: 48, color: AppTheme.primary),
          const SizedBox(height: 16),
          Text(
            'アカウントが必要です',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'イベントの追加・編集には\nアカウントへのログインが必要です。',
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {
                Navigator.of(context).pop();
                context.go('/signup');
              },
              child: const Text('サインアップ（無料）'),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                Navigator.of(context).pop();
                context.go('/login');
              },
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppTheme.primary),
                foregroundColor: AppTheme.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('ログイン'),
            ),
          ),
          const SizedBox(height: 4),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              '閲覧のみ続ける',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
          SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
        ],
      ),
    ),
    );
  }
}
