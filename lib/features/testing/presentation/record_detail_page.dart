import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../domain/test_sample.dart';
import 'widgets/test_result_view.dart';

class RecordDetailPage extends StatelessWidget {
  const RecordDetailPage({super.key, required this.sample});

  final TestSample sample;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: TestResultView(sample: sample),
        ),
      ),
    );
  }
}
