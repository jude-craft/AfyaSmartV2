# Afya Smart

**Afya Smart** is a comprehensive Flutter-based mobile application that provides intelligent health consultation and chat services powered by real-time communication. Built with scalable architecture and modern best practices, it delivers a seamless user experience across Android, iOS, Web, and Desktop platforms.

---

## 📋 Table of Contents

- [Features](#-features)
- [Project Overview](#-project-overview)
- [Prerequisites](#-prerequisites)
- [Installation & Setup](#-installation--setup)
- [Project Structure](#-project-structure)
- [Architecture](#-architecture)
- [Firebase Configuration](#-firebase-configuration)
- [Dependencies](#-dependencies)
- [Running the Application](#-running-the-application)
- [Development Guidelines](#-development-guidelines)
- [Contributing](#-contributing)
- [License](#-license)

---

## ✨ Features

- **Firebase Authentication** - Secure user authentication with Firebase
- **Google Sign-In** - Social authentication for quick onboarding
- **Real-time Chat** - WebSocket-based instant messaging
- **Dark Mode Support** - Complete light and dark theme implementation
- **State Management** - Provider-based reactive state management
- **Chat History** - Persistent conversation tracking
- **Responsive UI** - Optimized for all screen sizes
- **Smooth Animations** - Enhanced UX with Lottie and custom animations
- **Multi-platform Support** - Android, iOS, Web, macOS, Linux, and Windows

---

## 🎯 Project Overview

Afya Smart brings healthcare consultation to your fingertips through an intuitive chat interface. The application features:

- **Splash Screen** - App initialization and branding
- **Authentication Flow** - Secure user onboarding via Firebase & Google Sign-In
- **Dynamic Chat Interface** - Real-time messaging with session management
- **Theme Persistence** - User theme preferences saved locally
- **Robust Networking** - WebSocket integration for real-time communication

---

## 📦 Prerequisites

Before setting up the project, ensure you have the following installed:

- **Flutter SDK** (v3.10.7 or higher)
- **Android SDK** (for Android development)
- **Xcode** (for iOS development)
- **Firebase CLI** (`npm install -g firebase-tools`)
- **Git** (for version control)

### System Requirements
- **OS**: macOS, Windows, or Linux
- **RAM**: Minimum 8GB recommended
- **Disk Space**: At least 5GB free

---

## 🔧 Installation & Setup

### 1. Clone the Repository

```bash
git clone <repository-url>
cd afya_smart
```

### 2. Install Flutter Dependencies

```bash
flutter pub get
```

### 3. Configure Firebase

Ensure Firebase is properly configured by running:

```bash
flutterfire configure
```

This will update the `firebase_options.dart` file with your Firebase project credentials.

### 4. Generate Build Files (Android)

```bash
cd android
./gradlew build
cd ..
```

### 5. Run the Application

```bash
flutter run
```

For specific platforms:

```bash
# Android
flutter run -d android

# iOS
flutter run -d ios

# Web
flutter run -d chrome

# Windows
flutter run -d windows

# macOS
flutter run -d macos

# Linux
flutter run -d linux
```

---

## 📁 Project Structure

### **Lib Directory Structure**

```
lib/
├── main.dart                       # App entry point & Provider setup
├── app.dart                        # Root MaterialApp configuration
├── firebase_options.dart           # Firebase credentials (auto-generated)
│
├── core/                           # Core functionality & utilities
│   ├── constants/                  # Application constants
│   │   ├── app_colors.dart        # Color palette definitions
│   │   └── app_strings.dart       # Localized strings
│   │
│   ├── services/                   # Business logic services
│   │   ├── auth_service.dart       # Firebase authentication logic
│   │   ├── chat_service.dart       # Chat API & WebSocket service
│   │   └── storage_service.dart    # Local storage (SharedPreferences)
│   │
│   ├── theme/                      # Theme configuration
│   │   └── app_theme.dart          # Light & dark theme definitions
│   │
│   └── utils/                      # Utility functions
│       ├── validators.dart         # Input validation utilities
│       ├── date_utils.dart         # Date/time formatting
│       └── extensions.dart         # Dart extensions
│
├── models/                         # Data models
│   ├── user_model.dart             # User data class (firebaseUser, profile info)
│   ├── message_model.dart          # Chat message model
│   └── chat_session.dart           # Chat session model
│
├── providers/                      # State management (Provider)
│   ├── auth_provider.dart          # Authentication state & logic
│   ├── theme_provider.dart         # Theme switching state
│   ├── chat_provider.dart          # Chat messages state & management
│   └── history_provider.dart       # Chat history state
│
└── ui/                             # UI layer - Presentation
    ├── screens/                    # Complete screens
    │   ├── splash/
    │   │   └── splash_screen.dart          # App initialization screen
    │   │
    │   ├── auth/
    │   │   ├── auth_screen.dart            # Authentication screen
    │   │   ├── login_widget.dart           # Login UI component
    │   │   └── signup_widget.dart          # Sign-up UI component
    │   │
    │   └── chat/
    │       ├── chat_screen.dart            # Main chat interface
    │       └── message_list.dart           # Message display component
    │
    └── widgets/                    # Reusable UI components
        ├── common/
        │   ├── custom_button.dart          # Custom button component
        │   ├── custom_textfield.dart       # Custom text input
        │   ├── loading_spinner.dart        # Loading indicator
        │   └── error_widget.dart           # Error display
        │
        └── chat/
            ├── message_bubble.dart         # Chat message bubble
            └── input_field.dart            # Message input field
```

### **Directory Descriptions**

| Directory | Purpose |
|-----------|---------|
| **core/** | Contains core app functionality, services, utilities, themes, and constants |
| **core/constants/** | Centralized color, text, and app-wide constants |
| **core/services/** | Business logic layer - handles API calls, authentication, and data operations |
| **core/theme/** | Theme definitions for light and dark modes |
| **core/utils/** | Helper functions, validators, and Dart extensions |
| **models/** | Data classes representing app entities (User, Message, ChatSession) |
| **providers/** | Provider classes managing app state using the Provider package |
| **ui/screens/** | Complete full-screen widgets organized by feature (auth, chat, splash) |
| **ui/widgets/** | Reusable UI components used across multiple screens |

---

## 🏗️ Architecture

### **Architecture Pattern: MVVM + Provider**

Afya Smart follows a **Model-View-ViewModel (MVVM)** architecture combined with the **Provider** state management pattern:

```
┌─────────────────────────────────────────────────────┐
│                 UI Layer (Screens/Widgets)          │
│              (Watches Providers for state)          │
└──────────────────┬──────────────────────────────────┘
                   │
┌──────────────────▼──────────────────────────────────┐
│           Providers (State Management)              │
│  - AuthProvider      - ThemeProvider               │
│  - ChatProvider      - HistoryProvider             │
└──────────────────┬──────────────────────────────────┘
                   │
┌──────────────────▼──────────────────────────────────┐
│    Services Layer (Business Logic)                  │
│  - AuthService    - ChatService                    │
│  - StorageService                                  │
└──────────────────┬──────────────────────────────────┘
                   │
┌──────────────────▼──────────────────────────────────┐
│  Data Layer & External APIs                        │
│  - Firebase    - WebSocket    - SharedPreferences  │
└─────────────────────────────────────────────────────┘
```

### **Data Flow**

1. **UI Layer**: Screens and widgets consume state via `context.watch()`
2. **Provider Layer**: Manages state changes and notifies listeners
3. **Service Layer**: Handles business logic and API communication
4. **Data Layer**: Manages external APIs (Firebase, WebSocket) and local storage

---

## 🔑 Firebase Configuration

Afya Smart integrates with **Firebase** for:
- **Authentication** - User sign-up and login
- **Real-time Database** - Chat message storage
- **Cloud Messaging** - Push notifications (optional)

### Firebase Project Setup

1. Create a Firebase project at [Firebase Console](https://console.firebase.google.com)
2. Enable Authentication (Email/Password & Google Sign-In)
3. Configure Android and Web apps
4. Run: `flutterfire configure`

Your Firebase credentials will be automatically populated in `lib/firebase_options.dart`.

---

## 📚 Dependencies

### Core Dependencies

| Package | Version | Purpose |
|---------|---------|---------|
| `flutter` | SDK | Flutter framework |
| `firebase_core` | ^4.0.0 | Firebase initialization |
| `firebase_auth` | ^6.0.1 | Firebase authentication |
| `provider` | ^6.1.2 | State management |
| `google_sign_in` | ^6.2.1 | Google authentication |
| `http` | ^1.6.0 | HTTP requests |
| `web_socket_channel` | ^3.0.3 | WebSocket communication |

### UI Dependencies

| Package | Version | Purpose |
|---------|---------|---------|
| `flutter_svg` | ^2.0.10+1 | SVG rendering |
| `animate_do` | ^3.3.4 | Pre-built animations |
| `lottie` | ^3.1.2 | Lottie animations |
| `flutter_spinkit` | ^5.2.1 | Loading spinners |
| `cached_network_image` | ^3.3.1 | Image caching |

### Utility Dependencies

| Package | Version | Purpose |
|---------|---------|---------|
| `shared_preferences` | ^2.3.2 | Local data storage |
| `uuid` | ^4.4.2 | Unique ID generation |
| `timeago` | ^3.7.0 | Relative time formatting |
| `intl` | ^0.20.2 | Internationalization |

---

## 🚀 Running the Application

### Debug Mode
```bash
flutter run
```

### Release Mode
```bash
# Android
flutter build apk --release

# iOS
flutter build ios --release

# Web
flutter build web --release
```

### Hot Reload
```bash
# VS Code: Ctrl+S (automatic)
# Command line: Press 'r' in terminal
```

---

## 💻 Development Guidelines

### Code Style
- Follow [Dart Style Guide](https://dart.dev/guides/language/effective-dart/style)
- Use `dart analyze` for linting
- Format code with `dart format`

### Naming Conventions
- **Classes**: PascalCase (`UserModel`)
- **Functions/Variables**: camelCase (`getUserData()`)
- **Constants**: camelCase or UPPER_SNAKE_CASE (`maxRetries`, `API_KEY`)
- **Files**: snake_case (`user_model.dart`)

### Commit Messages
Follow conventional commits:
```
feat: Add user authentication
fix: Correct chat message ordering
docs: Update README
refactor: Improve theme provider
test: Add unit tests for validators
```

---

## 🤝 Contributing

1. Create a new branch: `git checkout -b feature/your-feature`
2. Make changes and commit: `git commit -m "feat: Add your feature"`
3. Push to branch: `git push origin feature/your-feature`
4. Open a Pull Request

### Before Committing
- Run `flutter pub get` to ensure dependencies are updated
- Run `dart analyze` to check for errors
- Run `dart format` to format code
- Test on multiple devices/platforms

---

## 📄 License

This project is licensed under the MIT License - see LICENSE file for details.

---

## 📞 Support

For support, please open an issue on the project repository or contact the development team.

---

## 🔗 Useful Resources

- [Flutter Documentation](https://docs.flutter.dev/)
- [Firebase Flutter Setup](https://firebase.flutter.dev/docs/overview/)
- [Provider Package](https://pub.dev/packages/provider)
- [Dart Language Guide](https://dart.dev/guides)

---

**Last Updated**: March 2026  
**Version**: 1.0.0
