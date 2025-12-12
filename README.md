# Smart Navigation System

A Flutter-based mobile application that provides indoor navigation for grocery shopping using Bluetooth Low Energy (BLE) beacons. The system helps users navigate through stores efficiently by calculating optimal routes based on their shopping lists and providing real-time positioning using beacon trilateration.

## 📱 Features

### Core Features
- **User Authentication** - Secure login and registration using Firebase Authentication
- **Shopping List Management** - Create, edit, and manage shopping lists with real-time synchronization
- **Indoor Navigation** - Real-time positioning using BLE beacon trilateration
- **Route Optimization** - Calculates optimal shopping routes using Nearest Neighbor algorithm
- **Store Map Visualization** - Interactive map showing user position, product locations, and navigation routes
- **Product Location Tracking** - Products mapped to specific store locations (aisle, section, shelf)
- **Turn-by-Turn Directions** - Step-by-step navigation guidance through the store

### Additional Features
- **User Profile Management** - Edit profile, notification preferences, and privacy settings
- **Help & Support** - User assistance and documentation
- **Real-time Synchronization** - Shopping lists sync across devices via Firebase
- **Responsive UI** - Material Design with custom theme and reusable components

## 🛠️ Technology Stack

### Framework & Language
- **Flutter** 3.8.1+ (Dart SDK)
- Cross-platform mobile development (Android & iOS)

### Backend Services
- **Firebase Core** - Backend infrastructure
- **Firebase Authentication** - User authentication (Email/Password)
- **Cloud Firestore** - NoSQL database for data storage

### Bluetooth & Positioning
- **flutter_blue_plus** - Bluetooth Low Energy (BLE) beacon scanning
- **Trilateration Algorithm** - Indoor positioning using RSSI-based distance calculation
- **Route Optimization** - Nearest Neighbor algorithm for pathfinding

### State Management & UI
- **Provider** - State management
- **Material Design** - UI components
- **flutter_svg** - SVG image support
- **shared_preferences** - Local data persistence
- **flutter_secure_storage** - Secure credential storage

### Development Tools
- **flutter_lints** - Code quality and linting
- **flutter_native_splash** - Splash screen generation
- **flutter_launcher_icons** - App icon generation

## 📁 Project Structure

```
lib/
├── main.dart                          # App entry point and route configuration
├── firebase_options.dart              # Firebase configuration
├── models/                            # Data models
│   ├── user_model.dart                # User data model
│   ├── product_model.dart             # Product with location data
│   ├── shopping_list_model.dart       # Shopping list and items
│   └── store_layout_model.dart        # Store layout structure
├── screens/                           # UI screens
│   ├── login_screen.dart              # User login
│   ├── register_screen.dart           # User registration
│   ├── home_screen.dart                # Main home screen
│   ├── main_navigation_screen.dart    # Bottom navigation container
│   ├── shopping_list_screen.dart      # Shopping list management
│   ├── add_list_screen.dart           # Create/edit shopping list
│   ├── map_screen.dart                # Store map and navigation
│   ├── profile_screen.dart             # User profile
│   ├── edit_profile_screen.dart       # Edit user profile
│   ├── notification_preferences_screen.dart
│   ├── privacy_security_screen.dart
│   └── help_support_screen.dart
├── services/                          # Business logic services
│   ├── firebase_service.dart          # Firebase operations
│   ├── beacon_service.dart            # BLE beacon scanning
│   ├── navigation_service.dart        # Positioning and routing
│   └── credentials_service.dart       # Credential management
├── widgets/                           # Reusable UI components
│   ├── custom_button.dart             # Custom button widget
│   ├── input_field.dart               # Form input field
│   ├── list_tile.dart                 # List item widget
│   ├── app_logo.dart                  # App logo widget
│   ├── product_search_field.dart      # Product search widget
│   └── store_map_widget.dart          # Store map visualization
├── theme/                             # App theming
│   └── app_theme.dart                 # Theme configuration
└── data/                              # Static data
    └── store_layout_config.dart       # Store layout configuration
```

## 🚀 Getting Started

### Prerequisites
- Flutter SDK 3.8.1 or higher
- Dart SDK
- Android Studio / Xcode (for mobile development)
- Firebase account
- Physical device with Bluetooth support (for beacon testing)

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd Smart-Navigation-System
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure Firebase**
   - Follow the instructions in [FIREBASE_SETUP.md](FIREBASE_SETUP.md)
   - Run `flutterfire configure` or manually update `lib/firebase_options.dart`
   - Download `google-services.json` for Android and place in `android/app/`
   - Download `GoogleService-Info.plist` for iOS and place in `ios/Runner/`

4. **Configure app icons and splash screen**
   ```bash
   flutter pub run flutter_launcher_icons
   flutter pub run flutter_native_splash:create
   ```

5. **Run the app**
   ```bash
   flutter run
   ```

## 📋 Setup Instructions

### Firebase Configuration

1. Create a Firebase project at [Firebase Console](https://console.firebase.google.com/)
2. Enable Authentication (Email/Password method)
3. Create Firestore database (start in test mode for development)
4. Configure Android/iOS apps in Firebase Console
5. Download configuration files and update `firebase_options.dart`

See [FIREBASE_SETUP.md](FIREBASE_SETUP.md) for detailed instructions.

### Bluetooth Permissions

#### Android
Add to `android/app/src/main/AndroidManifest.xml`:
```xml
<uses-permission android:name="android.permission.BLUETOOTH" />
<uses-permission android:name="android.permission.BLUETOOTH_ADMIN" />
<uses-permission android:name="android.permission.BLUETOOTH_SCAN" />
<uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
```

#### iOS
Add to `ios/Runner/Info.plist`:
```xml
<key>NSBluetoothAlwaysUsageDescription</key>
<string>This app needs Bluetooth to detect beacons for indoor navigation</string>
<key>NSLocationWhenInUseUsageDescription</key>
<string>This app needs location to provide navigation services</string>
```

## 🔧 Key Services

### BeaconService
- Scans for BLE beacons in the environment
- Calculates distance using RSSI (Received Signal Strength Indicator)
- Implements signal smoothing for accurate readings
- Filters beacons by proximity and signal strength

### NavigationService
- **Trilateration** - Calculates user position using 3+ beacon distances
- **Route Optimization** - Finds optimal path through shopping list items
- **Direction Generation** - Creates turn-by-turn navigation instructions
- **Position Validation** - Ensures calculated positions are within store bounds

### FirebaseService
- User authentication (sign up, sign in, sign out)
- Shopping list CRUD operations
- Product queries and search
- User profile management
- Real-time data synchronization

## 📊 Current Implementation Status

**Overall Progress: ~85%**

### ✅ Completed
- Data models (User, Product, ShoppingList, StoreLayout)
- Core services (Firebase, Beacon, Navigation)
- Reusable UI widgets
- Screen navigation and routing
- Firebase integration structure
- Documentation and diagrams

### 🔄 In Progress
- Screen enhancements with full Firebase integration
- Map screen with beacon visualization
- Shopping list real-time sync

### 📝 Planned
- Unit and integration tests
- Offline mode support
- Product barcode scanning
- Push notifications
- Multiple store support

See [docs/IMPLEMENTATION_STATUS.md](docs/IMPLEMENTATION_STATUS.md) for detailed status.

## 📚 Documentation

- [Firebase Setup Guide](FIREBASE_SETUP.md) - Firebase configuration instructions
- [Implementation Status](docs/IMPLEMENTATION_STATUS.md) - Current development progress
- [System Architecture](docs/diagrams/System-Architecture.png) - System architecture diagram
- [Navigation Flow](docs/diagrams/Navigation-Flow.png) - Screen navigation flow
- [Beacon Trilateration](docs/diagrams/Beacon-Trilateration.png) - Positioning algorithm
- [Chapter 4: System Implementation](docs/report/Chapter-4-System-Implementation.md) - Detailed implementation documentation

## 🧪 Testing

Run tests with:
```bash
flutter test
```

## 📦 Dependencies

Key dependencies (see `pubspec.yaml` for complete list):
- `flutter_blue_plus: ^2.0.0` - Bluetooth Low Energy
- `firebase_core: ^4.1.1` - Firebase SDK
- `cloud_firestore: ^6.0.2` - Firestore database
- `firebase_auth: ^6.1.0` - Authentication
- `provider: ^6.1.5+1` - State management
- `flutter_svg: ^2.2.1` - SVG support
- `shared_preferences: ^2.3.3` - Local storage
- `flutter_secure_storage: ^9.2.2` - Secure storage
- `url_launcher: ^6.3.1` - URL launching

## 🎯 Usage

1. **Register/Login** - Create an account or sign in
2. **Create Shopping List** - Add items to your shopping list
3. **Start Navigation** - Open the map screen to begin navigation
4. **Follow Directions** - The app will guide you through the store
5. **Check Off Items** - Mark items as found while shopping

## 🤝 Contributing

This is a Final Year Project (FYP) implementation. For questions or contributions, please refer to the project documentation.

## 📄 License

See [LICENSE](LICENSE) file for details.

## 👤 Author

Final Year Project - Smart Navigation System

## 🙏 Acknowledgments

- Flutter team for the excellent framework
- Firebase for backend services
- flutter_blue_plus contributors for BLE support
- Material Design for UI guidelines

---

**Note**: This application requires physical BLE beacons deployed in the store environment for indoor navigation to function properly.
