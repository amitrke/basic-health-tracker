# Releasing to testers

`.github/workflows/release.yml` builds a signed Android App Bundle and uploads
it to the Play **internal testing** track, and builds a signed IPA and uploads
it to **TestFlight**. It is adapted from the relay-player workflow of the same
name, so the setup below mirrors that repo's.

## How a release is triggered

- **Push to `develop`**: the everyday test channel. Builds are named after
  `pubspec.yaml`'s version, e.g. `1.0.0 (12)`.
- **Tag `v<version>`**: marks the build that shipped. The tag must match
  `pubspec.yaml`. After a tag exists, bump `pubspec.yaml` before the next
  round of test builds.
- **Run workflow** manually from the Actions tab, optionally to one store only.

The build number is `github.run_number`, so Play's `versionCode` and iOS's
`CFBundleVersion` agree. Do not rename or recreate `release.yml` once builds
have been uploaded: the count would restart at 1 and both stores would reject
the builds.

Repository variable `RELEASE_ANDROID` or `RELEASE_IOS` set to `false` switches
that store off. With none of the secrets below set, the workflow still runs: it
builds the AAB (kept as an artifact) and compiles iOS without signing.

## One-time setup

Identifiers for both stores: `com.subnext.wellbite`, Apple team `BTSKP77HML`.

### Android (Play internal testing)

1. **Create an upload key** (keep it out of git; `*.jks` is ignored):

   ```bash
   keytool -genkeypair -v -keystore upload-keystore.jks -alias upload \
     -keyalg RSA -keysize 2048 -validity 10000
   ```

   Back the keystore and its passwords up somewhere safe. If it is lost, Play
   Console can reset the upload key, but only through support.
2. **Repository secrets** (Settings → Secrets and variables → Actions):
   - `ANDROID_UPLOAD_KEYSTORE_BASE64`: `base64 -w0 upload-keystore.jks`
   - `ANDROID_UPLOAD_KEYSTORE_PASSWORD`
   - `ANDROID_UPLOAD_KEY_PASSWORD`

   Repository **variable** `ANDROID_UPLOAD_KEY_ALIAS` = `upload`. It is a
   variable because GitHub masks a secret's value everywhere in the logs, and a
   secret alias of "upload" turns every log line containing that word into `***`.
3. **Service account for CI.** A Google Cloud service account with the Play
   Android Developer API enabled, invited in Play Console → Users and
   permissions with release rights **for this app** (access is granted per
   app: the first run failed with "The caller does not have permission" until
   that was done). The relay-player service account can be reused. Store its
   JSON key as secret `PLAY_SERVICE_ACCOUNT_JSON`.
4. **First release needs no manual upload.** With the secrets above, a manual
   run (`platforms: android`, `status: draft`) created the app's first release
   as a draft on the Internal testing track (verified 2026-10-09, build
   `1.0.0 (2)`). An earlier version of this document said Play's API cannot do
   that; that was carried over from relay-player's notes and did not hold
   here. The upload by hand is only a fallback: the `android-aab-N` artifact
   is kept for it.
5. **Finish in Play Console.** A draft release does nothing until someone
   rolls it out: Testing → Internal testing → Testers (create a list and add
   Gmail addresses), then Edit release → Save → Roll out. Play App Signing is
   opted into at that point.
6. **Status for later runs.** Manual runs default to `status: draft`, which
   leaves each build in Play Console to roll out by hand. `completed` rolls out
   to internal testers at once. relay-player found that Play refuses anything
   but draft while the app itself is still a draft; this repo has not yet tried
   `completed` before a first rollout, and pushes to `develop` have no inputs,
   so they use `completed`. Roll out the first release by hand (step 5) before
   relying on those.

### iOS (TestFlight)

1. **App Store Connect API key.** The key is team-wide, so the relay-player key
   works here too (it needs the **Admin** role for cloud-managed signing).
   Apple lets you download a `.p8` only once; if you no longer have it, create
   a new key under Users and Access → Integrations.
   - Secret `APP_STORE_CONNECT_API_KEY_P8`: the full contents of the `.p8`
   - Variables `APP_STORE_CONNECT_API_KEY_ID` and `APP_STORE_CONNECT_ISSUER_ID`
2. **First build needs no manual upload.** The CI upload alone delivered the
   first build to App Store Connect (verified 2026-10-09, run 4). Add internal
   testers in App Store Connect → TestFlight once the build finishes processing.
   The Xcode project must have `DEVELOPMENT_TEAM` set on the Runner target
   (`BTSKP77HML`): without it `flutter build ios --config-only` fails with "No
   valid code signing certificates were found", which failed the first run.
3. Signing is automatic and cloud-managed: no `.p12` or provisioning profile is
   stored. The archive is unsigned on purpose; signing happens at export.
   A signed archive would mint a new development certificate on every run.
4. TestFlight needs the app's export-compliance answer; set
   `ITSAppUsesNonExemptEncryption` to `false` in `ios/Runner/Info.plist` if the
   app uses no custom encryption, so builds do not wait on that question.

## Release notes

Play's "what's new" comes from
`fastlane/metadata/android/en-US/changelogs/v<version>.txt` (or `<build>.txt`),
at most 500 characters. A run without notes still uploads, with a warning.

## Health data (Apple Health, Health Connect)

The app reads calories burned, weight and height, read-only. Both stores
treat this as sensitive data, so before the first release that includes it:

- **Apple:** the HealthKit capability must be enabled for `com.subnext.wellbite`
  in the Apple Developer portal (Identifiers). The entitlement is already in
  `ios/Runner/Runner.entitlements`. In App Store Connect, answer the App Privacy
  questions for Health data (collected on device only, not linked or shared),
  and have a privacy policy URL.
- **Google Play:** complete the Health apps declaration and the Health Connect
  permissions declaration in Play Console (App content). Declare the four
  `READ_*` permissions in `AndroidManifest.xml`: active calories, total
  calories, weight and height. A privacy policy URL is required, and it must
  say the data is read on device and not sent anywhere.
- Health Connect only releases data from the last 30 days before the user
  granted access, so older weight or height records may not appear.
