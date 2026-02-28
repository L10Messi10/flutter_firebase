class ChatMessage {
  final String id;
  final String text;
  final String senderId;
  final String senderName;
  final String? senderPhoto;
  final DateTime timestamp;

  ChatMessage({
    required this.id,
    required this.text,
    required this.senderId,
    required this.senderName,
    this.senderPhoto,
    required this.timestamp,
  });

  // Create from Firebase data
  factory ChatMessage.fromFirebase(Map<String, dynamic> data, String id) {
    return ChatMessage(
      id: id,
      text: data['text'] ?? '',
      senderId: data['sender_id'] ?? '',
      senderName: data['sender_name'] ?? 'Unknown',
      senderPhoto: data['sender_photo'],
      timestamp: DateTime.fromMillisecondsSinceEpoch(
        data['timestamp'] ?? DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }

  // Convert to Firebase format
  Map<String, dynamic> toFirebase() {
    return {
      'text': text.trim(),
      'sender_id': senderId,
      'sender_name': senderName,
      'sender_photo': senderPhoto,
      'timestamp': timestamp.millisecondsSinceEpoch,
    };
  }

  // For validation
  bool get isValid {
    return text.trim().isNotEmpty && 
           text.trim().length <= 500 && // Reasonable message length limit
           senderId.isNotEmpty &&
           senderName.isNotEmpty;
  }
}
