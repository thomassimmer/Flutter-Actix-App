import 'package:flutter/material.dart';

class AppLogo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Image.asset(
          'assets/images/flutter-logo.png',
          width: 80,
          height: 80,
        ),
        Image.asset(
          'assets/images/actix-logo.png',
          width: 80,
          height: 80,
        ),
      ],
    );
  }
}
