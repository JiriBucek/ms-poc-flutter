import 'package:flutter/material.dart';

import 'colors.dart';

/// Typography helpers mirroring the iOS `UIFont.chXxx` family + the
/// `UILabel` style extensions. All text uses the NeuzeitGro family.
class AppText {
  AppText._();

  static const String family = 'NeuzeitGro';

  static TextStyle light(double size, {Color color = AppColors.dark}) =>
      TextStyle(fontFamily: family, fontWeight: FontWeight.w300, fontSize: size, color: color);

  static TextStyle regular(double size, {Color color = AppColors.dark}) =>
      TextStyle(fontFamily: family, fontWeight: FontWeight.w400, fontSize: size, color: color);

  static TextStyle bold(double size, {Color color = AppColors.dark}) =>
      TextStyle(fontFamily: family, fontWeight: FontWeight.w700, fontSize: size, color: color);

  static TextStyle black(double size, {Color color = AppColors.dark}) =>
      TextStyle(fontFamily: family, fontWeight: FontWeight.w900, fontSize: size, color: color);

  // Named styles from UILabel+Style.swift ----------------------------------

  /// `makeTitleLabel`: Black 32, line-height 34, colour chDark.
  static TextStyle get title =>
      black(32, color: AppColors.dark).copyWith(height: 34 / 32);

  /// `makeSubTitleLabel`: Bold 20, colour chBlack.
  static TextStyle get subtitle => bold(20, color: AppColors.black);

  /// Filled/outlined button label: Bold 22.
  static TextStyle get button => bold(22, color: AppColors.white);
}
