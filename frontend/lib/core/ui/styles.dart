import 'package:flutter/material.dart';

class AppThemeStyles {
  final List<BoxShadow> cardShadow;

  final ButtonStyle buttonSmall;
  final ButtonStyle buttonMedium;
  final ButtonStyle buttonLarge;
  final ButtonStyle buttonText;

  const AppThemeStyles({
    this.cardShadow = const [
      BoxShadow(
        color: Color(0x1F000000),
        offset: Offset(0, 8),
        blurRadius: 23,
      ),
    ],
    this.buttonSmall = const ButtonStyle(
      minimumSize: WidgetStatePropertyAll(Size.zero),
      padding: WidgetStatePropertyAll(
          EdgeInsets.symmetric(vertical: 10, horizontal: 12)),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(15))),
      ),
      textStyle: WidgetStatePropertyAll(
        TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    ),
    this.buttonMedium = const ButtonStyle(
      minimumSize: WidgetStatePropertyAll(Size.zero),
      padding: WidgetStatePropertyAll(
          EdgeInsets.symmetric(vertical: 8, horizontal: 24)),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(30))),
      ),
      textStyle: WidgetStatePropertyAll(
        TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
    ),
    this.buttonLarge = const ButtonStyle(
      minimumSize: WidgetStatePropertyAll(Size.zero),
      padding: WidgetStatePropertyAll(
          EdgeInsets.symmetric(vertical: 12, horizontal: 24)),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(30))),
      ),
      textStyle: WidgetStatePropertyAll(
        TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
    ),
    this.buttonText = const ButtonStyle(
      minimumSize: WidgetStatePropertyAll(Size.zero),
      backgroundColor: WidgetStatePropertyAll(Colors.transparent),
      padding: WidgetStatePropertyAll(EdgeInsets.zero),
      splashFactory: NoSplash.splashFactory,
      textStyle: WidgetStatePropertyAll(
        TextStyle(fontSize: 16, fontWeight: FontWeight.w500, height: 1),
      ),
    ),
  });
}
