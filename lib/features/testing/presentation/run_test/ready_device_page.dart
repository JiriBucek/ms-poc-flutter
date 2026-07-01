import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/strings.dart';
import '../../../../app/theme.dart';
import '../../../../app/theme/app_images.dart';
import '../../../../app/widgets/ch_buttons.dart';
import '../../application/connection_controller.dart';
import '../../application/run_test_controller.dart';

/// Step 3 — the "ready to test / insert strip" confirmation. Matches the iOS
/// ReadyDevice screen: scanner hero, a summary of the selected test, and an
/// instruction, then the "Reader is ready" button.
class ReadyDevicePage extends ConsumerWidget {
  const ReadyDevicePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final testType = ref.watch(runTestControllerProvider).testType;
    final device = ref.watch(connectionControllerProvider).device;

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(),
      body: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Image.asset(AppImages.stripScanner,
                width: double.infinity, fit: BoxFit.fitWidth),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 8),
                    Text(S.readyToTest,
                        textAlign: TextAlign.center, style: AppText.title),
                    const SizedBox(height: 28),
                    _InfoRow(label: S.testLabel, value: testType?.name ?? '—'),
                    if (device != null)
                      _InfoRow(label: 'Reader:', value: device.name),
                    const SizedBox(height: 16),
                    const Divider(height: 1, color: Color(0xFFD8D8D8)),
                    const SizedBox(height: 16),
                    Text(
                      S.insertStripHelp,
                      textAlign: TextAlign.center,
                      style: AppText.regular(18, color: AppColors.subtitleGrey),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: CHFilledButton(
                title: S.readyBtn,
                onPressed: () => context.push('/run/perform'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppText.regular(18, color: AppColors.black)),
          Flexible(
            child: Text(value,
                textAlign: TextAlign.right,
                style: AppText.bold(20, color: AppColors.black)),
          ),
        ],
      ),
    );
  }
}
