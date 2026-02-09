# Flutter & Firebase: Google Authentication & Realtime Database

---

## 1. Overview

**What we are building:**

- A **Login Screen** with a "Sign in with Google" button.
- A **Dashboard** that displays the logged-in user's info (Name, Email, Photo).
- Integration with **Firebase Realtime Database** to store user status.

**Key Concepts:**

- **OAuth 2.0**: The protocol used by Google Sign-In.
- **Streams**: Listening to authentication state changes in real-time.
- **Asynchronous Programming**: Handling `Future` and `await` for network requests.

---

## 2. Prerequisites (The Setup)

Before coding, we must configure the project in the [Firebase Console](https://console.firebase.google.com/).

### Critical Steps:

1.  **Create Project**: Set up a new Firebase project.
2.  **Enable Auth**: Turn on "Google" in the _Authentication > Sign-in method_ tab.
3.  **Database Rules**: Set Realtime Database rules to allow authenticated read/write:
    ```json
    {
      "rules": {
        "users": {
          "$uid": {
            ".read": "$uid === auth.uid",
            ".write": "$uid === auth.uid"
          }
        }
      }
    }
    ```
4.  **SHA-1 Fingerprint (Android Only)**:
    - Run `gradlew signingReport` in the `android` folder.
    - Copy the `SHA1` key (Debug).
    - Paste it into _Project Settings > Android App > Add Fingerprint_.
    - **Without this, Google Sign-In will FAIL with a generic error.**

---

## 3. Dependencies (`pubspec.yaml`)

We added the following packages to handle Firebase services:

```yaml
dependencies:
  firebase_core: ^4.4.0 # Core Firebase functionality
  firebase_auth: ^6.1.4 # Handling User Authentication
  google_sign_in: ^6.2.1 # Native Google Sign-In flow
  firebase_database: ^12.1.2 # Realtime Database interaction
```

---

## 4. The Logic Layer: `AuthService`

We created a dedicated service class to handle authentication logic, keeping our UI clean.

### Key Code Snippet:

```dart
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // 1. Trigger the native Google Sign-In flow
  Future<User?> signInWithGoogle() async {
    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
    if (googleUser == null) return null;

    // 2. Obtain the auth details (tokens)
    final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

    // 3. Create a new credential
    final AuthCredential credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    // 4. Sign in to Firebase with the credential
    return (await _auth.signInWithCredential(credential)).user;
  }
}
```

---

## 5. The Data Layer: `DatabaseService`

We use this service to write user data to the Realtime Database upon login.

### Key Code Snippet:

```dart
class DatabaseService {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();

  Future<void> saveUserData(User user) async {
    // Write data to: /users/{uid}
    await _dbRef.child('users').child(user.uid).set({
      'email': user.email,
      'displayName': user.displayName,
      'lastSignIn': DateTime.now().toIso8601String(),
    });
  }
}
```

---

## 6. The UI Layer: `LoginScreen` & `HomeScreen`

We built two screens and use a **StreamBuilder** to decide which one to show.

### Managing State in `main.dart`:

```dart
StreamBuilder<User?>(
  stream: AuthService().authStateChanges, // Listens for login/logout
  builder: (context, snapshot) {
    if (snapshot.hasData) {
      return const HomeScreen(); // User is logged in
    } else {
      return const LoginScreen(); // User is logged out
    }
  },
)
```

---

## 7. Configuration Files (`firebase_options.dart`)

This file connects our Flutter code to the specific Firebase project.

- Typically generated via `flutterfire configure`.
- Contains API keys, App IDs, and Project IDs.
- **Must be present** for `Firebase.initializeApp()` to work.

---

## 8. Summary of Flow

1.  **App Starts**: `main.dart` initializes Firebase.
2.  **Auth Check**: `StreamBuilder` checks if a user is already logged in.
3.  **User Clicks Login**: `AuthService.signInWithGoogle()` is called.
4.  **Google Popup**: User selects their Google account.
5.  **Firebase Auth**: Google returns a token -> We exchange it for a Firebase User.
6.  **Database Write**: `DatabaseService` saves the user's info.
7.  **UI Update**: The Stream detects the new user and automatically switches to `HomeScreen`.
