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

## Helpful scripts

- `.\tool\check-setup.ps1`
  Verifies Flutter, Supabase CLI, Docker availability, and required local config files.
- `.\tool\run-dev.ps1`
  Launches the Flutter app using `dart_defines.json`.
- `.\tool\start-supabase.ps1`
  Starts the local Supabase stack if Docker Desktop is installed.
- `.\tool\deploy-hosted.ps1 -ProjectRef <your-project-ref>`
  Pushes the database, uploads secrets, and deploys the Edge Functions to a hosted Supabase project.

## Security reminders

- Never commit `dart_defines.json` or `supabase/.env.local`.
- Never place AI API keys in Flutter code.
- The client must not write `users.subscription_tier` or `usage_quotas`.
- Hive is cache only. It must not store JWTs, API keys, or media binaries.
