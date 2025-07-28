class Message {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  Message({
    required this.text, 
    required this.isUser,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  @override
  String toString() {
    return 'Message(text: $text, isUser: $isUser, timestamp: $timestamp)';
  }
}