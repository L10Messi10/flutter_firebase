import 'dart:developer' as developer;
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Simple test to verify Firebase connectivity
Future<void> testFirebaseConnection() async {
  try {
    developer.log('=== Testing Firebase Connection ===');
    
    // Check authentication
    final user = FirebaseAuth.instance.currentUser;
    developer.log('Authenticated user: ${user?.uid}');
    developer.log('User email: ${user?.email}');
    
    if (user == null) {
      developer.log('ERROR: No authenticated user!');
      return;
    }
    
    // Test database connection
    final dbRef = FirebaseDatabase.instance.ref();
    developer.log('Database URL: ${FirebaseDatabase.instance.databaseURL}');
    
    // Test reading chat_rooms
    final chatRoomsSnapshot = await dbRef.child('chat_rooms').get();
    developer.log('Chat rooms snapshot exists: ${chatRoomsSnapshot.exists}');
    
    if (chatRoomsSnapshot.exists) {
      final data = chatRoomsSnapshot.value as Map<dynamic, dynamic>?;
      developer.log('Chat rooms data: $data');
      developer.log('Number of rooms: ${data?.length ?? 0}');
    } else {
      developer.log('No chat rooms found in database');
    }
    
    // Test writing a simple test entry
    final testRef = dbRef.child('test').push();
    await testRef.set({
      'message': 'Hello from test',
      'user': user.uid,
      'timestamp': ServerValue.timestamp,
    });
    developer.log('Test write successful');
    
    // Clean up test
    await testRef.remove();
    developer.log('Test cleanup successful');
    
    developer.log('=== Firebase Test Complete ===');
    
  } catch (e) {
    developer.log('Firebase test error: $e');
    developer.log('Error type: ${e.runtimeType}');
  }
}
