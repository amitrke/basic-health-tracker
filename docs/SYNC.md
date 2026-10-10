# Syncing between devices

Settings → Sync keeps the food log, saved foods, meal templates and weigh-ins
the same on every device signed in to the same account. Goals, units and AI keys
are per device and are not synced.

## How it works

Each synced row has a UUID and an `updated_at` stamp (kept current by SQLite
triggers, so no code path can forget). Deletes leave a tombstone. A sync
downloads one JSON file, merges it into the local database (newest row wins; a
delete beats an older edit), and uploads the result if it changed. It runs a few
seconds after a change, on launch and when the app returns to the foreground.

The file is `wellbite-sync.json`. Code: `lib/sync/`.

| Platform | Where the file lives | Status |
|---|---|---|
| Android | Google Drive hidden app folder (`drive.appdata` scope) | Built; needs the Google setup below |
| iOS / iPadOS | iCloud container | Not built yet |

If two devices both held data before sync was first turned on, the second one to
sync pairs rows with the same food, meal and time, so nothing doubles.

## Android setup (one time)

1. Google Cloud Console → create a project → enable the **Google Drive API**.
2. OAuth consent screen: External, add the `.../auth/drive.appdata` scope, add
   yourself as a test user (or publish the app).
3. Credentials → create an **Android** OAuth client: package
   `com.subnext.wellbite` and the SHA-1 of the signing key. Debug builds use the
   debug keystore SHA-1 (`keytool -list -v -keystore ~/.android/debug.keystore`);
   Play builds need the Play App Signing SHA-1 too.
4. Credentials → create a **Web application** OAuth client. Its client id is
   the server client id.
5. Build with it:

```bash
flutter run --dart-define=GOOGLE_SERVER_CLIENT_ID=<web-client-id>.apps.googleusercontent.com
```

Without the define, the Sync row in Settings is disabled with an explanation.
