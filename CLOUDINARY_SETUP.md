# Cloudinary Setup Guide for Chat-Karo

This guide will help you set up Cloudinary for profile picture uploads and image optimization in your Flutter chat application.

## Prerequisites

1. A Cloudinary account (sign up at [cloudinary.com](https://cloudinary.com))
2. Flutter project with the required dependencies

## Step 1: Get Your Cloudinary Credentials

1. Log in to your Cloudinary dashboard
2. Go to the **Dashboard** section
3. Copy the following credentials:
   - **Cloud Name**
   - **API Key**
   - **API Secret**

## Step 2: Create Upload Preset

1. In your Cloudinary dashboard, go to **Settings** > **Upload**
2. Scroll down to **Upload presets**
3. Click **Add upload preset**
4. Configure the preset:
   - **Preset name**: `chatkaro_upload` (or any name you prefer)
   - **Signing Mode**: `Unsigned` (for client-side uploads)
   - **Folder**: `chatkaro/profiles`
   - **Allowed formats**: `jpg, png, gif, webp`
   - **Max file size**: `10MB` (or your preferred limit)
   - **Transformation**: `c_fill,g_face,h_400,w_400,f_auto,q_auto`
5. Save the preset

## Step 3: Update Configuration

Open `lib/config/cloudinary_config.dart` and replace the placeholder values:

```dart
class CloudinaryConfig {
  // Replace these with your actual Cloudinary credentials
  static const String cloudName = 'your_actual_cloud_name';
  static const String uploadPreset = 'your_actual_upload_preset';
  static const String apiKey = 'your_actual_api_key';
  static const String apiSecret = 'your_actual_api_secret';
  
  // ... rest of the configuration
}
```

## Step 4: Install Dependencies

Run the following command to install the required packages:

```bash
flutter pub get
```

## Step 5: Platform-Specific Setup

### Android

Add the following permissions to `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
```

### iOS

Add the following keys to `ios/Runner/Info.plist`:

```xml
<key>NSCameraUsageDescription</key>
<string>This app needs camera access to take profile pictures</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>This app needs photo library access to select profile pictures</string>
```

## Step 6: Test the Integration

1. Run your Flutter app
2. Go to the profile edit screen
3. Try uploading a profile picture
4. Verify that the image appears in your Cloudinary dashboard

## Features Included

### Profile Picture Management
- **Upload**: Users can upload profile pictures from gallery or camera
- **Optimization**: Images are automatically optimized for different sizes
- **Transformation**: Face detection and cropping for better profile pictures
- **Caching**: Cloudinary CDN provides fast image delivery

### Image Transformations
- **Profile Pictures**: 200x200px with face detection and cropping
- **Thumbnails**: 50x50px for user lists
- **Chat Images**: 400px max width for chat messages (future feature)

### Security
- **Upload Preset**: Unsigned uploads with preset restrictions
- **File Validation**: Only allowed formats and sizes
- **Folder Organization**: Images organized in `chatkaro/profiles` folder

## Troubleshooting

### Common Issues

1. **Upload Failed**: Check your upload preset configuration
2. **Images Not Loading**: Verify your cloud name and public IDs
3. **Permission Denied**: Ensure proper platform permissions are set
4. **Network Errors**: Check internet connectivity and Cloudinary service status

### Debug Tips

1. Check the console for error messages
2. Verify credentials in `cloudinary_config.dart`
3. Test upload preset in Cloudinary dashboard
4. Check network tab for failed requests

## Advanced Configuration

### Custom Transformations

You can modify the transformation parameters in `CloudinaryService`:

```dart
// For different image styles
String getProfilePictureUrl(String publicId, {int size = 200}) {
  return 'https://res.cloudinary.com/$_cloudName/image/upload/c_fill,g_face,h_$size,w_$size,f_auto,q_auto,r_max/$publicId';
}
```

### Environment-Specific Configs

You can create different configurations for development and production:

```dart
class CloudinaryConfig {
  static const bool isProduction = bool.fromEnvironment('PRODUCTION', defaultValue: false);
  
  static String get cloudName => isProduction 
    ? 'prod_cloud_name' 
    : 'dev_cloud_name';
}
```

## Support

For more information about Cloudinary:
- [Cloudinary Documentation](https://cloudinary.com/documentation)
- [Flutter Cloudinary Package](https://pub.dev/packages/cloudinary_public)
- [Image Transformations Guide](https://cloudinary.com/documentation/image_transformations) 