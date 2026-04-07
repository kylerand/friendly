# 📱 Friendly Mobile — Deployment Guide

## Prerequisites

- [Node.js](https://nodejs.org) 18+
- [EAS CLI](https://docs.expo.dev/build/setup/): `npm install -g eas-cli`
- Apple Developer account (for iOS TestFlight)
- Supabase project created with schema applied
- Railway backend deployed and running

---

## 1. Initial Setup

```bash
cd mobile
npm install

# Log in to Expo
eas login

# Link to your Expo project (first time only)
eas init
```

Copy the generated project ID into `app.json` → `expo.extra.eas.projectId`.

---

## 2. Configure Environment

### Option A: app.json extra (current setup — works for pilot)

The `app.json` already has your Supabase and Railway URLs in the `extra` block.
Expo Constants reads these at runtime. No extra config needed.

### Option B: EAS Secrets (recommended for production)

```bash
eas secret:create --name EXPO_PUBLIC_SUPABASE_URL --value "https://your-project.supabase.co"
eas secret:create --name EXPO_PUBLIC_SUPABASE_ANON_KEY --value "eyJ...your-anon-key"
eas secret:create --name EXPO_PUBLIC_API_URL --value "https://your-app.up.railway.app"
```

---

## 3. Assets

Brand assets have been copied from `design/` to `assets/`:

| File | Source | Purpose |
|------|--------|---------|
| `assets/icon.png` | `design/logo.png` | App icon (1024×1024 ideal) |
| `assets/adaptive-icon.png` | `design/logo.png` | Android adaptive icon foreground |
| `assets/splash.png` | `design/friendly app.png` | Splash screen |

> Resize if needed: icon should be 1024×1024, splash should be 1284×2778.

---

## 4. Build

### Development build (for local testing on device)

```bash
npm run build:dev
# or: eas build --profile development --platform all
```

### Pilot build (for TestFlight / internal distribution)

```bash
# iOS only
npm run build:pilot:ios

# Android only
npm run build:pilot:android

# Both platforms
npm run build:pilot
```

---

## 5. Distribute to Testers

### iOS (TestFlight)

1. After build completes:
   ```bash
   eas submit --platform ios
   ```
2. In App Store Connect → TestFlight → add pilot testers by email
3. Testers receive a TestFlight invite and install from there

### Android (Internal distribution)

1. EAS builds with `distribution: internal` produce a shareable link
2. Copy the download URL from the EAS dashboard
3. Send to testers — they open on their Android device to install

---

## 6. OTA Updates (JS-only changes)

For changes that don't touch native modules:

```bash
eas update --branch pilot --message "Fix: description of change"
```

Testers get the update automatically on next app launch.

---

## 7. Local Development

```bash
# Start Metro bundler
npm start

# With pilot env
npm run start:pilot

# Run on iOS simulator
npm run ios

# Run on Android emulator
npm run android
```

---

## Available Scripts

| Command | Description |
|---------|-------------|
| `npm start` | Start Expo dev server |
| `npm run start:pilot` | Start with pilot env |
| `npm run ios` | Run on iOS simulator |
| `npm run android` | Run on Android emulator |
| `npm run build:dev` | EAS development build (both platforms) |
| `npm run build:pilot` | EAS pilot build (both platforms) |
| `npm run build:pilot:ios` | EAS pilot build (iOS only) |
| `npm run build:pilot:android` | EAS pilot build (Android only) |

---

## Troubleshooting

| Problem | Fix |
|---------|-----|
| `Missing Supabase credentials` warning | Fill in `app.json` → `extra` or set EAS secrets |
| `expo-secure-store` crash on simulator | Use a development build, not Expo Go |
| Build fails on missing assets | Copy assets from `design/` (see step 3) |
| Auth tokens not persisting | Ensure `expo-secure-store` plugin is in `app.json` plugins |
| API calls return 401 | Verify Railway `SUPABASE_JWT_SECRET` matches your Supabase project |
| `eas init` fails | Run `eas login` first, ensure you have an Expo account |
