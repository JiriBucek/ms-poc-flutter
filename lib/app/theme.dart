import 'package:flutter/material.dart';

import '../features/testing/domain/enums.dart';
import 'theme/app_text.dart';
import 'theme/colors.dart';

export 'theme/app_text.dart';
export 'theme/colors.dart';

/// App-wide theme + result semantics, matching the iOS `Style.swift`.
///
/// Milk testing: *positive* = antibiotics detected (unsafe → red, [AppColors.positive]);
/// *negative* = clean/safe (green, [AppColors.negative]).
class AppTheme {
  AppTheme._();

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      primary: AppColors.primary,
      brightness: Brightness.light,
    );
    return ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      fontFamily: AppText.family,
      scaffoldBackgroundColor: AppColors.white,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.white,
        surfaceTintColor: Colors.transparent,
        foregroundColor: AppColors.dark,
        // Back/nav icons are blue (chPrimaryDark) as in iOS.
        iconTheme: IconThemeData(color: AppColors.primaryDark, size: 26),
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontFamily: AppText.family,
          fontWeight: FontWeight.w700,
          fontSize: 18,
          color: AppColors.dark,
        ),
      ),
    );
  }

  static Color resultColor(SampleResult r) => switch (r) {
        SampleResult.positive => AppColors.positive,
        SampleResult.weakPositive => AppColors.warning,
        SampleResult.negative => AppColors.negative,
        SampleResult.none => AppColors.darkGrey,
      };

  static Color resultBackground(SampleResult r) => switch (r) {
        SampleResult.positive => AppColors.backgroundPink,
        SampleResult.weakPositive => AppColors.backgroundPink,
        SampleResult.negative => AppColors.backgroundGreen,
        SampleResult.none => AppColors.msOffWhite,
      };

  static String resultLabel(SampleResult r) => switch (r) {
        SampleResult.positive => 'Positive',
        SampleResult.weakPositive => 'Weak positive',
        SampleResult.negative => 'Negative',
        SampleResult.none => 'Unknown',
      };

  static IconData resultIcon(SampleResult r) => switch (r) {
        SampleResult.positive => Icons.warning_amber_rounded,
        SampleResult.weakPositive => Icons.error_outline,
        SampleResult.negative => Icons.check_circle_outline,
        SampleResult.none => Icons.help_outline,
      };
}
