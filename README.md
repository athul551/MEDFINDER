# MedFinder

MedFinder is a Flutter application that helps customers find medicines at nearby pharmacies. Customers can search medicine stock, reserve medicines, upload prescriptions, and ask Jasper, the built-in AI assistant, for help. Pharmacy owners manage their inventory and reservations, while administrators manage the platform.

## Features

### Customers

- Search medicines with fuzzy matching and autocomplete.
- View available stock at verified pharmacies.
- Find pharmacies near the customer's location.
- Reserve medicines for pickup.
- Upload a prescription when making a reservation.
- Track reservation history and receive notifications.
- Use Medicine Hunt mode to search for multiple medicines and plan a route.
- Ask Jasper questions about medicines, availability, and pharmacies.
- Automatically save Jasper chat history per signed-in user.
- Review pharmacies with ratings for availability, pricing, service, and delivery.
- Switch between light and dark themes.

### Pharmacy owners

- Manage pharmacy medicine stock, prices, quantities, and expiry dates.
- View inventory statistics.
- Approve or reject reservations.
- Mark reservations as picked up.
- View customer reviews.

### Administrators

- Manage users and pharmacies.
- Verify pharmacies.
- Manage medicines and categories.
- View and manage platform reservations.

## Technology

- **Flutter / Dart** - Cross-platform application
- **Provider** - Application state management
- **Firebase Authentication** - Email/password and anonymous guest sign-in
- **Cloud Firestore** - Users, medicines, pharmacies, stock, reservations, reviews, notifications, and private AI chat history
- **Firebase Storage** - Prescription and profile image uploads
- **Firebase Cloud Messaging** - Push notifications
- **Groq API** - Jasper AI assistant
- **Google Maps** - Pharmacy locations and route planning
- **Geolocator** - Device location
- **Shared Preferences** - Local theme preferences

## Requirements

- Flutter SDK 3.3.0 or later
- Dart SDK 3.3.0 or later
- A Firebase project
- Android Studio or Xcode for mobile builds
- A Google Maps API key for map features
- A Groq API key for Jasper

## Installation

Clone the repository and install the Flutter dependencies:

```bash
git clone https://github.com/athul551/MEDFINDER.git
cd MEDFINDER
flutter pub get
```

## Firebase setup

1. Create or select a Firebase project.
2. Install and authenticate with the Firebase CLI:

   ```bash
   npm install -g firebase-tools
   firebase login
   ```

3. Install the FlutterFire CLI and configure the supported platforms:

   ```bash
   dart pub global activate flutterfire_cli
   flutterfire configure
   ```

4. Enable these Firebase services in the Firebase Console:

   - Authentication: Email/Password
   - Cloud Firestore
   - Cloud Storage
   - Cloud Messaging (optional)

5. Deploy the Firestore and Storage rules and indexes:

   ```bash
   firebase deploy --only firestore:rules,firestore:indexes,storage
   ```

The Firestore rules protect user-owned data. Jasper messages are stored under each user's document and can only be read or written by that authenticated user.

## Environment configuration

Create a `.env` file in the project root:

```env
GROQ_API_KEY=your_groq_api_key
GROQ_MODEL=openai/gpt-oss-120b
```

Do not commit `.env` or API keys to GitHub. Alternatively, provide the Groq key at runtime:

```bash
flutter run --dart-define=GROQ_API_KEY=your_groq_api_key
```

## Google Maps configuration

Add a Google Maps API key to the platform-specific configuration:

- **Android:** `android/app/src/main/AndroidManifest.xml`
- **iOS:** `ios/Runner/AppDelegate.swift` or the iOS project configuration

Enable the required Maps SDKs and billing settings in Google Cloud Console.

## Running the app

```bash
flutter run
```

For a specific platform:

```bash
flutter run -d chrome
flutter run -d android
flutter run -d ios
```

## Cloud Functions

The `functions/` directory contains Firebase Cloud Functions used by the project. To install dependencies and deploy them:

```bash
cd functions
npm install
npm run deploy
```

## Project structure

```text
lib/
├── main.dart
├── firebase_options.dart
├── models/       # Firestore and application data models
├── providers/    # Provider state management
├── screens/      # Authentication, customer, pharmacy, and admin screens
├── services/     # Authentication, Firestore, storage, location, and AI services
├── utils/        # Constants, validators, and helper functions
└── widgets/      # Reusable UI components

functions/        # Firebase Cloud Functions
firestore.rules   # Firestore security rules
storage.rules     # Firebase Storage security rules
```

## Testing and analysis

Run the available checks with:

```bash
flutter analyze
flutter test
```

## Security

- Keep Firebase and Groq credentials out of source control.
- Use the provided Firestore and Storage rules in deployed environments.
- Review Firebase Authentication, Firestore, Storage, Maps, and Groq usage limits before production deployment.

## License

This project does not currently include a license file. Add a license before distributing or reusing the project publicly.
