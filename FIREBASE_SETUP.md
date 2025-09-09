# Firebase Setup Guide for Chat Karo

## 🔥 Firebase Security Rules Setup

### 1. Firestore Security Rules

Copy the contents of `firestore.rules` to your Firebase Console:

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Select your project (`chatkaro-8d37d`)
3. Navigate to **Firestore Database** → **Rules**
4. Replace the existing rules with the content from `firestore.rules`
5. Click **Publish**

**Key Features Protected:**
- ✅ Users can only edit their own profiles
- ✅ Messages are only visible to participants
- ✅ Only senders can edit/delete their messages
- ✅ 24-hour edit window enforced
- ✅ Proper validation for all message operations

### 2. Firebase Storage Rules

Copy the contents of `storage.rules` to your Firebase Console:

1. Go to **Storage** → **Rules**
2. Replace existing rules with content from `storage.rules`
3. Click **Publish**

**Key Features Protected:**
- ✅ Profile pictures: 5MB limit, image files only
- ✅ Chat media: 50MB limit, multiple file types
- ✅ Temporary uploads: 100MB limit with auto-cleanup
- ✅ User isolation: Users can only access their own uploads

### 3. Firestore Indexes

**Option A: Automatic (Recommended)**
The app will automatically suggest creating indexes when you run queries. Click the provided links in the console logs.

**Option B: Manual Setup**
1. Go to **Firestore Database** → **Indexes**
2. Use the `firestore.indexes.json` file to create indexes manually
3. Or use Firebase CLI: `firebase deploy --only firestore:indexes`

## 🚀 Deployment Steps

### 1. Install Firebase CLI
```bash
npm install -g firebase-tools
```

### 2. Login and Initialize
```bash
firebase login
firebase init
```

### 3. Deploy Rules
```bash
# Deploy Firestore rules
firebase deploy --only firestore:rules

# Deploy Storage rules  
firebase deploy --only storage

# Deploy indexes
firebase deploy --only firestore:indexes
```

## 🔧 Required Firebase Services

Make sure these services are enabled in your Firebase project:

### Authentication
- ✅ Email/Password provider
- ✅ Google Sign-In (optional)
- ✅ Anonymous authentication (optional)

### Firestore Database
- ✅ Native mode
- ✅ Multi-region or single region based on your needs

### Cloud Storage
- ✅ Default bucket configured
- ✅ Appropriate region selected

### Cloud Functions (Optional)
For advanced features like push notifications:
- ✅ Blaze plan required
- ✅ Node.js runtime

## 🔐 Security Best Practices

### 1. API Keys
- ✅ Restrict API keys in Google Cloud Console
- ✅ Add your app's package name to restrictions
- ✅ Enable only required APIs

### 2. Database Rules Testing
```bash
# Test rules locally
firebase emulators:start --only firestore
```

### 3. Regular Security Audits
- Monitor Firebase Console for unusual activity
- Review security rules regularly
- Update rules when adding new features

## 📱 App Configuration

### 1. Update Firebase Config
Ensure your `firebase_options.dart` has correct configuration:
- Project ID: `chatkaro-8d37d`
- App ID matches your registered app
- API keys are current

### 2. Permissions
Add required permissions to `android/app/src/main/AndroidManifest.xml`:
```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
```

## 🐛 Troubleshooting

### Common Issues:

1. **Index Errors**: Click the provided links in console logs to create missing indexes
2. **Permission Denied**: Check if rules are properly deployed
3. **Storage Upload Fails**: Verify file size and type restrictions
4. **Authentication Issues**: Ensure providers are enabled in Firebase Console

### Debug Mode:
Enable Firestore debug logging in your app:
```dart
FirebaseFirestore.instance.settings = const Settings(
  persistenceEnabled: true,
  cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
);
```

## 📊 Monitoring

Set up monitoring in Firebase Console:
- **Performance Monitoring**: Track app performance
- **Crashlytics**: Monitor crashes and errors  
- **Analytics**: Track user engagement
- **App Check**: Protect against abuse

## 🔄 Backup Strategy

1. **Firestore Backup**: Enable automatic backups
2. **Storage Backup**: Set up Cloud Storage backup
3. **Rules Versioning**: Keep rules in version control

---

**✅ Your Firebase setup is now complete and secure!**

The rules provide comprehensive protection while allowing all the chat features to work properly. Remember to test thoroughly in a development environment before deploying to production.
