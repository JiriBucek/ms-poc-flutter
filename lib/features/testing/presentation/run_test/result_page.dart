import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/strings.dart';
import '../../../../app/theme.dart';
import '../../../../app/theme/app_images.dart';
import '../../../../app/widgets/ch_buttons.dart';
import '../../application/run_test_controller.dart';
import '../widgets/test_result_view.dart';

/// Step 5 — the saved result. Matches the iOS TestRecord screen. The record was
/// already persisted by the controller; here we present it and offer a new run.
class ResultPage extends ConsumerWidget {
  const ResultPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sample = ref.watch(runTestControllerProvider).result;

    if (sample == null) {
      // Guard: nothing to show (e.g. deep-linked). Send home.
      return Scaffold(
        backgroundColor: AppColors.white,
        body: Center(
          child: CHFilledButton(title: 'Home', onPressed: () => context.go('/')),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leadingWidth: 64,
        leading: IconButton(
          iconSize: 30,
          icon: Image.asset(AppImages.iconHome, height: 30, width: 30),
          onPressed: () => context.go('/'),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: TestResultView(sample: sample),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: CHFilledButton(
                title: S.runNewTest,
                onPressed: () {
                  ref.read(runTestControllerProvider.notifier).reset();
                  context.go('/run/test-type');
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
