# Shaya AI iOS Signing Handoff

Use this guide when you move the repo to a Mac for the final iOS release pass.

## 1. What is already ready in this repo

- bundle ID is set to `com.shayaai.app`
- app display name is `Shaya AI`
- app icons and launch screen branding are already wired
- the Flutter version is `1.0.0+1`
- `NSPhotoLibraryUsageDescription` is already present for avatar picking

## 2. Open the iOS workspace

From the project root on a Mac:

```bash
open ios/Runner.xcworkspace
```

Use the workspace, not the `.xcodeproj`, so CocoaPods and Flutter dependencies load correctly.

## 3. Attach your Apple Developer team

In Xcode:

1. Select the `Runner` project in the left sidebar.
2. Select the `Runner` target.
3. Open the `Signing & Capabilities` tab.
4. Choose your Apple Developer team.
5. Keep the bundle identifier as `com.shayaai.app` unless you intentionally change your production ID.

If Xcode says the bundle ID is already in use, pick the production identifier you actually control and then mirror that same change everywhere before submission.

## 4. Confirm the release metadata

In the `General` tab for the `Runner` target, confirm:

- Display Name: `Shaya AI`
- Version: `1.0.0`
- Build: `1`

These values should already come from Flutter, but this is the last sanity check before archiving.

## 5. Verify privacy and deep-link settings

In `Runner/Info.plist`, confirm:

- `NSPhotoLibraryUsageDescription`
- `CFBundleURLSchemes` includes `shayaai`

That covers avatar picking and the mobile auth callback flow.

## 6. Install CocoaPods if needed

From the project root:

```bash
cd ios
pod install
cd ..
```

## 7. Build once on a simulator

In Xcode:

1. Choose an iPhone simulator.
2. Press `Run`.
3. Confirm the app launches.
4. Confirm login still works.
5. Confirm avatar selection still requests photo access properly.

## 8. Archive the app

In Xcode:

1. Choose `Any iOS Device (arm64)` or a connected physical device.
2. Open `Product -> Archive`.
3. Wait for Organizer to open.

## 9. Validate and distribute

Inside Organizer:

1. Select the new archive.
2. Click `Validate App`.
3. Fix any signing or metadata issues it reports.
4. Click `Distribute App`.
5. Choose `App Store Connect`.

## 10. Common issues to watch for

- wrong Apple team selected
- bundle ID mismatch
- missing provisioning profile
- opening the `.xcodeproj` instead of `.xcworkspace`
- trying to archive before `pod install`
- forgetting to test the `shayaai://auth-callback` URL handling after signing changes

## 11. Recommended final smoke test on the Mac build

- install the signed build on a simulator or test device
- create or log into a real account
- open `Home`, `Library`, `Create`, and `Profile`
- change the avatar photo once
- confirm logout still works

If all of that passes, the iOS handoff should be ready for App Store Connect submission.
