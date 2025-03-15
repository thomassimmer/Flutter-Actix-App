import 'package:flutter/material.dart';
import 'package:flutteractixapp/core/constants/app_colors.dart';

enum ButtonSize { small, medium, large }

class Button extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isPrimary;
  final ButtonSize size;
  final TextStyle? textStyle;

  const Button({
    required this.text,
    required this.onPressed,
    this.isPrimary = true,
    this.size = ButtonSize.medium,
    this.textStyle,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    EdgeInsets padding;
    double fontSize;

    // Determine the padding and font size based on button size
    switch (size) {
      case ButtonSize.small:
        padding = EdgeInsets.symmetric(horizontal: 24, vertical: 8);
        fontSize = 14;
      case ButtonSize.medium:
        padding = EdgeInsets.symmetric(horizontal: 40, vertical: 16);
        fontSize = 18;
      case ButtonSize.large:
        padding = EdgeInsets.symmetric(horizontal: 56, vertical: 20);
        fontSize = 22;
    }

    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
          padding: padding,
          backgroundColor: isPrimary
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.primaryContainer),
      child: Text(
        text,
        style: textStyle ??
            Theme.of(context)
                .textTheme
                .labelSmall
                ?.copyWith(fontSize: fontSize, color: AppColors.onPrimary),
      ),
    );
  }
}
