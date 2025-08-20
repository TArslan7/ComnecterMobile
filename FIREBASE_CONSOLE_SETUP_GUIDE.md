# 🔥 Firebase Console Setup Guide - Step by Step

## 🚨 Current Issue
Both **Email/Password** AND **Anonymous** authentication are disabled in your Firebase project, causing these errors:
- `CONFIGURATION_NOT_FOUND` for email/password
- `admin-restricted-operation` for anonymous sign-in

## 🛠️ Complete Firebase Console Setup

### Step 1: Access Firebase Console
1. Go to: https://console.firebase.google.com/
2. Sign in with your Google account
3. Select your project: **comnecter-mobile-aa30b**

### Step 2: Enable Authentication
1. In the left sidebar, click **"Authentication"**
2. Click **"Get started"** if you see this button
3. Go to the **"Sign-in method"** tab

### Step 3: Enable Email/Password Authentication
1. Find **"Email/Password"** in the list
2. Click on it
3. **Enable** the first option (Email/Password)
4. Click **"Save"**

### Step 4: Enable Anonymous Authentication
1. Find **"Anonymous"** in the list
2. Click on it
3. **Enable** the option
4. Click **"Save"**

### Step 5: Configure reCAPTCHA (Optional for Development)
1. In the **Sign-in method** tab, scroll down to **"Advanced"**
2. Find **"reCAPTCHA"** settings
3. For development, you can disable reCAPTCHA enforcement
4. For production, configure proper reCAPTCHA keys

### Step 6: Test Authentication
1. Go back to your Flutter app
2. Try **"Continue as Guest"** - should work now
3. Try **email/password sign up** - should work now

## 🔧 Alternative: Quick Test with Firebase Emulator

If you want to test immediately without console setup:

```bash
# Install Firebase CLI
npm install -g firebase-tools

# Login to Firebase
firebase login

# Initialize emulator
firebase init emulators

# Start auth emulator
firebase emulators:start --only auth
```

## 📱 Expected Results After Setup

- ✅ **Anonymous Authentication**: "Continue as Guest" works
- ✅ **Email/Password Sign Up**: Create new accounts
- ✅ **Email/Password Sign In**: Login with existing accounts
- ✅ **Sign Out**: Works from settings screen

## 🆘 If Still Having Issues

1. **Check Firebase Project ID**: Ensure it matches `comnecter-mobile-aa30b`
2. **Verify API Key**: Check `google-services.json` and `firebase_options.dart`
3. **Enable Authentication Service**: Make sure Authentication is enabled in project
4. **Check Billing**: Some features require billing to be enabled

## 📞 Support
If you continue having issues:
1. Check Firebase Console for error messages
2. Verify your project configuration
3. Ensure you have proper permissions on the Firebase project

## 🎯 Next Steps After Fix
1. Test anonymous authentication
2. Test email/password sign up
3. Test complete user flow
4. Integrate with user profile management
