class ChatMessage {
  final String id;
  final String roomId;
  final String senderId;
  final String content;
  final DateTime timestamp;
  final bool encrypted;

  ChatMessage({
    required this.id,
    required this.roomId,
    required this.senderId,
    required this.content,
    required this.timestamp,
    this.encrypted = true,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] ?? '',
      roomId: json['room_id'] ?? '',
      senderId: json['sender_id'] ?? '',
      content: json['content'] ?? '',
      timestamp: DateTime.tryParse(json['timestamp'] ?? '') ?? DateTime.now(),
      encrypted: json['encrypted'] ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'room_id': roomId,
    'sender_id': senderId,
    'content': content,
    'timestamp': timestamp.toIso8601String(),
    'encrypted': encrypted,
  };
}
