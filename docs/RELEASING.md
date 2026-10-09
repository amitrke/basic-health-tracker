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
3. **First upload by hand.** Play's API cannot create an app's first release.
   Run the workflow once, download the `android-aab-N` artifact, and upload it
   to Internal testing in Play Console (opt in to Play App Signing). Add
   testers under Testing → Internal testing → Testers.
4. **Service account for CI.** A Google Cloud service account with the Play
   Android Developer API enabled, invited in Play Console → Users and
   permissions with release rights **for this app**. The relay-player service
   account can be reused: grant it access to this app too. Store its JSON key
   as secret `PLAY_SERVICE_ACCOUNT_JSON`.
5. While the Play app is still a draft, run with `status: draft`
   (the default for manual runs here); Play rejects other statuses until the
   app has had a first release.

### iOS (TestFlight)

1. **App Store Connect API key.** The key is team-wide, so the relay-player key
   works here too (it needs the **Admin** role for cloud-managed signing).
   Apple lets you download a `.p8` only once; if you no longer have it, create
   a new key under Users and Access → Integrations.
   - Secret `APP_STORE_CONNECT_API_KEY_P8`: the full contents of the `.p8`
   - Variables `APP_STORE_CONNECT_API_KEY_ID` and `APP_STORE_CONNECT_ISSUER_ID`
2. **First build.** Upload the first build so the app's TestFlight page exists
   (the CI upload can also do this once the key is set). Add internal testers in
   App Store Connect → TestFlight.
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
