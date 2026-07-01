import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/strings.dart';
import '../../../../app/theme.dart';
import '../../../../app/widgets/ch_buttons.dart';
import '../../application/run_test_controller.dart';
import '../../domain/enums.dart';
import '../../domain/test_type.dart';

/// Step 1 — choose the test type. Matches the iOS TestTypeSelection screen:
/// bordered cards with brand + test name (+ a "Quant" badge), then "Next".
class TestTypePage extends ConsumerWidget {
  const TestTypePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final typesAsync = ref.watch(testTypesProvider);
    final selected = ref.watch(runTestControllerProvider).testType;

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(),
      body: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(S.chooseTestTitle, style: AppText.title),
              const SizedBox(height: 20),
              Expanded(
                child: typesAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('Failed to load: $e')),
                  data: (types) => ListView.separated(
                    itemCount: types.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, i) {
                      final t = types[i];
                      return _TestTypeCard(
                        type: t,
                        selected: selected?.id == t.id,
                        onTap: () => ref
                            .read(runTestControllerProvider.notifier)
                            .selectTestType(t),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 12),
              CHFilledButton(
                title: S.next,
                onPressed:
                    selected == null ? null : () => context.push('/run/device'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TestTypeCard extends StatelessWidget {
  const _TestTypeCard({
    required this.type,
    required this.selected,
    required this.onTap,
  });

  final TestType type;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isQuant = type.measurementMethod == MeasurementMethod.quantitative;
    final fg = selected ? AppColors.primary : AppColors.black;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 138,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? AppColors.primaryDark : AppColors.black,
            width: 1,
          ),
        ),
        child: Stack(
          children: [
            // Centred brand + test name.
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('MilkSafe™',
                      textAlign: TextAlign.center,
                      style: AppText.bold(22, color: fg)),
                  const SizedBox(height: 2),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      type.name.replaceFirst('MilkSafe™ ', ''),
                      textAlign: TextAlign.center,
                      style: AppText.bold(48, color: fg),
                    ),
                  ),
                ],
              ),
            ),
            // "Quant" pill, top-right.
            if (isQuant)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.msOffWhite,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Text(S.quant,
                      style:
                          AppText.regular(14, color: AppColors.subtitleGrey)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
