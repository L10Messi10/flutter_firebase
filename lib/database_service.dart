import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DatabaseService {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();

  // Save User Data
  Future<void> saveUserData(User user) async {
    await _dbRef.child('users').child(user.uid).set({
      'uid': user.uid,
      'email': user.email,
      'displayName': user.displayName,
      'photoURL': user.photoURL,
      'lastSignIn': DateTime.now().toIso8601String(),
    });
  }

  // Example: Update a specific field
  Future<void> updateUserStatus(String uid, String status) async {
    await _dbRef.child('users').child(uid).update({'status': status});
  }
}
