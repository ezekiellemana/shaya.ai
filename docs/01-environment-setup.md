# Shaya AI Environment Setup

This guide gets you from "fresh clone" to "app can run" in the safest order for a beginner.

## 1. What you need installed

- Flutter 3.41 or newer
- Android Studio for Android builds
- Xcode for iOS builds on macOS
- Supabase CLI
- Docker Desktop if you want to run Supabase locally

## 2. Choose your setup path

### Path A: Hosted Supabase (recommended for beginners)

Choose this first if you want the simplest route. You create a project on supabase.com and point the Flutter app at it.

### Path B: Local Supabase with Docker

Choose this if you want a full local backend on your own machine. This needs Docker Desktop and uses the `supabase start` workflow.

## 3. Create your local config files

From the project root, copy the example files:

```powershell
Copy-Item dart_defines.example.json dart_defines.json
Copy-Item supabase/.env.example supabase/.env.local
```

Then edit them.

### `dart_defines.json`

These values are used by the Flutter app:

- `SHAYA_SUPABASE_URL`
- `SHAYA_SUPABASE_ANON_KEY`
- `SHAYA_OAUTH_REDIRECT_URL`
- `SHAYA_PASSWORD_RESET_REDIRECT_URL`

Use these redirect values unless you intentionally change the app deep links:

- `shayaai://auth-callback`
- `shayaai://auth-callback/reset`

### `supabase/.env.local`

These values are used by Supabase Edge Functions:

- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`
- `SUPABASE_SERVICE_ROLE_KEY`
- `ANTHROPIC_API_KEY`
- `ANTHROPIC_MODEL`
- `UDIO_API_KEY`
- `KLING_API_KEY`
- `APPLE_SHARED_SECRET`
- `GOOGLE_PLAY_ACCESS_TOKEN`

You can leave provider secrets blank until you are ready to test those specific features, but music, lyrics, video, and purchase verification will not work until they are filled.

## 4. Hosted Supabase setup

### 4.1 Create the project

1. Create a new Supabase project in the dashboard.
2. Copy the project URL and anon key into `dart_defines.json`.
3. Copy the project URL, anon key, and service role key into `supabase/.env.local`.

### 4.2 Configure Auth redirect URLs

In Supabase Dashboard:

1. Open `Authentication -> URL Configuration`.
2. Add these redirect URLs:
   - `shayaai://auth-callback`
   - `shayaai://auth-callback/reset`
3. Keep email confirmations enabled for production-style testing.

### 4.3 Link this repo to the hosted project

```powershell
supabase login
supabase link --project-ref your-project-ref
```

Replace `your-project-ref` with the short ref from your Supabase project URL.

### 4.4 Push the database schema

```powershell
supabase db push
```

This applies the Shaya AI schema, policies, triggers, and quota helpers.

### 4.5 Upload Edge Function secrets and deploy functions

Use the helper script:

```powershell
.\tool\deploy-hosted.ps1 -ProjectRef your-project-ref
```

That script will:

- push the database
- upload secrets from `supabase/.env.local`
- deploy `generate-music`
- deploy `generate-video`
- deploy `generate-lyrics`
- deploy `verify-purchase`

## 5. Local Supabase setup

This path only works after Docker Desktop is installed and running.

### 5.1 Start the local stack

```powershell
.\tool\start-supabase.ps1
```

### 5.2 Reset and seed the local database

```powershell
supabase db reset
```

### 5.3 Serve Edge Functions locally

```powershell
supabase functions serve --env-file supabase/.env.local
```

### 5.4 Use local Supabase values in `dart_defines.json`

When the local stack is running, the usual defaults are:

- `SHAYA_SUPABASE_URL`: `http://127.0.0.1:54321`
- `SHAYA_SUPABASE_ANON_KEY`: shown by `supabase status`

## 6. Check your setup before running

```powershell
.\tool\check-setup.ps1
```

If the script shows warnings, fix those first before trying to run the app.

## 7. Run the Flutter app

```powershell
.\tool\run-dev.ps1
```

This script reads `dart_defines.json` and starts the app with the correct Dart defines.

## 8. Common beginner mistakes

- Using the service role key in Flutter instead of the anon key
- Forgetting to create `dart_defines.json`
- Forgetting to create `supabase/.env.local`
- Testing Google sign-in before configuring the provider in Supabase
- Trying to use local Supabase without Docker Desktop
- Committing secret files to Git

## 9. What to do next

After setup is working, the next recommended step is live verification of:

- database policies
- auth flows
- Edge Function payloads
- Android and iOS smoke tests
