import 'package:flutter/material.dart';
import 'package:flutteractixapp/core/ui/extensions.dart';

class IconWithWarning extends StatelessWidget {
  final IconData iconData;
  final bool shouldBeWarning;

  const IconWithWarning({
    Key? key,
    required this.iconData,
    required this.shouldBeWarning,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(iconData),
        if (shouldBeWarning)
          Positioned(
            right: -6.0,
            top: -6.0,
            child: Container(
              width: 16.0,
              height: 16.0,
              decoration: BoxDecoration(
                color: context.colors.error,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '!',
                  style: TextStyle(
                    color: context.colors.textOnPrimary,
                    fontSize: 12.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
