# Contributing to habits.me

Thanks for helping! Small, focused pull requests are easiest to review.

## Report a bug or suggest a feature
Open an [issue](https://github.com/arunkrish11/habits.me/issues). For bugs, include your phone model, Android version, the app version (Settings → bottom of the page) and steps to reproduce.

## Set up
1. Fork and clone the repo.
2. Run `flutter pub get` and `dart run build_runner build`.
3. Run the app with `flutter run`.

## Before you open a pull request
- Create a branch from `main` (`fix/short-name` or `feat/short-name`).
- Run `dart format .` and `flutter analyze`. Both should be clean.
- Test on a real phone or emulator, including a `flutter run --release` check if your change touches storage, notifications or backups.
- Keep the app local-only. Changes that add accounts, tracking or network calls will not be merged.

## Changing the database
1. Edit the table in `lib/data/app_database.dart`.
2. Increase `schemaVersion` and add a migration step in `onUpgrade`, so existing users keep their data.
3. Run `dart run build_runner build`.
4. Update `lib/core/backup_service.dart` so backups include the new field and old backups still restore.

## Release builds (maintainers)
Release APKs are signed with a private key that is never committed. Contributors don't need it. To test a release build yourself, create your own key:
```bash
keytool -genkey -v -keystore my-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias habits
```
Then add `android/key.properties` (already in `.gitignore`).

## Pull request description
Say what changed and why, and add screenshots for UI changes.