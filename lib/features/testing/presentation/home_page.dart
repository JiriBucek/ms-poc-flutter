import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/strings.dart';
import '../../../app/theme.dart';
import '../../../app/theme/app_images.dart';
import '../../../app/widgets/ch_buttons.dart';

/// Landing screen — mirrors the iOS Home: MilkSafe + Chr. Hansen logos centred,
/// with "Test records" (outlined) and "Start test" (filled) at the bottom.
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Top bar: Settings (right).
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 16, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => _comingSoon(context, S.settings),
                    child: Text(S.settings,
                        style: AppText.bold(22, color: AppColors.primary)),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(AppImages.logoMilksafe, height: 34),
                    const SizedBox(height: 36),
                    Image.asset(AppImages.logoCh, height: 40),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  CHOutlinedButton(
                    title: S.testRecords,
                    onPressed: () => context.push('/history'),
                  ),
                  const SizedBox(height: 24),
                  CHFilledButton(
                    title: S.startTest,
                    onPressed: () => context.push('/run/test-type'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _comingSoon(BuildContext context, String what) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$what — coming soon')),
    );
  }
}
