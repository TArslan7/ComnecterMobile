# 🚀 Comnecter Mobile

**Connect with people nearby using advanced radar technology**

Comnecter is a revolutionary Flutter-based mobile application that enables users to discover and connect with people in their immediate vicinity through proximity-based networking and social features.

---

## ✨ **Core Features**

### 🔍 **Radar Detection**
- **Real-time User Detection**: Discover nearby users using advanced radar technology
- **Proximity-based Networking**: Connect with people within customizable range settings
- **Interactive Radar Interface**: Beautiful circular radar visualization with scanning animations
- **Range Customization**: Adjustable detection radius with multiple unit options
- **Sound Effects**: Audio feedback for user detection and interactions

### 👥 **Social Networking**
- **Friends Management**: Add, remove, and manage your friend connections
- **User Profiles**: View detailed profiles of detected users
- **Friend Requests**: Send and receive friend requests seamlessly
- **Social Discovery**: Find new connections through proximity detection

### 💬 **Real-time Chat**
- **Instant Messaging**: Chat with your friends in real-time
- **Message History**: Persistent chat history with Firebase Firestore
- **Push Notifications**: Get notified of new messages instantly
- **Chat Interface**: Modern, intuitive chat UI with smooth animations

### 🔐 **Authentication & Security**
- **Firebase Authentication**: Secure email/password authentication
- **Two-Factor Authentication**: Enhanced security with 2FA support
- **User Registration**: Simple sign-up process with email verification
- **Secure Sessions**: Persistent login sessions with automatic token refresh

### ⚙️ **Settings & Customization**
- **App Preferences**: Customize your app experience
- **Notification Settings**: Control push notification preferences
- **Privacy Controls**: Manage your visibility and privacy settings
- **Theme Options**: Light/dark mode support

### 📱 **Cross-Platform Support**
- **iOS & Android**: Native performance on both platforms
- **Responsive Design**: Optimized for all screen sizes
- **Platform-specific Features**: Leverages platform capabilities

---

## 🛠 **Technical Stack**

### **Frontend**
- **Flutter 3.0+**: Modern cross-platform framework
- **Dart**: Type-safe programming language
- **Riverpod**: State management solution
- **GoRouter**: Declarative routing
- **Flutter Hooks**: React-like hooks for Flutter

### **Backend & Services**
- **Firebase Core**: Backend-as-a-Service platform
- **Firebase Auth**: User authentication and management
- **Cloud Firestore**: Real-time NoSQL database
- **Firebase Storage**: File storage and management
- **Firebase Messaging**: Push notifications
- **Firebase Analytics**: User behavior analytics

### **Location & Maps**
- **Google Maps**: Interactive map integration
- **Geolocator**: Location services and permissions
- **Geocoding**: Address and coordinate conversion

### **UI/UX**
- **Material Design**: Google's design system
- **Flutter Animate**: Smooth animations and transitions
- **Shimmer Effects**: Loading state animations
- **Confetti**: Celebration animations

---

## 📋 **Prerequisites**

### **Development Environment**
- **Flutter SDK**: Latest stable version (3.0+)
- **Dart SDK**: Latest stable version
- **Xcode 14+**: For iOS development (macOS only)
- **Android Studio**: For Android development
- **VS Code/Android Studio**: Recommended IDEs

### **Platform Requirements**
- **iOS**: iOS 13.0+ (iPhone/iPad)
- **Android**: API Level 21+ (Android 5.0+)
- **macOS**: macOS 10.14+ (for iOS development)

### **External Services**
- **Firebase Project**: Active Firebase project with required services
- **Google Cloud Console**: For Maps API and other Google services
- **Apple Developer Account**: For iOS App Store distribution
- **Google Play Console**: For Android Play Store distribution

---

## 🚀 **Quick Start**

### **1. Clone the Repository**
```bash
git clone https://github.com/TArslan7/ComnecterMobile.git
cd ComnecterMobile
```

### **2. Install Dependencies**
```bash
flutter pub get
```

### **3. Firebase Setup**
1. Create a new Firebase project at [Firebase Console](https://console.firebase.google.com/)
2. Enable the following services:
   - Authentication (Email/Password)
   - Firestore Database
   - Storage
   - Messaging
   - Analytics
3. Download configuration files:
   - `google-services.json` → `android/app/`
   - `GoogleService-Info.plist` → `ios/Runner/`

### **4. Platform Setup**

#### **iOS Setup**
```bash
cd ios
pod install
cd ..
```

#### **Android Setup**
- Ensure `google-services.json` is in `android/app/`
- Update `android/app/build.gradle` with your package name

### **5. Run the App**
```bash
# Development mode
flutter run

# iOS simulator
flutter run -d iPhone

# Android emulator
flutter run -d android

# Release mode
flutter run --release
```

---

## 🏗 **Project Structure**

```
lib/
├── app.dart                 # Main app entry point
├── main.dart               # App initialization
├── firebase_options.dart   # Firebase configuration
├── features/               # Feature modules
│   ├── auth/              # Authentication screens
│   ├── chat/              # Chat functionality
│   ├── friends/           # Friends management
│   ├── radar/             # Radar detection
│   ├── settings/          # App settings
│   └── common/            # Shared components
├── services/              # Business logic services
├── providers/             # State management
├── theme/                 # App theming
└── routing/               # Navigation configuration
```

---

## 🧪 **Testing**

### **Run Tests**
```bash
# All tests
flutter test

# Specific test file
flutter test test/widget_test.dart

# With coverage
flutter test --coverage
```

### **Test Coverage**
- Unit tests for business logic
- Widget tests for UI components
- Integration tests for user flows

---

## 📦 **Building for Production**

### **iOS Build**
```bash
# Build IPA
flutter build ipa --release

# Upload to App Store Connect
# Use Xcode or Transporter app
```

### **Android Build**
```bash
# Build APK
flutter build apk --release

# Build App Bundle (recommended)
flutter build appbundle --release

# Upload to Google Play Console
```

---

## 🔧 **Configuration**

### **Environment Variables**
Create a `.env` file in the project root:
```env
FIREBASE_API_KEY=your_api_key
GOOGLE_MAPS_API_KEY=your_maps_key
```

### **Firebase Configuration**
- Update `lib/firebase_options.dart` with your project settings
- Configure authentication providers in Firebase Console
- Set up Firestore security rules
- Configure push notification topics

---

## 🚀 **Deployment**

### **App Store (iOS)**
1. Update version in `pubspec.yaml`
2. Build release IPA
3. Upload via Xcode or Transporter
4. Submit for review in App Store Connect

### **Google Play Store (Android)**
1. Update version in `pubspec.yaml`
2. Build release AAB
3. Upload to Google Play Console
4. Submit for review

---

## 🤝 **Contributing**

We welcome contributions! Please follow these guidelines:

1. **Fork the repository**
2. **Create a feature branch**: `git checkout -b feature/amazing-feature`
3. **Commit your changes**: `git commit -m 'Add amazing feature'`
4. **Push to the branch**: `git push origin feature/amazing-feature`
5. **Open a Pull Request**

### **Development Guidelines**
- Follow Flutter/Dart style guidelines
- Write tests for new features
- Update documentation as needed
- Ensure all tests pass before submitting

**📖 For detailed development information, see [DEVELOPMENT.md](DEVELOPMENT.md)**

---

## 📄 **License**

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 📞 **Support**

- **Issues**: [GitHub Issues](https://github.com/TArslan7/ComnecterMobile/issues)
- **Discussions**: [GitHub Discussions](https://github.com/TArslan7/ComnecterMobile/discussions)
- **Email**: [Your Contact Email]

---

## 🎯 **Roadmap**

### **Upcoming Features**
- [ ] Voice messages in chat
- [ ] Group chat functionality
- [ ] Event creation and management
- [ ] Community features
- [ ] Premium subscription plans
- [ ] Advanced privacy controls
- [ ] Offline mode support

### **Performance Improvements**
- [ ] Image optimization
- [ ] Caching strategies
- [ ] Background sync
- [ ] Battery optimization

---

## 🙏 **Acknowledgments**

- **Flutter Team**: For the amazing framework
- **Firebase Team**: For comprehensive backend services
- **Open Source Community**: For various packages and libraries
- **Contributors**: Thank you to all contributors!

---

**Made with ❤️ using Flutter**

---

*Last updated: December 2024*