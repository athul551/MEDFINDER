# MedFinder - Medicine Availability Finder

A **Flutter** app for finding nearby pharmacies with medicine availability. Customers search for medicines, view stock at verified pharmacies, reserve for pickup, and get AI-powered assistance. Pharmacy owners manage inventory and reservations. Admins oversee the platform.

## Features

### Three Roles

| Role | Capabilities |
|---|---|
| **Customer** | Search medicines with fuzzy matching, view stock at nearby pharmacies, reserve medicines with pickup time & prescription upload, track reservation history, multi-medicine hunt mode with route planning, AI assistant (Jasper), rate pharmacies, dark mode |
| **Pharmacy Owner** | Dashboard with stock stats, add/edit medicines, manage reservations (approve/reject/pickup), view reviews |
| **Admin** | View/manage pharmacies, users, medicine categories, all reservations |

### Key Highlights
- Medicine search with autocomplete & Levenshtein matching
- Real-time stock availability at verified pharmacies
- Medicine Hunt Mode — enter multiple medicines, get optimized route
- Gemini AI-powered assistant for natural-language questions
- Multi-dimensional pharmacy reviews (availability, pricing, service, delivery)
- Dark/Light theme toggle (persisted)

## Tech Stack

| Layer | Technology |
|---|---|
| **Framework** | Flutter (Dart) |
| **State Management** | Provider (ChangeNotifier) |
| **Auth** | Firebase Authentication (email/password, anonymous guest) |
| **Database** | Cloud Firestore |
| **Storage** | Firebase Storage |
| **Push** | Firebase Cloud Messaging |
| **AI** | Google Generative AI (Gemini) |
| **Maps** | google_maps_flutter |
| **Location** | geolocator |
| **Theme** | shared_preferences |
| **Images** | image_picker |

## Project Structure

```
lib/
├── main.dart                     # Entry point, routing, theme, providers
├── firebase_options.dart         # Firebase config per platform
├── models/                       # Data models
│   ├── app_user.dart
│   ├── pharmacy.dart
│   ├── medicine.dart
│   ├── stock_item.dart
│   ├── reservation.dart
│   ├── pharmacy_review.dart
│   └── app_notification.dart
├── providers/                    # State management
│   ├── app_auth_provider.dart
│   ├── customer_provider.dart
│   ├── pharmacy_provider.dart
│   ├── admin_provider.dart
│   └── theme_provider.dart
├── services/                     # Firebase & business logic
│   ├── auth_service.dart
│   ├── firestore_service.dart
│   ├── storage_service.dart
│   ├── location_service.dart
│   ├── notification_service.dart
│   └── ai_assistant_service.dart
├── screens/                      # UI screens
│   ├── auth/                     # Login, register, forgot password
│   ├── customer/                 # Home, search, hunt, pharmacy list/details, reservations, reviews, AI assistant
│   ├── pharmacy/                 # Dashboard, stock management, reservations, reviews
│   ├── admin/                    # Dashboard, pharmacy verification
│   ├── profile_screen.dart       # Shared profile (all roles)
│   └── firebase_setup_screen.dart
├── utils/                        # Constants, validators, snackbars, location utils
└── widgets/                      # Reusable widgets (cards, badges, ratings, etc.)
```

## Prerequisites

- Flutter SDK >=3.3.0
- Dart SDK >=3.3.0
- A Firebase project

## Setup

### 1. Firebase Configuration

```bash
# Login to Firebase
firebase login

# Configure Firebase for this project
dart pub global activate flutterfire_cli
flutterfire configure
```

### 2. Enable Firebase Services

In Firebase Console:
- **Authentication** > Sign-in method > Enable **Email/Password**
- **Cloud Firestore** > Create database
- **Cloud Storage** > Set up
- **Cloud Messaging** (optional)

### 3. API Keys

**Gemini AI Key** (optional — falls back to rule-based responses):
```bash
flutter run --dart-define=GEMINI_API_KEY=your_key_here
```

**Google Maps Key** (required for map view on mobile):
- Android: `android/app/src/main/AndroidManifest.xml` — meta-data `com.google.android.geo.API_KEY`
- iOS: `ios/Runner/AppDelegate.swift` or `ios/Runner/Info.plist`

### 4. Deploy Security Rules

```bash
firebase deploy --only firestore:rules,firestore:indexes
firebase deploy --only storage
```

### 5. Run

```bash
flutter pub get
flutter run --dart-define=GEMINI_API_KEY=your_key_here
```

## Firestore Security Rules

- **Users**: Read/update own doc; admins can manage all
- **Pharmacies**: Create by owner with matching `ownerId`; owner/admin update; customer rating updates (limited fields only)
- **Stock**: Create/update by owning pharmacy only
- **Reservations**: Create by customer; read by customer, pharmacy, or admin; update by pharmacy/admin
- **Reviews**: Create by customers with validated ratings (1–5); duplicate checking enforced

## Firestore Collections

| Collection | Key Fields |
|---|---|
| `users` | `uid`, `name`, `email`, `phone`, `role`, `createdAt`, `profileImageUrl` |
| `pharmacies` | `pharmacyId`, `ownerId`, `name`, `address`, `phone`, `lat/lng`, `isVerified`, ratings |
| `medicines` | `medicineId`, `name`, `category`, `description` |
| `stock` | `stockId`, `pharmacyId`, `medicineId`, `medicineName`, `quantity`, `price`, `expiryDate`, `isAvailable` |
| `reservations` | `reservationId`, `userId`, `pharmacyId`, `medicineId`, `status`, `reservedAt`, `pickupTime`, `prescriptionUrl` |
| `reviews` | `reviewId`, `pharmacyId`, `userId`, multi‑dim ratings, `comment`, `createdAt` |
| `notifications` | `notificationId`, `userId`, `title`, `message`, `createdAt`, `isRead` |
