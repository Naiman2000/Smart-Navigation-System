# Firebase Setup Guide

## Step 1: Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Add project" or select existing project
3. Follow the setup wizard

## Step 2: Register Android App

1. In Firebase Console, click on Android icon (or "Add app")
2. Fill in the details:
   - **Package name**: `com.example.smart_navigation_system`
   - **App nickname**: Smart Navigation System (optional)
   - **Debug signing certificate**: Leave blank for now
3. Click "Register app"
4. Download `google-services.json` file
5. Place it in `android/app/` folder

## Step 3: Get Firebase Credentials

1. In Firebase Console, go to Project Settings (gear icon)
2. Scroll down to "Your apps" section
3. Click on the Android app
4. Copy the following values:
   - `apiKey`
   - `appId` 
   - `messagingSenderId`
   - `projectId`
   - `storageBucket`

## Step 4: Update firebase_options.dart

Open `lib/firebase_options.dart` and replace the placeholder values:

```dart
static const FirebaseOptions android = FirebaseOptions(
  apiKey: 'AIza...', // Your actual API key
  appId: '1:123456789:android:abcdef', // Your actual app ID
  messagingSenderId: '123456789', // Your actual sender ID
  projectId: 'your-project-id', // Your actual project ID
  storageBucket: 'your-project-id.appspot.com', // Your actual storage bucket
);
```

## Step 5: Enable Firebase Services

In Firebase Console:

1. **Authentication**:
   - Go to Authentication → Get Started
   - Enable "Email/Password" sign-in method
   - Save

2. **Firestore Database**:
   - Go to Firestore Database → Create database
   - Choose "Start in test mode" (for development)
   - Select a location
   - Enable

## Step 6: Update Android Build Files

The `google-services.json` file has already been downloaded and should be in `android/app/`.

Make sure `android/build.gradle` includes:

```gradle
dependencies {
    classpath 'com.google.gms:google-services:4.4.0'
}
```

Make sure `android/app/build.gradle` includes at the bottom:

```gradle
apply plugin: 'com.google.gms.google-services'
```

## Step 7: Run the App

```bash
flutter clean
flutter pub get
flutter run
```

## Troubleshooting

- **"No Firebase App" error**: Make sure `google-services.json` is in `android/app/` folder
- **"API key invalid"**: Check that API key is correct in `firebase_options.dart`
- **Authentication not working**: Make sure Email/Password is enabled in Firebase Console

## Quick Test

1. Run the app
2. Try to register a new account
3. Check Firebase Console → Authentication → Users to see if user was created



