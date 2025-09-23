# 🛠️ Comnecter Development Guide

**Complete development documentation for Comnecter Mobile App**

This guide contains all the essential information for developers working on Comnecter, including setup, deployment, and workflow guidelines.

---

## 📋 **Table of Contents**

1. [Firebase Setup](#firebase-setup)
2. [App Store Launch](#app-store-launch)
3. [Development Workflow](#development-workflow)
4. [Testing Guidelines](#testing-guidelines)
5. [Troubleshooting](#troubleshooting)

---

## 🔥 **Firebase Setup**

### **Prerequisites**
- Google account
- Flutter project ready
- Firebase CLI (optional but recommended)

### **🌐 STEP 1: Create Firebase Project**

1. **Go to [Firebase Console](https://console.firebase.google.com/)**
2. **Click "Create a project"**
3. **Enter project name**: `comnecter-mobile` (or your preferred name)
4. **Enable Google Analytics** (recommended)
5. **Click "Create project"**

### **📱 STEP 2: Add Android App**

1. **In Firebase Console, click "Android" icon**
2. **Enter Android package name**: `com.comnecter.mobile.app`
3. **Enter app nickname**: `ComnecterMobile`
4. **Click "Register app"**
5. **Download `google-services.json`**
6. **Place it in**: `android/app/google-services.json`

### **🍎 STEP 3: Add iOS App**

1. **In Firebase Console, click "iOS" icon**
2. **Enter iOS bundle ID**: `com.comnecter.mobile.app`
3. **Enter app nickname**: `ComnecterMobile`
4. **Click "Register app"**
5. **Download `GoogleService-Info.plist`**
6. **Place it in**: `ios/Runner/GoogleService-Info.plist`

### **🔧 STEP 4: Enable Firebase Services**

#### **Authentication**
1. Go to **Authentication** → **Sign-in method**
2. Enable **Email/Password**
3. Configure additional providers if needed

#### **Firestore Database**
1. Go to **Firestore Database**
2. Click **Create database**
3. Choose **Start in test mode**
4. Select your preferred location

#### **Storage**
1. Go to **Storage**
2. Click **Get started**
3. Choose **Start in test mode**
4. Select your preferred location

#### **Messaging**
1. Go to **Cloud Messaging**
2. No additional setup required for basic functionality

#### **Analytics**
1. Go to **Analytics**
2. Enable **Google Analytics**
3. Link to your Google Analytics account

### **📝 STEP 5: Update Flutter Configuration**

1. **Run FlutterFire CLI**:
   ```bash
   dart pub global activate flutterfire_cli
   flutterfire configure
   ```

2. **Verify configuration**:
   ```bash
   flutter pub get
   flutter run
   ```

---

## 🚀 **App Store Launch**

### **🚀 PRE-LAUNCH CHECKLIST**

#### **✅ Critical Issues Fixed**
- [x] **Main.dart** - Fixed to run Comnecter app instead of demo
- [x] **Android Permissions** - Added location, camera, microphone, storage
- [x] **iOS Permissions** - Added camera, microphone, photo library access
- [x] **Package Names** - Updated for uniqueness
- [x] **Debug Code** - Removed print statements and debug code

#### **⚠️ Remaining Issues to Address**
- [ ] **Deprecated APIs** - Fix remaining `withOpacity` and `background` usage
- [ ] **Performance** - Add missing `const` constructors
- [ ] **Error Handling** - Fix BuildContext async gaps
- [ ] **Unused Code** - Clean up unused methods and imports

### **📱 GOOGLE PLAY STORE REQUIREMENTS**

#### **🔧 Technical Requirements**
- [x] **Minimum SDK**: 21 (Android 5.0)
- [x] **Target SDK**: Latest (Android 14)
- [x] **App Bundle**: APK or AAB format
- [x] **64-bit Support**: Required for new apps
- [x] **Target API Level**: 34+ (Android 14)

#### **📋 Store Listing Requirements**
- [ ] **App Title**: "Comnecter" (max 50 characters)
- [ ] **Short Description**: 80 characters max
- [ ] **Full Description**: 4000 characters max
- [ ] **App Icon**: 512x512 PNG
- [ ] **Screenshots**: 2-8 screenshots per device type
- [ ] **Feature Graphic**: 1024x500 PNG

#### **🔒 Content Rating**
- [ ] **Complete content rating questionnaire**
- [ ] **Age-appropriate content**
- [ ] **Privacy policy link**

### **🍎 APPLE APP STORE REQUIREMENTS**

#### **🔧 Technical Requirements**
- [x] **iOS Deployment Target**: 13.0+
- [x] **Xcode Version**: 14+
- [x] **Swift Version**: 5.0+
- [x] **Architecture**: arm64 (64-bit)

#### **📋 Store Listing Requirements**
- [ ] **App Name**: "Comnecter" (max 30 characters)
- [ ] **Subtitle**: 30 characters max
- [ ] **Description**: 4000 characters max
- [ ] **Keywords**: 100 characters max
- [ ] **App Icon**: 1024x1024 PNG
- [ ] **Screenshots**: 3-10 screenshots per device type

#### **🔒 App Review Guidelines**
- [ ] **Follow Apple Human Interface Guidelines**
- [ ] **No placeholder content**
- [ ] **Proper error handling**
- [ ] **Privacy policy accessible**

---

## 🔄 **Development Workflow**

### **📋 Branching Strategy**

#### **Main Branches:**
- **`master`** - Production-ready code (stable releases only)
- **`develop`** - Integration branch for features (ongoing development)
- **`testing`** - Pre-release testing and validation

#### **Feature Branches:**
- **`feature/feature-name`** - Individual features
- **`bugfix/bug-description`** - Bug fixes
- **`hotfix/urgent-fix`** - Critical production fixes

### **🔄 Development Workflow**

#### **1. Starting New Development**
```bash
# Always start from develop branch
git checkout develop
git pull origin develop

# Create feature branch
git checkout -b feature/new-feature
```

#### **2. Development Process**
```bash
# Make changes and commit
git add .
git commit -m "feat: Add new feature"

# Push to remote
git push origin feature/new-feature
```

#### **3. Code Review Process**
1. **Create Pull Request** to `develop` branch
2. **Request Review** from team members
3. **Address Feedback** and make changes
4. **Merge** after approval

#### **4. Release Process**
```bash
# Merge develop to testing
git checkout testing
git merge develop

# Test thoroughly
flutter test
flutter run --release

# Merge to master for release
git checkout master
git merge testing
git tag v1.0.0
git push origin master --tags
```

---

## 🧪 **Testing Guidelines**

### **🔍 Testing Checklist**

#### **Unit Tests**
- [ ] **Business Logic**: Test all service classes
- [ ] **Models**: Test data models and validation
- [ ] **Utilities**: Test helper functions

#### **Widget Tests**
- [ ] **UI Components**: Test individual widgets
- [ ] **User Interactions**: Test tap, scroll, input
- [ ] **State Changes**: Test state management

#### **Integration Tests**
- [ ] **User Flows**: Test complete user journeys
- [ ] **Firebase Integration**: Test database operations
- [ ] **Authentication**: Test login/signup flows

#### **Manual Testing**
- [ ] **Device Testing**: Test on real devices
- [ ] **Platform Testing**: Test iOS and Android
- [ ] **Performance Testing**: Test app performance

### **🧪 Running Tests**
```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/widget_test.dart

# Run with coverage
flutter test --coverage

# Run integration tests
flutter test integration_test/
```

---

## 🔧 **Troubleshooting**

### **🚨 Common Issues**

#### **Firebase Issues**
- **Authentication not working**: Check Firebase configuration files
- **Database connection failed**: Verify Firestore rules
- **Storage upload failed**: Check storage permissions

#### **Build Issues**
- **iOS build failed**: Check Xcode version and iOS deployment target
- **Android build failed**: Check Android SDK and build tools
- **Dependencies conflict**: Run `flutter clean` and `flutter pub get`

#### **Runtime Issues**
- **App crashes on startup**: Check Firebase initialization
- **Navigation errors**: Verify GoRouter configuration
- **State management issues**: Check Riverpod providers

### **🛠️ Debug Commands**
```bash
# Clean build cache
flutter clean
flutter pub get

# Check Flutter doctor
flutter doctor

# Analyze code
flutter analyze

# Check dependencies
flutter pub deps
```

---

## 📚 **Additional Resources**

### **📖 Documentation**
- [Flutter Documentation](https://flutter.dev/docs)
- [Firebase Documentation](https://firebase.google.com/docs)
- [Riverpod Documentation](https://riverpod.dev/docs)

### **🛠️ Tools**
- [Firebase Console](https://console.firebase.google.com/)
- [Google Play Console](https://play.google.com/console/)
- [App Store Connect](https://appstoreconnect.apple.com/)

### **💡 Best Practices**
- **Code Style**: Follow Flutter/Dart style guidelines
- **Performance**: Use `const` constructors where possible
- **Security**: Never commit API keys or sensitive data
- **Testing**: Write tests for new features
- **Documentation**: Update documentation with changes

---

**Last updated: December 2024**
