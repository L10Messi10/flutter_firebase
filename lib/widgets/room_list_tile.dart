import 'package:flutter/material.dart';
import '../models/chat_room.dart';

class RoomListTile extends StatelessWidget {
  final ChatRoom room;
  final VoidCallback onTap;
  final Stream<int>? participantCountStream;

  const RoomListTile({
    super.key,
    required this.room,
    required this.onTap,
    this.participantCountStream,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primary,
          child: Text(
            room.name.isNotEmpty ? room.name[0].toUpperCase() : '?',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          room.name,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Text(
          'Created ${_formatTimestamp(room.createdAt)}',
          style: TextStyle(color: Colors.grey[600], fontSize: 14),
        ),
        trailing: StreamBuilder<int>(
          stream: participantCountStream,
          builder: (context, snapshot) {
            final count = snapshot.data ?? room.participantCount;
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Icon(
                  Icons.chat_bubble_outline,
                  size: 20,
                  color: Colors.grey[600],
                ),
                const SizedBox(height: 4),
                Text(
                  '$count members',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            );
          },
        ),
        onTap: onTap,
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays == 0) {
      return 'today';
    } else if (difference.inDays == 1) {
      return 'yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 30) {
      return '${(difference.inDays / 7).floor()} weeks ago';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }
}
