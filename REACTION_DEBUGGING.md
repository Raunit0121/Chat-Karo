# Reaction Feature Debugging Guide 🔧

If the reaction feature is not working, follow this step-by-step debugging guide.

## 🚨 Common Issues & Solutions

### 1. **Firestore Rules Not Deployed**
**Problem**: Reactions can't be added due to permission denied errors.

**Solution**: 
1. Deploy the updated Firestore rules:
   ```bash
   firebase deploy --only firestore:rules
   ```

2. Check if rules are properly deployed in Firebase Console:
   - Go to Firestore Database → Rules
   - Verify the `isValidReactionUpdate` function is present

### 2. **Message Structure Issues**
**Problem**: Messages don't have the required fields for reactions.

**Solution**:
1. Check if messages have `participants` field
2. Ensure user is in the participants list
3. Verify message exists in Firestore

### 3. **Authentication Issues**
**Problem**: User not authenticated when trying to add reactions.

**Solution**:
1. Check if user is logged in
2. Verify `AuthService().currentUser` is not null
3. Ensure user has valid Firebase Auth token

## 🧪 Testing Steps

### Step 1: Test Basic Functionality
1. Navigate to `/reaction-test` route
2. Create a test message
3. Try adding a reaction
4. Check Firestore console for the message

### Step 2: Check Firestore Console
1. Go to Firebase Console → Firestore Database
2. Look for the `chats` collection
3. Find your test message
4. Check if it has a `reactions` field

### Step 3: Test Real Chat
1. Navigate to `/reaction-demo` route
2. Try long-pressing on a message
3. Select "React to Message"
4. Choose an emoji

## 🔍 Debug Information

### Check Console Logs
Look for these debug messages in your Flutter console:
```
Error adding reaction: [error message]
Error removing reaction: [error message]
```

### Verify Data Structure
Your message document should look like this:
```json
{
  "id": "message_id",
  "senderId": "user_id",
  "receiverId": "user_id",
  "text": "Message text",
  "timestamp": "2024-01-01T12:00:00Z",
  "participants": ["user_id", "other_user_id"],
  "reactions": [
    {
      "userId": "user_id",
      "emoji": "❤️",
      "timestamp": "2024-01-01T12:01:00Z"
    }
  ]
}
```

## 🛠️ Manual Testing

### Test 1: Create Message with Reaction
```dart
// In your test screen
await _chatService.sendMessage(
  receiverId: 'test_user',
  text: 'Test message',
);

// Get the message ID from Firestore console
// Then add reaction
await _chatService.addReaction('actual_message_id', '❤️');
```

### Test 2: Check Reaction Methods
```dart
// Test if methods are accessible
final chatService = ChatService();
print('ChatService instance: ${chatService != null}');

// Test if user is authenticated
final user = AuthService().currentUser;
print('Current user: ${user?.uid}');
```

## 🐛 Common Error Messages

### "Permission denied"
- **Cause**: Firestore rules not deployed or incorrect
- **Fix**: Deploy updated rules

### "Message not found"
- **Cause**: Message ID is incorrect or message doesn't exist
- **Fix**: Use correct message ID from Firestore

### "User not authenticated"
- **Cause**: User not logged in
- **Fix**: Ensure user is authenticated before testing

### "Field 'reactions' is not allowed"
- **Cause**: Firestore rules don't allow reactions field
- **Fix**: Update and deploy Firestore rules

## 📱 UI Testing

### Test Reaction Picker
1. Long press any message
2. Select "React to Message"
3. Verify emoji picker appears
4. Select an emoji
5. Check if reaction is added

### Test Reaction Display
1. Add a reaction to a message
2. Verify reaction bubble appears below message
3. Check if count is displayed correctly
4. Tap reaction bubble to see details

## 🔧 Quick Fixes

### If Nothing Works:
1. **Restart the app** completely
2. **Clear app data** and re-login
3. **Check Firebase project** configuration
4. **Verify internet connection**
5. **Check Firebase Console** for any errors

### Emergency Fix:
If reactions still don't work, temporarily disable Firestore rules:
```javascript
// In firestore.rules - TEMPORARY ONLY
match /chats/{messageId} {
  allow read, write: if request.auth != null;
}
```

**⚠️ Remember to re-enable proper rules after testing!**

## 📞 Getting Help

If you're still having issues:

1. **Check the console logs** for specific error messages
2. **Verify Firebase configuration** in `firebase_options.dart`
3. **Test with a simple message** first
4. **Check if other Firebase features** (auth, messaging) work
5. **Create a minimal test case** to isolate the issue

## 🎯 Success Criteria

The reaction feature is working correctly when:
- ✅ Long press on message shows "React to Message" option
- ✅ Emoji picker appears with 8 emoji options
- ✅ Selecting emoji adds reaction to Firestore
- ✅ Reaction bubble appears below message
- ✅ Reaction count is displayed correctly
- ✅ Tapping reaction shows details
- ✅ Real-time updates work across devices

---

**If you're still experiencing issues, please share the specific error message or behavior you're seeing!**
