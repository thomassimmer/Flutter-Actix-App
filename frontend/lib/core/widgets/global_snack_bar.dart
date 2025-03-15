import 'package:flutter/material.dart';
import 'package:flutteractixapp/core/messages/message.dart';
import 'package:flutteractixapp/core/messages/message_mapper.dart';

class GlobalSnackBar {
  static Color _getBackgroundColor(Message message) {
    if (message is SuccessMessage) {
      return Colors.green;
    } else if (message is InfoMessage) {
      return Colors.blueAccent;
    } else {
      return Colors.redAccent;
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
    final backgroundColor = _getBackgroundColor(message);

    return (ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(messageTranslated),
        backgroundColor: backgroundColor,
        showCloseIcon: true,
      ),
    ));
  }
}
