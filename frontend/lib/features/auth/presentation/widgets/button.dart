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
    // Determine the current brightness (theme) of the app
    final Brightness brightness = Theme.of(context).brightness;
    final bool isDarkMode = brightness == Brightness.dark;

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

    // Define colors based on whether the button is primary and the current theme
    final Color backgroundColor = isPrimary
        ? (isDarkMode ? Colors.blueGrey.shade700 : Colors.white)
        : (isDarkMode ? Colors.blue.shade300 : Colors.blue.shade700);

    final Color foregroundColor = isPrimary
        ? (isDarkMode ? Colors.white : Colors.blue.shade900)
        : (isDarkMode ? Colors.blueGrey.shade900 : Colors.white);

    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        padding: padding,
        backgroundColor: backgroundColor,
        foregroundColor: foregroundColor,
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
