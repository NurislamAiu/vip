# VIP Client Manager

A premium, real-time CRM for a medical clinic's VIP concierge team, built with
Flutter + Firebase. Managers work simultaneously and see every change live.

## Highlights

- **Email/password auth** with role-based access (Administrator / Manager).
- **Live clients dashboard** — search, quick filters, status colors, pagination.
- **Full client CRUD** with a block-by-block detail view. Deletes are
  administrator-only, enforced both in the UI and in Firestore rules.
- **Staff management** for administrators (create / edit / disable / remove).
- **Real-time sync** via Firestore streams — no manual refresh anywhere.
- **Offline-first** — Firestore local cache is on; edits reconcile on reconnect.
- **Push notifications** via FCM (new client, client updated, arrival in ~2h,
  appointment in ~30m, departure today) driven by Cloud Functions.
- **Material 3**, light + dark themes, Inter typography, fully responsive.

No Firebase Storage is used — all data lives in Cloud Firestore.

## Architecture

Clean-ish layering with the Repository pattern and Riverpod:

```
lib/
  app/            App shell + auth gate (routing)
  core/           constants, theme, utils (formatters, validators)
  models/         AppUser, Client, enums (roles, status, filters)
  repositories/   Auth / User / Client — the only code that talks to Firebase
  services/       NotificationService (FCM + local notifications)
  providers/      Riverpod providers (repositories, auth, clients, users)
  screens/        auth, dashboard, client (form/detail), managers, splash
  widgets/        reusable UI (client card, status badge, section card, …)
  main.dart
```

Each entity has a Model → Repository → Provider → UI chain.

## Firebase setup (required before first run)

1. Create a Firebase project and enable **Authentication → Email/Password** and
   **Cloud Firestore**.
2. Install the CLI and configure the app (this generates `lib/firebase_options.dart`
   and the native config files, replacing the committed placeholders):
   ```bash
   dart pub global activate flutterfire_cli
   flutterfire configure
   ```
   This drops `android/app/google-services.json` and
   `ios/Runner/GoogleService-Info.plist` into place.
3. Deploy the security rules:
   ```bash
   firebase deploy --only firestore:rules
   ```
4. Deploy the notification functions (optional but needed for reminders):
   ```bash
   cd functions && npm install && cd ..
   firebase deploy --only functions
   ```
5. **Create the first administrator** (bootstrap — rules require an existing
   admin to create staff):
   - In Authentication, add a user with an email + password.
   - In Firestore, create `users/{that-uid}` with:
     ```json
     {
       "name": "Admin",
       "phone": "+10000000000",
       "email": "admin@example.com",
       "role": "administrator",
       "isActive": true
     }
     ```

## Run

```bash
flutter pub get
flutter run
```

## Notes & limitations

- **Creating staff** uses a temporary secondary Firebase app so the admin's
  session isn't disrupted when the new Auth account is created.
- **Removing staff** deletes the Firestore profile (which blocks sign-in). The
  underlying Auth account must be deleted from the Firebase console, since the
  client SDK cannot delete other users.
- Search and quick filters run in-memory over the streamed page for instant
  results; the Firestore query itself is paginated with a growing `limit`.

## Tests

```bash
flutter test
```

Covers status/role round-tripping, distinct status colors, and the
search + filter logic.
