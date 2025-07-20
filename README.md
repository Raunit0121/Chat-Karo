# ChatKaro 💬

A modern, real-time chat application built with Flutter and Firebase, inspired by WhatsApp's design and functionality.

![ChatKaro](https://img.shields.io/badge/Flutter-3.7.2+-blue.svg)
![Firebase](https://img.shields.io/badge/Firebase-Latest-orange.svg)
![Platform](https://img.shields.io/badge/Platform-Cross--Platform-green.svg)

## 📱 Features

### ✨ Core Features
- **Real-time Messaging**: Instant message delivery using Firebase Firestore
- **User Authentication**: Secure email/password authentication with Firebase Auth
- **User Profiles**: Customizable user profiles with name and bio
- **Message Status**: Read receipts and unread message counts
- **Search Functionality**: Find users quickly with real-time search
- **Emoji Support**: Built-in emoji picker for expressive conversations

### 🎨 UI/UX Features
- **Modern Design**: WhatsApp-inspired interface with custom color scheme
- **Smooth Animations**: Lottie animations for enhanced user experience
- **Responsive Layout**: Optimized for various screen sizes
- **Dark/Light Theme**: Adaptive design elements
- **Custom Components**: Reusable widgets for consistent design

### 🔧 Technical Features
- **Cross-Platform**: Support for Android, iOS, Web, Windows, and macOS
- **Real-time Updates**: Live message synchronization
- **Offline Support**: Basic offline functionality
- **Error Handling**: Comprehensive error management
- **Performance Optimized**: Efficient data streaming and caching

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (3.7.2 or higher)
- Dart SDK
- Firebase project
- Android Studio / VS Code
- Git

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/Raunit0121/Chat-Karo
   cd chatkaro
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Firebase Setup**
   - Create a new Firebase project at [Firebase Console](https://console.firebase.google.com/)
   - Enable Authentication (Email/Password)
   - Enable Firestore Database
   - Download `google-services.json` for Android
   - Download `GoogleService-Info.plist` for iOS
   - Place the configuration files in their respective directories

4. **Configure Firebase**
   ```bash
   # Install FlutterFire CLI
   dart pub global activate flutterfire_cli
   
   # Configure Firebase for your project
   flutterfire configure
   ```

5. **Run the application**
   ```bash
   flutter run
   ```

## 📁 Project Structure

```
lib/
├── constants.dart              # App colors and constants
├── firebase_options.dart       # Firebase configuration
├── main.dart                   # App entry point
├── models/
│   ├── message_model.dart      # Message data structure
│   └── user_model.dart         # User data structure
├── screens/
│   ├── chat_screen.dart        # Real-time chat interface
│   ├── login_screen.dart       # User authentication
│   ├── onboarding_screen.dart  # App introduction
│   ├── profile_edit_screen.dart # User profile management
│   ├── signup_screen.dart      # User registration
│   ├── splash_screen.dart      # Loading screen
│   ├── user_list_screen.dart   # Chat list with search
│   └── welcome_screen.dart     # Post-registration welcome
├── services/
│   ├── auth_service.dart       # Firebase authentication
│   └── chat_service.dart       # Real-time messaging
└── widgets/
    ├── custom_app_bar.dart     # Reusable app bar
    ├── message_bubble.dart     # Chat message display
    └── user_tile.dart          # User list item
```

## 🎯 Usage

### User Registration
1. Launch the app
2. Complete the onboarding flow
3. Tap "Sign Up" to create an account
4. Enter your name, email, and password
5. Start chatting!

### Messaging
1. Browse the user list or search for contacts
2. Tap on a user to start a conversation
3. Type your message and send
4. View real-time message status and timestamps

### Profile Management
1. Tap the profile icon in the user list
2. Edit your name and bio
3. Save changes to update your profile

## 🔧 Configuration

### Firebase Configuration
The app requires the following Firebase services:
- **Authentication**: Email/password sign-in
- **Firestore**: Real-time database for messages and user data
- **Storage**: For future file sharing features

### Environment Variables
No additional environment variables are required. All configuration is handled through Firebase configuration files.

## 📱 Screenshots

<p>
  <img src="https://github.com/user-attachments/assets/c30f7c76-c4b9-4edb-94cf-e545f0d51610" width="200"/>
  <img src="https://github.com/user-attachments/assets/2b968da1-01ef-4a50-b21b-b699df82e4c4" width="200"/>
  <img src="https://github.com/user-attachments/assets/3680ecd4-a06b-4397-918c-6a14062b6029" width="200"/>
  <img src="https://github.com/user-attachments/assets/bf1bf503-6d53-403e-9104-26866f15abd8" width="200"/>
  <img src="https://github.com/user-attachments/assets/d4aa3eb9-1c61-4d89-8c36-cdf622875ad1" width="200"/>
  <img src="https://github.com/user-attachments/assets/eddf6c91-24a4-487c-bcd7-a662830d29c2" width="200"/>
  <img src="https://github.com/user-attachments/assets/1ceedcb7-1a9d-41e4-aeea-2ed6264dc4c2" width="200"/>
  <img src="https://github.com/user-attachments/assets/2217a108-477f-4977-b8a6-2e88b32967fc" width="200"/>
</p>



## 🛠️ Dependencies

### Core Dependencies
- `flutter`: ^3.7.2
- `firebase_core`: ^2.30.0
- `firebase_auth`: ^4.17.4
- `cloud_firestore`: ^4.15.8
- `firebase_storage`: ^11.7.4

### UI Dependencies
- `cupertino_icons`: ^1.0.8
- `emoji_picker_flutter`: ^1.6.3
- `lottie`: ^2.7.0
- `image_picker`: ^1.1.1

### Development Dependencies
- `flutter_test`: SDK
- `flutter_lints`: ^2.0.0
- `flutter_native_splash`: ^2.3.10

## 🚀 Deployment

### Android
```bash
flutter build apk --release
```

### iOS
```bash
flutter build ios --release
```

### Web
```bash
flutter build web --release
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- **Flutter Team** for the amazing framework
- **Firebase** for backend services
- **Lottie** for beautiful animations
- **WhatsApp** for design inspiration

## 📞 Support

If you encounter any issues or have questions:
- Create an issue in the GitHub repository
- Check the Firebase documentation for backend issues

## 🔮 Roadmap

- [ ] Group chat functionality
- [ ] File and image sharing
- [ ] Voice messages
- [ ] Video calling
- [ ] Push notifications
- [ ] Message encryption
- [ ] Message reactions
- [ ] User status (online/offline)
- [ ] Message search
- [ ] Message forwarding

---

**Made with ❤️ Raunit Goyal ❤️ using Flutter and Firebase**
