class ChatRoom {
  final String id;
  final String name;
  final List<String> participants;
  final DateTime createdAt;
  final ChatMessage? lastMessage;

  ChatRoom({
    required this.id,
    required this.name,
    required this.participants,
    required this.createdAt,
    this.lastMessage,
  });

  factory ChatRoom.fromJson(Map<String, dynamic> json) {
    return ChatRoom(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      participants: List<String>.from(json['participants'] ?? []),
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      lastMessage: json['last_message'] != null 
          ? ChatMessage.fromJson(json['last_message']) 
          : null,
    );
  }
}
