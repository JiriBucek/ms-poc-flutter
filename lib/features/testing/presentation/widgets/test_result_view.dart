import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../app/strings.dart';
import '../../../../app/theme.dart';
import '../../../../app/theme/app_images.dart';
import '../../domain/enums.dart';
import '../../domain/test_sample.dart';

/// The test-result presentation, matching the iOS TestRecord screen: large
/// result icon, headline, a coloured result banner, metadata rows, and the
/// per-substance breakdown. Shared by the run-flow result page and history
/// detail.
class TestResultView extends StatelessWidget {
  const TestResultView({super.key, required this.sample});

  final TestSample sample;

  @override
  Widget build(BuildContext context) {
    final result = sample.result;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        Center(child: _resultImage(result)),
        const SizedBox(height: 28),
        Text(_headline(result),
            textAlign: TextAlign.center,
            style: AppText.black(32, color: AppColors.black)),
        const SizedBox(height: 8),
        Text(sample.testType.name,
            textAlign: TextAlign.center,
            style: AppText.regular(20, color: AppColors.black)),
        const SizedBox(height: 28),

        // Metadata
        _MetaRow(
          icon: AppImages.iconTime,
          label: S.dateTimeLabel,
          value: DateFormat('d MMM yyyy, HH:mm').format(sample.testDate),
        ),
        if ((sample.readerSerialNumber ?? '').isNotEmpty)
          _MetaRow(
            icon: AppImages.iconUser,
            label: S.readerLabel,
            value: sample.readerSerialNumber!,
          ),
        _MetaRow(
          icon: AppImages.iconNotSynced,
          label: S.uploadStatusLabel,
          value: S.notSynced,
        ),
        if ((sample.batchNumber ?? '').isNotEmpty)
          _MetaRow(
            icon: AppImages.iconBatch,
            label: S.batchNumberLabel,
            value: sample.batchNumber!,
          ),

        const SizedBox(height: 16),
        const Divider(height: 1, color: Color(0xFFD8D8D8)),
        const SizedBox(height: 16),

        // Substances
        ...sample.substances.map((item) => _SubstanceRow(item: item)),
      ],
    );
  }

  Widget _resultImage(SampleResult r) {
    final asset = switch (r) {
      SampleResult.negative => AppImages.negativeLarge,
      SampleResult.positive => AppImages.positiveLarge,
      SampleResult.weakPositive => AppImages.positiveLarge,
      SampleResult.none => AppImages.warningBlue,
    };
    return Image.asset(asset, height: 64, width: 64);
  }

  String _headline(SampleResult r) => switch (r) {
        SampleResult.positive => S.testIsPositive,
        SampleResult.weakPositive => S.testIsWeakPositive,
        SampleResult.negative => S.testIsNegative,
        SampleResult.none => AppTheme.resultLabel(r),
      };
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.icon, required this.label, required this.value});
  final String icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        children: [
          Image.asset(icon, height: 16, width: 16),
          const SizedBox(width: 10),
          Text(label, style: AppText.regular(18, color: AppColors.black)),
          const Spacer(),
          Flexible(
            child: Text(value,
                textAlign: TextAlign.right,
                style: AppText.bold(18, color: AppColors.black)),
          ),
        ],
      ),
    );
  }
}

/// One substance line, matching iOS `SampleItemStackView`:
/// `Name:  value   ResultText  [icon]` — black text on white, with only the
/// red-cross / green-check icon carrying colour. Column widths 40/20/30/10.
class _SubstanceRow extends StatelessWidget {
  const _SubstanceRow({required this.item});
  final SampleResultItem item;

  @override
  Widget build(BuildContext context) {
    final isNegative = item.result == SampleResult.negative;
    final icon = isNegative ? AppImages.greenCheckmark : AppImages.closeRed;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(
            flex: 40,
            child: Text('${item.substance.name}:',
                style: AppText.regular(18, color: AppColors.black)),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 20,
            child: Text(item.level,
                style: AppText.regular(18, color: AppColors.black)),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 30,
            child: Text(AppTheme.resultLabel(item.result),
                style: AppText.bold(18, color: AppColors.black)),
          ),
          SizedBox(
            width: 24,
            child: Image.asset(icon, height: 20, width: 20),
          ),
        ],
      ),
    );
  }
}
