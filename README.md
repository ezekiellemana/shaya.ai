# Shaya AI

Shaya AI is a production-minded Flutter app built from the Shaya AI SRS v4.0. The client talks only to Supabase, while AI generation, quota enforcement, and purchase verification live in Supabase Edge Functions.

## Current foundation

- Flutter app structure aligned to the SRS
- Dark Afrofuturist design system foundation
- Riverpod + go_router app shell with persistent mini-player
- Secure Supabase session storage using `flutter_secure_storage`
- Encrypted Hive cache for non-secret metadata only
- Supabase schema migration and Edge Function scaffolding

## Recommended setup path

If you are new to Supabase, start with a hosted Supabase project first. Local Supabase development is also supported, but it requires Docker Desktop.

Read the step-by-step beginner guide in `docs/01-environment-setup.md`.

## Quick start

1. Copy `dart_defines.example.json` to `dart_defines.json`.
2. Copy `supabase/.env.example` to `supabase/.env.local`.
3. Fill both files with your real project values and secrets.
4. Run `.\tool\check-setup.ps1`.
5. Run `.\tool\run-dev.ps1`.

Keep `SHAYA_ENABLE_GOOGLE_AUTH` set to `"false"` until the Google provider is configured in Supabase. The login screen will only show the Google button when that flag is enabled.
For the current Supabase OAuth flow, you do not need `google-services.json` or `GoogleService-Info.plist`.

## Helpful scripts

- `.\tool\check-setup.ps1`
  Verifies Flutter, Supabase CLI, Docker availability, and required local config files.
- `.\tool\run-dev.ps1`
  Launches the Flutter app using `dart_defines.json`.
- `.\tool\start-supabase.ps1`
  Starts the local Supabase stack if Docker Desktop is installed.
- `.\tool\deploy-hosted.ps1 -ProjectRef <your-project-ref>`
  Pushes the database, uploads secrets, and deploys the Edge Functions to a hosted Supabase project.
- `.\tool\check-release-readiness.ps1`
  Verifies package IDs, adaptive icons, privacy strings, signing scaffolding, and release-build readiness.
- `.\tool\bootstrap-android-signing.ps1`
  Generates a local Android upload keystore plus `android/key.properties` for release builds.
- `.\tool\backup-android-signing.ps1`
  Copies your Android signing files into a backup folder outside the repo and records a non-secret backup marker.
- `.\tool\restore-android-signing.ps1`
  Restores the Android signing files from a previous backup onto a new machine.

## Android release prep

- Copy `android/key.properties.example` to `android/key.properties` when you are ready to sign release builds.
- Or use `.\tool\bootstrap-android-signing.ps1` to generate both files locally.
- After generating them, run `.\tool\backup-android-signing.ps1` so you do not lose your release key when you switch machines.
- Put your upload keystore inside `android/` and point `storeFile` at it.
- If `android/key.properties` is missing, release builds still fall back to the debug key so local smoke tests keep working.
- When your real keystore is in place, `flutter build apk --release --dart-define-from-file=dart_defines.json` will use it automatically.

For the full repo-specific checklist, read `docs/02-release-prep.md`.
For the Mac-only iOS handoff, read `docs/03-ios-signing-handoff.md`.

## Security reminders

- Never commit `dart_defines.json` or `supabase/.env.local`.
- Never place AI API keys in Flutter code.
- The client must not write `users.subscription_tier` or `usage_quotas`.
- Hive is cache only. It must not store JWTs, API keys, or media binaries.
