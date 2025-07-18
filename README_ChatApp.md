# 💬 Real-Time Chat App (Flutter + Firebase)

A modern, real-time chat application built using **Flutter** and **Firebase**, enabling users to sign up, log in, and chat instantly with each other. Perfect for one-on-one messaging, this app syncs messages live without refreshing.

---

## 🚀 Features

- 🔐 Firebase Authentication (Email & Password)
- 💬 Real-time messaging using Cloud Firestore
- 📡 Live chat updates with message timestamps
- 👥 User listing and message history
- 🛡️ Secure Firestore Rules
- 💻 Built in Flutter – cross-platform (Android, iOS, Web)

---

## 🧱 Tech Stack

| Layer       | Technology        |
|-------------|-------------------|
| UI          | Flutter            |
| Backend     | Firebase Firestore |
| Auth        | Firebase Auth      |
| Hosting     | Firebase Hosting *(optional)* |

---

## 📲 Screens

- Sign Up / Login Page
- Chat List Screen
- Chat Screen (One-to-One Messaging)
- Real-time typing & sending updates

---

## 🔧 Setup Instructions

### 1. 🔌 Firebase Configuration

- Go to [Firebase Console](https://console.firebase.google.com/)
- Create a project
- Add Android/iOS app
- Enable **Authentication** (Email/Password)
- Enable **Cloud Firestore**

Update `android/app/google-services.json` and `ios/Runner/GoogleService-Info.plist`.

---

### 2. 🛠️ Install Dependencies

```bash
flutter pub get
```

In `pubspec.yaml`:

```yaml
dependencies:
  firebase_core: ^latest
  firebase_auth: ^latest
  cloud_firestore: ^latest
```

---

### 3. 🧪 Firebase Security Rules

```js
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    // Users can only access their own profile
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }

    // Chats between authenticated users
    match /chats/{chatId} {
      allow read: if request.auth != null && (
        request.auth.uid == resource.data.senderId ||
        request.auth.uid == resource.data.receiverId
      );
      allow create: if request.auth != null && request.resource.data.senderId == request.auth.uid;
    }
  }
}
```

---

## 📁 Project Structure

```
lib/
├── main.dart
├── models/
│   └── message_model.dart
│   └── user_model.dart
├── screens/
│   └── login_screen.dart
│   └── signup_screen.dart
│   └── chat_screen.dart
│   └── user_list_screen.dart
├── services/
│   └── auth_service.dart
│   └── chat_service.dart
├── widgets/
│   └── message_bubble.dart
│   └── user_tile.dart
```

---

## ✅ Future Improvements

- Group chats
- Media sharing (images, audio, video)
- Online/offline indicators
- Push notifications

---

## ✨ Demo

Coming soon…

---

## 📜 License

MIT License. Free for personal and commercial use.

---

## 🙌 Author

Made with ❤️ by Goyal