import 'dart:developer' as developer;
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'models/chat_message.dart';
import 'models/chat_room.dart';

class ChatService {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Stream of all chat rooms
  Stream<List<ChatRoom>> getChatRooms() {
    return _dbRef.child('chat_rooms').onValue.map((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data == null) return <ChatRoom>[];

      final rooms = <ChatRoom>[];
      data.forEach((key, value) {
        if (value is Map) {
          final roomData = Map<String, dynamic>.from(value);
          rooms.add(ChatRoom.fromFirebase(roomData, key));
        }
      });
      return rooms;
    });
  }

  // Stream of messages for a specific room
  Stream<List<ChatMessage>> getMessages(String roomId) {
    return _dbRef
        .child('chat_rooms')
        .child(roomId)
        .child('messages')
        .orderByChild('timestamp')
        .limitToLast(50) // Load last 50 messages for performance
        .onValue
        .map((event) {
          final data = event.snapshot.value as Map<dynamic, dynamic>?;
          if (data == null) return <ChatMessage>[];

          final messages = <ChatMessage>[];
          data.forEach((key, value) {
            if (value is Map) {
              final messageData = Map<String, dynamic>.from(value);
              messages.add(ChatMessage.fromFirebase(messageData, key));
            }
          });

          // Sort messages by timestamp (oldest first for proper chat display)
          messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));

          return messages;
        });
  }

  // Create a new chat room
  Future<String?> createChatRoom(String name) async {
    try {
      final user = currentUser;
      if (user == null) return null;

      final room = ChatRoom(
        id: '', // Will be set by Firebase
        name: name,
        createdBy: user.uid,
        createdAt: DateTime.now(),
      );

      if (!room.isValid) return null;

      final roomRef = _dbRef.child('chat_rooms').push();
      await roomRef.set(room.toFirebase());

      // Add creator as participant
      await roomRef.child('participants').child(user.uid).set(true);

      return roomRef.key;
    } catch (e) {
      developer.log('Error creating chat room: $e');
      return null;
    }
  }

  // Send a message to a chat room
  Future<bool> sendMessage(String roomId, String text) async {
    try {
      final user = currentUser;
      if (user == null) return false;

      // Ensure sender is a participant
      await _dbRef
          .child('chat_rooms')
          .child(roomId)
          .child('participants')
          .child(user.uid)
          .set(true);

      // Update participant count
      await _updateParticipantCount(roomId);

      final message = ChatMessage(
        id: '', // Will be set by Firebase
        text: text,
        senderId: user.uid,
        senderName: user.displayName ?? 'Anonymous',
        senderPhoto: user.photoURL,
        timestamp: DateTime.now(),
      );

      if (!message.isValid) return false;

      await _dbRef
          .child('chat_rooms')
          .child(roomId)
          .child('messages')
          .push()
          .set(message.toFirebase());

      // Update last activity timestamp for the room
      await _dbRef
          .child('chat_rooms')
          .child(roomId)
          .child('last_activity')
          .set(ServerValue.timestamp);

      return true;
    } catch (e) {
      developer.log('Error sending message: $e');
      return false;
    }
  }

  // Join a chat room (add/update user as participant)
  Future<bool> joinChatRoom(String roomId) async {
    try {
      final user = currentUser;
      if (user == null) return false;

      await _dbRef
          .child('chat_rooms')
          .child(roomId)
          .child('participants')
          .child(user.uid)
          .update({
            'status': 'online',
            'last_seen': ServerValue.timestamp,
            'joined_at': ServerValue.timestamp,
            'name': user.displayName,
            'photo_url': user.photoURL,
          });

      return true;
    } catch (e) {
      developer.log('Error joining chat room: $e');
      return false;
    }
  }

  // Leave a chat room (mark user as offline)
  Future<bool> leaveChatRoom(String roomId) async {
    try {
      final user = currentUser;
      if (user == null) return false;

      await _dbRef
          .child('chat_rooms')
          .child(roomId)
          .child('participants')
          .child(user.uid)
          .update({'status': 'offline', 'last_seen': ServerValue.timestamp});

      return true;
    } catch (e) {
      developer.log('Error leaving chat room: $e');
      return false;
    }
  }

  // Update participant count for a room
  Future<void> _updateParticipantCount(String roomId) async {
    try {
      final participantsSnapshot = await _dbRef
          .child('chat_rooms')
          .child(roomId)
          .child('participants')
          .get();

      if (participantsSnapshot.exists) {
        final participants =
            participantsSnapshot.value as Map<dynamic, dynamic>?;
        final count = participants?.length ?? 0;

        await _dbRef
            .child('chat_rooms')
            .child(roomId)
            .child('participant_count')
            .set(count);
      }
    } catch (e) {
      developer.log('Error updating participant count: $e');
    }
  }

  // Update user presence
  Future<void> updatePresence(String status) async {
    try {
      final user = currentUser;
      if (user == null) return;

      await _dbRef.child('user_presence').child(user.uid).set({
        'status': status,
        'last_seen': ServerValue.timestamp,
        'display_name': user.displayName,
        'photo_url': user.photoURL,
      });
    } catch (e) {
      developer.log('Error updating presence: $e');
    }
  }

  // Set user as online when app starts
  Future<void> setOnline() async {
    await updatePresence('online');
  }

  // Set user as offline when app closes
  Future<void> setOffline() async {
    await updatePresence('offline');
  }

  // Get participant count for a room (counts all users who ever joined)
  Stream<int> getParticipantCount(String roomId) {
    return _dbRef
        .child('chat_rooms')
        .child(roomId)
        .child('participants')
        .onValue
        .map((event) {
          final data = event.snapshot.value as Map<dynamic, dynamic>?;
          return data?.length ??
              0; // Count all participants regardless of status
        });
  }
}
