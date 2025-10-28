# Video Call Setup Instructions

## Overview

A basic video call feature has been added to your chat application using Agora RTC Engine. This implementation includes:

- Video call button in the chat screen
- Basic video call interface with camera and microphone controls
- Mute/unmute functionality
- Video on/off toggle
- Speaker toggle
- End call functionality

## Setup Steps

### 1. Get Agora App ID

1. Go to [Agora Console](https://console.agora.io/)
2. Create a new project or use an existing one
3. Copy your App ID

### 2. Update Configuration

1. Open `lib/config/agora_config.dart`
2. Replace `YOUR_AGORA_APP_ID` with your actual Agora App ID

```dart
class AgoraConfig {
  static const String appId = 'your_actual_app_id_here';
  // ... rest of the config
}
```

### 3. Install Dependencies

Run the following command to install the new dependencies:

```bash
flutter pub get
```

### 4. Platform-Specific Setup

#### Android

Add the following permissions to `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.RECORD_AUDIO" />
<uses-permission android:name="android.permission.MODIFY_AUDIO_SETTINGS" />
<uses-permission android:name="android.permission.ACCESS_WIFI_STATE" />
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
```

#### iOS

Add the following permissions to `ios/Runner/Info.plist`:

```xml
<key>NSCameraUsageDescription</key>
<string>This app needs access to camera for video calls</string>
<key>NSMicrophoneUsageDescription</key>
<string>This app needs access to microphone for video calls</string>
```

### 5. Testing

1. Run the app on two different devices or simulators
2. Start a chat between two users
3. Tap the video call button (camera icon) in the chat screen
4. Both users should see the video call interface

## Features Included

- **Video Call Button**: Located in the chat screen app bar
- **Camera Controls**: Toggle video on/off
- **Microphone Controls**: Mute/unmute audio
- **Speaker Controls**: Toggle speaker/earpiece
- **End Call**: Terminate the video call
- **Picture-in-Picture**: Local video appears as a small window

## Notes

- This is a basic implementation for testing purposes
- For production use, you should implement proper token generation on your server
- The current implementation uses empty tokens which work for testing but have limitations
- Both users need to be in the same channel to see each other's video

## Troubleshooting

1. **No video showing**: Check camera permissions
2. **No audio**: Check microphone permissions
3. **Can't join channel**: Verify your Agora App ID is correct
4. **Users can't see each other**: Ensure both users are using the same channel name

## Next Steps (Optional)

For production use, consider adding:

- Server-side token generation
- Call notifications
- Call history
- Screen sharing
- Group video calls
- Call quality indicators
