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
    - Download `google-services.json` and move it to `android/app/`.
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

### Step 5: Whitelist Localhost (For Chrome Testing)

1.  Go to [GCP Credentials](https://console.cloud.google.com/apis/credentials).
2.  Find the **Web client** ID (auto-created by Firebase).
3.  Click the Pencil icon to edit.
4.  Under **Authorized JavaScript origins**, add:
    - `http://localhost`
    - `http://localhost:5000`
5.  **Copy the Web Client ID** (you will need it for `index.html`).

### Step 6: Publish the App

1.  Go to **OAuth consent screen**.
2.  Under "Publishing status", click **PUBLISH APP**. This ensures any student can log in without being manually added as a "Test User".

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
- **Hangs on Login?** Did you add the `<meta>` tag to `index.html` in Step 9?
