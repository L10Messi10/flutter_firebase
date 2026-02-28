# Step-by-Step Guide: Google Auth & Realtime Database

Welcome! This guide will take you from a blank project to a fully functional Flutter app with Google Sign-In and a Realtime Database.

---

## Phase 1: The Firebase Console (The Foundation)

Before writing any code, we must set up our project's "Home" on Google.

### Step 1: Create a Firebase Project

1.  Go to the [Firebase Console](https://console.firebase.google.com/).
2.  Click **Create a project** and give it a name.

### Step 2: Add Your Platforms

1.  **Android**:
    - Package Name: `com.example.flutter_firebase` (Must match your `android/app/build.gradle`).
    - **SHA-1 Fingerprint**: Get this by running `.\gradlew signingReport` in your `android` folder. Use the key from the `debug` variant.
    - **Alternative**: If Gradle still won't work, you can get the SHA-1 directly using the Java keytool utility. Run this command in your terminal (replace <YourUser> with your Windows username):

    ```powershell
    keytool -list -v -keystore "C:\Users\<YourUser>\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android
    ```

    - **"Missing Keystore" Error?**: If it says the file is missing, it's usually because you haven't run the app on Android yet.
      - **Easy Fix**: Connect an emulator or device and run `flutter run`. This creates the file automatically.
      - **Manual Fix**: Run this command to create a new debug keystore:
        ```powershell
        keytool -genkey -v -keystore "C:\Users\<YourUser>\.android\debug.keystore" -storepass android -alias androiddebugkey -keypass android -keyalg RSA -keysize 2048 -validity 10000 -dname "CN=Android Debug,O=Android,C=US"
        ```
    - Download `google-services.json` and move it to `android/app/`.
    - **Error**: If you get an error like "keytool is not recognized as an internal or external command", it means Java is not installed or not added to your system's PATH. You must install **Java Development Kit (JDK) 17** first.
    - **Download Links (Windows):**
      - [Microsoft Build of OpenJDK 17](https://aka.ms/download-jdk17-windows-x64) (Official Microsoft Installer)
      - [Eclipse Temurin 17](https://adoptium.net/temurin/releases/?version=17) (Community Standard)

2.  **Web**:
    - Click **"Add App"** > Select **Web**.
    - Register the app and copy the `firebaseConfig` object (you'll need this later).

### Step 3: Enable Services

1.  **Authentication**: Go to _Build > Authentication > Sign-in method_. Enable **Google**.
2.  **Database**: Go to _Build > Realtime Database_. Create a database and set the rules to:
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

---

## Phase 2: Google Cloud Console (The Security Gate)

Because we are using Google Sign-In on the Web, we need to handle a few extra security steps in the **Google Cloud Console**.

### Step 4: Enable the People API

1.  Go to [GCP Library](https://console.cloud.google.com/apis/library).
2.  Search for **Google People API** and click **ENABLE**. (This allows you to see the user's name and photo).

### Step 5. **Whitelist Localhost (For Chrome Testing)**:

    - Go to [GCP Credentials](https://console.cloud.google.com/apis/credentials).
    - Find the **Web client** ID (auto-created by Firebase).
    - Click the Pencil icon to edit.
    - Under **Authorized JavaScript origins**, add:
      - `http://localhost`
      - `http://localhost:5000`
    - **Note**: *Without this, Google may block the login request for students even if it works for you.*
    - **Copy the Web Client ID** (you will need it for `index.html`).

6.  **Publish the App**:
    - Go to **OAuth consent screen**.
    - Under "Publishing status", click **PUBLISH APP**.
    - **Why this matters**: _Without this, you would have to manually add every student's email as a "Test User". Publishing makes it open to everyone._

---

## Phase 3: Flutter Implementation (The Code)

### Step 7: Add Dependencies

In your `pubspec.yaml`, add these packages:

```yaml
dependencies:
  firebase_core: ^latest_version
  firebase_auth: ^latest_version
  google_sign_in: ^6.2.1
  firebase_database: ^latest_version
```

### Step 8: Create the Services

- **AuthService**: Handles the logic for `signInWithGoogle()` and `signOut()`.
- **DatabaseService**: Handles saving user profile data to the `/users/{uid}` path.

### Step 9: Configure index.html (Web Only)

Inside your `web/index.html` <head> tag, add your **Web Client ID**:

```html
<meta name="google-signin-client_id" content="PASTE_YOUR_WEB_CLIENT_ID_HERE" />
```

---

## Phase 4: Connecting Flutter to Firebase

### Option A: The "Easy way" (CLI)

1.  Run `dart pub global activate flutterfire_cli`.
2.  Run `flutterfire configure` and select your project.

### Option B: The "Manual way"

If CLI fails, open `lib/firebase_options.dart` and manually paste your:

- `apiKey`
- `appId`
- `projectId`
- `databaseURL` (Important for Web!)

---

## Phase 5: Run and Test!

1.  Run `flutter run`.
2.  Click the **Sign-in with Google** button.
3.  Check the **Firebase Console > Realtime Database** to see your user data appearing live!

---

## 10. Security: Are my API Keys safe?

You might notice that `firebase_options.dart` contains API Keys. In standard web development, we are taught NEVER to show API Keys. However, **Firebase is different.**

### 1. API Keys are "Identifiers"

In Firebase (including Realtime Database), the API key is not a "secret" like a credit card number. It is an **Identifier** that tells Google which project your app wants to talk to. Even if someone steals your API key, they cannot access your **Realtime Database** data unless they bypass your **Security Rules**.

### 2. The Real Shield: Security Rules

Security happens at the database level. Because we set our **Realtime Database Rules** in Step 3 to only allow users to read/write their **own** data (`auth.uid === $uid`), a hacker with your API key is still blocked from seeing other people's data. They can connect to the database, but the server will say "Permission Denied" for every single request they try to make.

### 3. Extra Protection (API Restrictions)

If you want to be even safer, you can go to **Google Cloud Console > Credentials**, find your API key, and restrict it so it only works on your specific website URL or Android App ID.

---

## 11. Conclusion & Next Steps

## Troubleshooting Checklist

- **401 Error on Web?** Double-check your Web Client ID and Localhost whitelisting in Step 5.
- **Access Blocked / Testing mode?** Did you click "PUBLISH APP" in Step 6?
- **Android Login Fails?** Re-check your SHA-1 fingerprint in Step 2.
- **Hangs on Login or "ClientID not set" error?**
  - First, ensure you added the `<meta>` tag to `web/index.html` in Step 9.
  - **The Definitive Fix**: Sometimes Flutter fails to read the meta tag. You should pass the Client ID explicitly in your code within `lib/auth_service.dart`:
    ```dart
    final GoogleSignIn _googleSignIn = GoogleSignIn(
      clientId: kIsWeb ? 'YOUR_WEB_CLIENT_ID.apps.googleusercontent.com' : null,
    );
    ```
