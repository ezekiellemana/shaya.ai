# Shaya AI Release Prep

This guide helps you move from "the app runs locally" to "the app is ready for store-facing release work."

## 1. Run the release check first

From the project root:

```powershell
.\tool\check-release-readiness.ps1
```

That script tells you which repo-side release blockers are already fixed and which ones still need action.

## 2. App version

Before public submission, update the version in [pubspec.yaml](/d:/PROJECTS/Shaya%20ai/pubspec.yaml).

Current format in this repo:

```yaml
version: 1.0.0+1
```

Meaning:

- `0.1.0` is the user-facing version name
- `1` is the build number

Example for a first public beta:

```yaml
version: 1.0.0+1
```

Example for the next build:

```yaml
version: 1.0.0+2
```

## 3. Create the Android upload keystore

Fastest repo-supported path:

```powershell
.\tool\bootstrap-android-signing.ps1
```

That creates:

- `android/upload-keystore.jks`
- `android/key.properties`

Both files are already gitignored.

If you prefer to create the keystore manually, use:

Run this from the project root:

```powershell
keytool -genkeypair -v -keystore android/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

Store the passwords somewhere safe. Losing them later is painful.

## 4. Create `android/key.properties`

If you used `.\tool\bootstrap-android-signing.ps1`, this file already exists.

Copy the example file:

```powershell
Copy-Item android/key.properties.example android/key.properties
```

Then fill it in:

```properties
storePassword=your_store_password
keyPassword=your_key_password
keyAlias=upload
storeFile=upload-keystore.jks
```

The Gradle config is already set up to use this automatically when it exists.

## 5. Build Android release artifacts

```powershell
flutter build apk --release --dart-define-from-file=dart_defines.json
```

If you want the app bundle later:

```powershell
flutter build appbundle --release --dart-define-from-file=dart_defines.json
```

## 6. Android release checklist

- `com.shayaai.app` package ID is already set
- adaptive launcher icons are already in place
- Shaya AI launch branding is already in place
- add your real keystore before store submission
- confirm the version in `pubspec.yaml`
- if you used the bootstrap script, back up the generated keystore and `android/key.properties` somewhere safe before changing machines

## 7. iOS release checklist

These steps still need a Mac:

- open `ios/Runner.xcworkspace` in Xcode
- attach your Apple Developer team
- verify bundle ID `com.shayaai.app`
- verify the Shaya AI app icons and launch screen
- verify `NSPhotoLibraryUsageDescription` in `Info.plist`
- archive and validate the build

## 8. What is already handled in this repo

- Android package name
- iOS bundle ID
- launcher/app display name
- adaptive Android icons
- branded launch visuals
- Android signing scaffold
- release readiness checker

## 9. What still needs real account setup

- Apple signing and archive validation
- Play Console / App Store Connect submission
- real subscription products
- real Google Sign-In provider files if you enable that path fully on iOS
