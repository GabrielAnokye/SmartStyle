# Branding assets

Drop the following files here before running the icon/splash generators:

| File | Size | Notes |
|------|------|-------|
| `app_icon.png` | 1024×1024 | Square, opaque, RGB (no alpha on iOS). Used by `flutter_launcher_icons`. |
| `splash_logo.png` | 1152×1152 | Transparent PNG, centered on a square canvas. Used by `flutter_native_splash`. |

## Generate

```bash
flutter pub get
flutter pub run flutter_launcher_icons
flutter pub run flutter_native_splash:create
```

Both generators rewrite iOS assets in place; commit the resulting files under
`ios/Runner/Assets.xcassets/` and `ios/Runner/Base.lproj/`.

## Colors

The seed color in `lib/main.dart` is `#2B4A6B`. Keep `background_color_ios` and
`flutter_native_splash.color` in `pubspec.yaml` in sync with any brand change.
