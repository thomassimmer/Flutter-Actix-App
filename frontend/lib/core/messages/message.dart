abstract class Message {}

class ErrorMessage extends Message {
  final String messageKey;

  ErrorMessage(this.messageKey);
}

class SuccessMessage extends Message {
  final String messageKey;

  SuccessMessage(this.messageKey);
}

class InfoMessage extends Message {
  final String messageKey;

  InfoMessage(this.messageKey);
}
