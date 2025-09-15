# Comnecter Mobile App

A Flutter-based mobile application for connecting users through proximity-based networking and social features.

## Setup Requirements

- Flutter SDK (latest stable version)
- Dart SDK (latest stable version)
- Xcode 14+ (for iOS development)
- Android Studio (for Android development)
- Firebase project with required services enabled
- Various API keys (see `.env.example` file)

## Environment Setup

### macOS Setup

1. Install Flutter and Dart:
   ```bash
   brew install flutter
   ```

2. Verify installation:
   ```bash
   flutter doctor
   ```

3. Install CocoaPods (for iOS development):
   ```bash
   sudo gem install cocoapods
   ```

4. Create a `.env` file in the project root based on `.env.example`

### iOS Setup

1. Open the iOS folder in Xcode:
   ```bash
   cd ios
   pod install
   open Runner.xcworkspace
   ```

2. Configure your development team in Xcode
3. Place `GoogleService-Info.plist` in the Runner directory
4. Ensure your iOS deployment target is set to iOS 13.0 or higher

### Android Setup

1. Open the android folder in Android Studio
2. Place `google-services.json` in the `android/app` directory
3. Ensure your `minSdkVersion` is set to 21 or higher in `android/app/build.gradle`
4. Configure your signing keys for release builds

## Running the App

### Development Mode

```bash
# Run on iOS simulator
flutter run -d iPhone

# Run on Android emulator
flutter run -d android

# Run with specific flavor
flutter run --flavor dev
```

### Production Mode

```bash
# Run in release mode
flutter run --release
```

## Testing

```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/widget_test.dart

# Run with coverage
flutter test --coverage
```

## Building for Release

### iOS

1. Update version in `pubspec.yaml`
2. Build the IPA:
   ```bash
   flutter build ipa --release
   ```
3. The IPA will be available at `build/ios/ipa/`
4. Upload to App Store Connect using Xcode or Transporter

### Android

1. Update version in `pubspec.yaml`
2. Build the APK:
   ```bash
   flutter build apk --release
   ```
   Or build the App Bundle:
   ```bash
   flutter build appbundle --release
   ```
3. The APK will be available at `build/app/outputs/flutter-apk/app-release.apk`
4. The AAB will be available at `build/app/outputs/bundle/release/app-release.aab`
5. Upload to Google Play Console

## Project Structure

- `lib/` - Main source code
  - `app.dart` - App entry point
  - `features/` - Feature modules
  - `services/` - Service classes
  - `theme/` - App theming
- `assets/` - Static assets
- `test/` - Test files

## Contributing

Please see our contribution guidelines and pull request template before submitting changes.
