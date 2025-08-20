# Firebase Authentication Setup Guide

## Current Issue
The Firebase Authentication is failing with a `CONFIGURATION_NOT_FOUND` error due to missing reCAPTCHA configuration.

## Quick Fix for Development

### 1. Enable Anonymous Authentication (Temporary)
For immediate testing, use the "Continue as Guest" button which uses anonymous authentication.

### 2. Firebase Console Configuration Required

To fix email/password authentication, you need to configure your Firebase project:

#### Step 1: Go to Firebase Console
1. Visit [Firebase Console](https://console.firebase.google.com/)
2. Select your project: `comnecter-mobile-aa30b`

#### Step 2: Enable Email/Password Authentication
1. Go to **Authentication** > **Sign-in method**
2. Click on **Email/Password**
3. Enable **Email/Password** (first option)
4. Save the changes

#### Step 3: Configure reCAPTCHA (Important)
1. In the same **Sign-in method** section
2. Scroll down to **Advanced** settings
3. Configure **reCAPTCHA** settings:
   - For development: You can disable reCAPTCHA enforcement
   - For production: Configure proper reCAPTCHA keys

#### Step 4: Add Authorized Domains
1. In **Authentication** > **Settings** > **Authorized domains**
2. Make sure these domains are added:
   - `localhost`
   - `comnecter-mobile-aa30b.firebaseapp.com`

## Alternative Solutions

### Option A: Use Anonymous Authentication for Testing
```dart
// This is already implemented - use "Continue as Guest" button
await authService.signInAnonymously();
```

### Option B: Use Firebase Emulator for Development
```bash
# Install Firebase CLI
npm install -g firebase-tools

# Initialize Firebase emulator
firebase init emulators

# Start emulator
firebase emulators:start --only auth
```

## Current Status
- ✅ Firebase Core: Working
- ✅ Anonymous Auth: Working
- ❌ Email/Password Auth: Needs Firebase Console configuration
- ✅ Sign Out: Working

## Next Steps
1. Configure Firebase Console as described above
2. Test email/password authentication
3. Consider implementing additional auth providers (Google, Apple)

## Error Messages
- `CONFIGURATION_NOT_FOUND`: Firebase project needs proper authentication configuration
- `No AppCheckProvider installed`: This is a warning and doesn't affect functionality
