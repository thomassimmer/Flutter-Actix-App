import 'package:flutter/material.dart';

class CustomTextButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isEnabled;
  final TextStyle? textStyle;
  final WidgetStateProperty<EdgeInsetsGeometry>? padding;

  const CustomTextButton({
    Key? key,
    required this.text,
    required this.onPressed,
    this.isEnabled = true,
    this.textStyle,
    this.padding,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: isEnabled ? onPressed : null,
      style: ButtonStyle(
        padding: padding ?? Theme.of(context).textButtonTheme.style?.padding,
        backgroundColor: WidgetStateProperty.all<Color>(isEnabled
            ? Theme.of(context).colorScheme.surface
            : Theme.of(context).colorScheme.surface),
        foregroundColor: WidgetStateProperty.resolveWith(
          (Set<WidgetState> states) {
            if (states.contains(WidgetState.hovered)) {
              return isEnabled
                  ? Theme.of(context).colorScheme.onSurface.withOpacity(0.10)
                  : Theme.of(context).colorScheme.onSurface.withOpacity(0.10);
            }
            return isEnabled
                ? Theme.of(context).colorScheme.surface
                : Theme.of(context).colorScheme.surface;
          },
        ),
      ),
      child: Text(
        text,
        style: textStyle ??
            Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: isEnabled
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.surface.withOpacity(0.38),
                ),
      ),
    );
  }
}
