import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/strings.dart';
import '../../../../app/theme.dart';
import '../../../../app/widgets/ch_buttons.dart';
import '../../application/run_test_controller.dart';

/// Step 4 — runs the test on the connected reader. Matches the iOS PerformTest
/// screen: a centred spinner with "Test is running. Please wait" and the test
/// name. Advances to the result screen on success.
class PerformTestPage extends ConsumerStatefulWidget {
  const PerformTestPage({super.key});

  @override
  ConsumerState<PerformTestPage> createState() => _PerformTestPageState();
}

class _PerformTestPageState extends ConsumerState<PerformTestPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(runTestControllerProvider.notifier).run();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Navigate to the result screen once the run succeeds.
    ref.listen(runTestControllerProvider, (prev, next) {
      if (next.phase == RunPhase.success && mounted) {
        context.pushReplacement('/run/result');
      }
    });

    final state = ref.watch(runTestControllerProvider);
    final testName = state.testType?.name ?? '';

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: switch (state.phase) {
            RunPhase.failure => _FailureView(
                message: state.errorMessage ?? 'Something went wrong',
                onRetry: () =>
                    ref.read(runTestControllerProvider.notifier).run(),
                onCancel: () => context.go('/'),
              ),
            _ => _RunningView(testName: testName),
          },
        ),
      ),
    );
  }
}

class _RunningView extends StatelessWidget {
  const _RunningView({required this.testName});
  final String testName;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(color: AppColors.primaryDark),
          const SizedBox(height: 20),
          Text(S.testIsRunning, style: AppText.subtitle),
          const SizedBox(height: 6),
          Text(testName,
              textAlign: TextAlign.center,
              style: AppText.black(32, color: AppColors.dark)),
        ],
      ),
    );
  }
}

class _FailureView extends StatelessWidget {
  const _FailureView({
    required this.message,
    required this.onRetry,
    required this.onCancel,
  });
  final String message;
  final VoidCallback onRetry;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Spacer(),
        const Icon(Icons.error_outline, size: 48, color: AppColors.warning),
        const SizedBox(height: 16),
        Text(message,
            textAlign: TextAlign.center,
            style: AppText.regular(18, color: AppColors.black)),
        const Spacer(),
        CHFilledButton(title: 'Retry', onPressed: onRetry),
        const SizedBox(height: 12),
        CHOutlinedButton(title: 'Cancel test', onPressed: onCancel),
      ],
    );
  }
}
