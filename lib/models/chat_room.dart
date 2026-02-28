class ChatRoom {
  final String id;
  final String name;
  final String createdBy;
  final DateTime createdAt;
  final int participantCount;

  ChatRoom({
    required this.id,
    required this.name,
    required this.createdBy,
    required this.createdAt,
    this.participantCount = 0,
  });

  // Create from Firebase data
  factory ChatRoom.fromFirebase(Map<String, dynamic> data, String id) {
    return ChatRoom(
      id: id,
      name: data['name'] ?? 'Unknown Room',
      createdBy: data['created_by'] ?? '',
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        data['created_at'] ?? DateTime.now().millisecondsSinceEpoch,
      ),
      participantCount: data['participant_count'] ?? 0,
    );
  }

  // Convert to Firebase format
  Map<String, dynamic> toFirebase() {
    return {
      'name': name.trim(),
      'created_by': createdBy,
      'created_at': createdAt.millisecondsSinceEpoch,
      'participant_count': participantCount,
    };
  }

  // For validation
  bool get isValid {
    return name.trim().isNotEmpty &&
        name.trim().length <= 50 && // Reasonable room name length
        createdBy.isNotEmpty;
  }
}
