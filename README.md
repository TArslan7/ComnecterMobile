# Comnecter App - MVP

# Comnecter - Chat App with Community Features and Nearby User Radar

## Overview
This app allows users to chat with each other, form communities around shared interests, and see other users nearby using a radar-like feature. The app uses geolocation to identify nearby users and display them on a radar visualization.

## Features
- User profiles with interests
- Direct messaging between users
- Community creation and chat
- Nearby user radar visualization
- Events creation and management

## Storage Options
The app supports two storage options:
1. **Local Storage**: Uses SharedPreferences to store data locally on the device (works in preview mode)
2. **Firebase**: Uses Firebase Firestore and Realtime Database for cloud storage (requires Firebase setup)

## Firebase Setup (Optional)

The app is designed to work in both local-only mode and with Firebase. Follow these steps to enable Firebase:

### 1. Create a Firebase Project

- Go to the [Firebase Console](https://console.firebase.google.com/)
- Click "Add project" and follow the steps to create a new project
- Once your project is created, click "Continue"

### 2. Add Firebase to your Android app

- In the Firebase console, click the Android icon to add an Android app to your project
- Enter `com.example.dreamflow` as the package name (or your actual package name if different)
- Register the app
- Download the `google-services.json` file
- Move the file to the `android/app/` directory (replacing the sample file)

### 3. Add Firebase to your iOS app

- In the Firebase console, click the iOS icon to add an iOS app to your project
- Enter your Bundle ID (e.g., `com.example.dreamflow`)
- Register the app
- Download the `GoogleService-Info.plist` file
- Move the file to the `ios/Runner/` directory (replacing the sample file)

### 4. Enable Authentication

- In the Firebase console, go to "Authentication" and click "Get started"
- Enable the "Email/Password" sign-in method

### 5. Set up Firestore Database

- In the Firebase console, go to "Firestore Database" and click "Create database"
- Start in test mode for easier development
- Choose a location closest to your users

### 6. Set up Realtime Database

- In the Firebase console, go to "Realtime Database" and click "Create database"
- Start in test mode for easier development
- Choose a location closest to your users

### 7. Update Firebase Rules

For both Firestore and Realtime Database, update the security rules to allow read/write access during development:

```
// Firestore rules
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read, write: if true;
    }
  }
}

// Realtime Database rules
{
  "rules": {
    ".read": true,
    ".write": true
  }
}
```

**IMPORTANT:** These rules allow anyone to read and write to your database. For production, set up proper authentication rules.

## Running in Preview Mode (No Firebase)

The app is configured to automatically fall back to local storage if Firebase initialization fails. This allows the app to run in preview mode without Firebase configuration.

## Development

### Adding New Features

When adding new features that require data storage, follow this pattern:

1. Implement the local storage version first
2. Add the Firebase implementation with conditional logic
3. Ensure fallbacks work properly

Use the `FirebaseConfig.isEnabled` flag to check if Firebase is available at runtime.

### Testing

Test both with and without Firebase to ensure the app works in all scenarios:

- Test with Firebase properly configured
- Test with Firebase dependencies but missing config files (should fall back to local storage)
- Test without any Firebase dependencies (pure local storage mode)