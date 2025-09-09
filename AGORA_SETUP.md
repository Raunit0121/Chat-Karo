# Agora Voice & Video Call Setup Guide

This guide will help you set up Agora for voice and video calling in your Chat Karo app.

## 1. Create Agora Account

1. Go to [Agora.io](https://www.agora.io/) and create a free account
2. Sign in to the Agora Console
3. Create a new project:
   - Click "Create Project"
   - Enter project name: "ChatKaro"
   - Choose "Secured mode: APP ID + Token" for authentication
   - Click "Submit"

## 2. Get Your Agora Credentials

After creating the project, you'll see:
- **App ID**: A unique identifier for your project
- **App Certificate**: Used for generating tokens (optional for testing)

## 3. Configure Your App

1. Open `lib/constants.dart`
2. Replace the placeholder values:

```dart
class AgoraConfig {
  // Replace with your actual Agora App ID
  static const String appId = 'YOUR_ACTUAL_AGORA_APP_ID';
  
  // Replace with your actual certificate (optional for testing)
  static const String appCertificate = 'YOUR_ACTUAL_AGORA_APP_CERTIFICATE';
  
  // Token expiration time (24 hours)
  static const int tokenExpirationTime = 24 * 3600;
  
  // Channel settings
  static const String channelPrefix = 'chatkaro_';
}
```

## 4. Testing Mode (No Token Required)

For testing purposes, you can use the App ID without implementing a token server:

1. In Agora Console, make sure your project is set to "Testing Mode"
2. Use only the App ID (leave token as empty string in the code)
3. This allows up to 10,000 minutes of free usage per month

## 5. Production Mode (Token Required)

For production, you'll need to implement a token server:

1. Set your project to "Secured Mode" in Agora Console
2. Implement a backend service to generate tokens
3. Update the `CallService` to fetch tokens from your server

## 6. Features Implemented

✅ **Voice Calls**
- High-quality audio calling
- Mute/unmute functionality
- Speaker toggle
- Call duration tracking

✅ **Video Calls**
- HD video calling
- Camera on/off toggle
- Front/back camera switching
- Picture-in-picture local video

✅ **Call Management**
- Incoming call notifications
- Call accept/decline
- Call end functionality
- Call status tracking

✅ **UI Features**
- Beautiful incoming call screen
- Full-screen call interface
- Animated call controls
- Real-time call duration

## 7. How to Use

### Starting a Call
1. Open any chat conversation
2. Tap the phone icon (📞) for voice call
3. Tap the video icon (📹) for video call

### Receiving a Call
1. Incoming call screen appears automatically
2. Tap green button to answer
3. Tap red button to decline

### During a Call
- **Mute**: Tap microphone icon
- **Video On/Off**: Tap camera icon (video calls)
- **Switch Camera**: Tap switch icon (video calls)
- **Speaker**: Tap speaker icon (voice calls)
- **End Call**: Tap red phone icon

## 8. Troubleshooting

### Common Issues:

1. **"Failed to initialize calling service"**
   - Check if App ID is correctly set
   - Ensure internet connection

2. **"Permissions not granted"**
   - Allow microphone permission for voice calls
   - Allow camera permission for video calls

3. **"Failed to join call"**
   - Check Agora project settings
   - Verify App ID is correct
   - Check network connectivity

### Debug Tips:
- Check Flutter console for Agora logs
- Ensure both users have the app open
- Test with different devices/networks

## 9. Agora Pricing

- **Free Tier**: 10,000 minutes/month
- **Pay-as-you-go**: $0.99 per 1,000 minutes
- **Enterprise**: Custom pricing

## 10. Next Steps

For production deployment:
1. Implement token server for security
2. Add call history storage
3. Add group calling support
4. Implement call recording (if needed)
5. Add push notifications for missed calls

## Support

- Agora Documentation: https://docs.agora.io/
- Agora Community: https://www.agora.io/en/community/
- Flutter Agora Plugin: https://pub.dev/packages/agora_rtc_engine
