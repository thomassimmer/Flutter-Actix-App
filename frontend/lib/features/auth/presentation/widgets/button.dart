import 'package:flutter/material.dart';

enum ButtonSize { small, medium, large }

class Button extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isPrimary;
  final ButtonSize size;

  const Button({
    required this.text,
    required this.onPressed,
    this.isPrimary = true,
    this.size = ButtonSize.medium,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    EdgeInsets padding;
    double fontSize;

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
        backgroundColor: isPrimary ? Colors.white : Colors.blue.shade700,
        foregroundColor: isPrimary ? Colors.blue.shade900 : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: fontSize),
      ),
    );
  }
}
