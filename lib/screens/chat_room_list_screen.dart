import 'package:flutter/material.dart';
import 'dart:developer' as developer;
import 'package:firebase_database/firebase_database.dart';
import '../chat_service.dart';
import '../models/chat_room.dart';
import '../widgets/room_list_tile.dart';
import 'create_room_screen.dart';
import 'chat_screen.dart';

class ChatRoomListScreen extends StatefulWidget {
  const ChatRoomListScreen({super.key});

  @override
  State<ChatRoomListScreen> createState() => _ChatRoomListScreenState();
}

class _ChatRoomListScreenState extends State<ChatRoomListScreen> {
  final ChatService _chatService = ChatService();
  late Stream<List<ChatRoom>> _roomsStream;

  @override
  void initState() {
    super.initState();
    _roomsStream = _chatService.getChatRooms();
    _chatService.setOnline(); // Set user as online when entering chat
  }

  @override
  void dispose() {
    _chatService.setOffline(); // Set user as offline when leaving
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat Rooms'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _roomsStream = _chatService.getChatRooms();
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.bug_report),
            onPressed: () async {
              // Debug Firebase connection
              try {
                final user = _chatService.currentUser;
                developer.log('Current user: ${user?.uid}');
                developer.log(
                  'Database URL: ${FirebaseDatabase.instance.databaseURL}',
                );

                final dbRef = FirebaseDatabase.instance.ref();
                final snapshot = await dbRef.child('chat_rooms').get();
                developer.log('Chat rooms exist: ${snapshot.exists}');
                if (snapshot.exists) {
                  developer.log('Chat rooms data: ${snapshot.value}');
                }

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Debug info logged to console. User: ${user?.uid ?? "None"}',
                      ),
                      duration: const Duration(seconds: 3),
                    ),
                  );
                }
              } catch (e) {
                developer.log('Debug error: $e');
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Debug error: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
          ),
        ],
      ),
      body: StreamBuilder<List<ChatRoom>>(
        stream: _roomsStream,
        builder: (context, snapshot) {
          // Debug logging
          developer.log('StreamBuilder state: ${snapshot.connectionState}');
          if (snapshot.hasError) {
            developer.log('StreamBuilder error: ${snapshot.error}');
          }
          if (snapshot.hasData) {
            developer.log('StreamBuilder data count: ${snapshot.data?.length}');
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading chat rooms',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    snapshot.error.toString(),
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          final rooms = snapshot.data ?? [];

          if (rooms.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    Icon(Icons.chat, size: 48, color: Colors.blue),
                    const SizedBox(height: 12),
                    Text(
                      'Join Chat Rooms',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Connect with others in real-time chat rooms',
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              setState(() {
                _roomsStream = _chatService.getChatRooms();
              });
            },
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              itemCount: rooms.length,
              itemBuilder: (context, index) {
                final room = rooms[index];
                return RoomListTile(
                  room: room,
                  onTap: () => _navigateToChat(room),
                  participantCountStream: _chatService.getParticipantCount(
                    room.id,
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToCreateRoom,
        tooltip: 'Create Room',
        child: const Icon(Icons.add),
      ),
    );
  }

  void _navigateToCreateRoom() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CreateRoomScreen()),
    );
  }

  void _navigateToChat(ChatRoom room) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(roomId: room.id, roomName: room.name),
      ),
    );
  }
}
