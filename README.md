# Medicine Availability Finder

A Flutter + Firebase mobile app for finding nearby pharmacies where a medicine is available.

## What is included

- Firebase Authentication with customer, pharmacy owner, and admin roles
- Cloud Firestore models/services for users, pharmacies, medicines, stock, reservations, and notifications
- Firebase Cloud Messaging initialization
- Firebase Storage prescription upload support
- Geolocator-based customer location lookup
- Google Maps pharmacy detail view
- Provider state management
- Role-based navigation and dashboards
- Firestore and Storage security rules

## Setup

1. Install dependencies:

   ```bash
   flutter pub get
   ```

2. Connect Firebase:

   ```bash
   dart pub global activate flutterfire_cli
   flutterfire configure
   ```

   Replace `lib/firebase_options.dart` with the generated values.

3. Enable Firebase products in the Firebase console:

   - Authentication: Email/password
   - Authentication: Anonymous
   - Cloud Firestore
   - Cloud Storage
   - Cloud Messaging

4. Deploy rules:

   ```bash
   firebase deploy --only firestore:rules,storage
   ```

5. Add Google Maps API keys for Android/iOS according to the `google_maps_flutter` package setup.

6. Run the app:

   ```bash
   flutter run
   ```

## Admin account

Create an admin user in Firebase Authentication, then create a matching document in `users`:

```json
{
  "uid": "AUTH_UID",
  "name": "Admin",
  "email": "admin@example.com",
  "phone": "",
  "role": "admin",
  "createdAt": "Firestore server timestamp"
}
```
