# App Store submission checklist

## Before first upload

1. **Bundle ID** — verify `PRODUCT_BUNDLE_IDENTIFIER` in
   `ios/Runner.xcodeproj/project.pbxproj` matches the one registered at
   developer.apple.com. Default Flutter value (`com.example.smartstyle`) must
   be replaced before a real upload.
2. **Signing** — open `ios/Runner.xcworkspace` → Runner target → Signing &
   Capabilities → pick your team, let Xcode manage provisioning.
3. **Version** — `pubspec.yaml` `version: 1.0.0+1`. Bump the `+N` build number
   on every upload (TestFlight rejects duplicates).
4. **Privacy manifest** — `ios/Runner/PrivacyInfo.xcprivacy` is already
   included. Add it to the Xcode Runner target via drag-and-drop if it
   doesn't appear under Build Phases → Copy Bundle Resources.
5. **Icons** — drop `assets/branding/app_icon.png` (1024×1024) and run
   `flutter pub run flutter_launcher_icons`. See `assets/branding/README.md`.
6. **Launch screen** — drop `assets/branding/splash_logo.png` and run
   `flutter pub run flutter_native_splash:create`.

## App Store Connect privacy labels

Mirror these from `PrivacyInfo.xcprivacy` when filling out the App Privacy
questionnaire in App Store Connect:

| Category | Data | Linked | Tracking | Purpose |
|----------|------|--------|----------|---------|
| Contact Info | Email | Yes | No | App functionality (auth) |
| User Content | Photos or Videos | Yes | No | App functionality (wardrobe images) |
| Location | Coarse | No | No | App functionality (weather lookup) |
| Diagnostics | Crash data | No | No | App functionality |
| Diagnostics | Performance data | No | No | Analytics (product improvement) |

Data NOT collected: Health/fitness, financial info, contacts, search history,
browsing history, sensitive info, user ID beyond auth email, device ID,
advertising identifiers.

Calendar is **read on-device only** — never transmitted. Do not declare it as
"data collected."

## Archive + upload

```bash
flutter build ipa --release
# Then:
# open build/ios/archive/Runner.xcarchive via Xcode Organizer → Distribute App
```
