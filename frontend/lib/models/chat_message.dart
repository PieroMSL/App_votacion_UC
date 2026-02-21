class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });

  factory ChatMessage.fromApiResponse(String response) {
    return ChatMessage(
      text: response,
      isUser: false,
      timestamp: DateTime.now(),
    );
  }
}
