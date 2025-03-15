import 'package:flutter/material.dart';
import 'package:flutteractixapp/core/messages/message.dart';
import 'package:flutteractixapp/core/messages/message_mapper.dart';
import 'package:flutteractixapp/core/ui/extensions.dart';

class GlobalSnackBar {
  static Color _getBackgroundColor(BuildContext context, Message message) {
    if (message is SuccessMessage) {
      return context.colors.accent;
    } else if (message is InfoMessage) {
      return context.colors.information;
    } else {
      return context.colors.error;
    }
  }

  static show(
    BuildContext context,
    Message? message,
  ) {
    if (message == null) {
      return null;
    }

    final messageTranslated = getTranslatedMessage(context, message);
    final backgroundColor = _getBackgroundColor(context, message);

    return (ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(messageTranslated),
        backgroundColor: backgroundColor,
        duration: Duration(seconds: 3),
        showCloseIcon: true,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(5.0),
        ),
        closeIconColor: context.colors.text,
      ),
    ));
  }
}
