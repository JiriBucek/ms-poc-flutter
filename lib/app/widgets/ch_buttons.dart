import 'package:flutter/material.dart';

import '../theme/app_text.dart';
import '../theme/colors.dart';

/// Filled primary button — iOS `CHFillWithIconButton.makeFilled`.
/// chPrimary fill, white Bold-22 title, chLightGrey when disabled.
class CHFilledButton extends StatelessWidget {
  const CHFilledButton({
    super.key,
    required this.title,
    required this.onPressed,
    this.icon,
    this.fillColor = AppColors.primary,
    this.titleColor = AppColors.white,
    this.height = 64,
  });

  final String title;
  final VoidCallback? onPressed;
  final Widget? icon;
  final Color fillColor;
  final Color titleColor;
  final double height;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return SizedBox(
      height: height,
      width: double.infinity,
      child: Material(
        color: enabled ? fillColor : AppColors.lightGrey,
        child: InkWell(
          onTap: onPressed,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[icon!, const SizedBox(width: 10)],
              Flexible(
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  style: AppText.button.copyWith(
                    color: enabled ? titleColor : titleColor.withValues(alpha: 0.5),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Outlined button — iOS `makeOutlined`. 1px chDark border, chDark Bold-22 title.
class CHOutlinedButton extends StatelessWidget {
  const CHOutlinedButton({
    super.key,
    required this.title,
    required this.onPressed,
    this.color = AppColors.dark,
    this.height = 60,
  });

  final String title;
  final VoidCallback? onPressed;
  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: color),
          shape: const RoundedRectangleBorder(),
          foregroundColor: color,
        ),
        child: Text(title, style: AppText.bold(22, color: color)),
      ),
    );
  }
}

/// Plain text button — iOS `makePlainButton`. chPrimary Bold-22 title.
class CHPlainButton extends StatelessWidget {
  const CHPlainButton({
    super.key,
    required this.title,
    required this.onPressed,
    this.color = AppColors.primary,
  });

  final String title;
  final VoidCallback? onPressed;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      child: Text(title, style: AppText.bold(22, color: color)),
    );
  }
}
