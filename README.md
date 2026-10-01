# habits.me

A privacy-first habit tracker for Android. All data stays on your phone: no account, no analytics, no internet access for your data.

## Features
- Habits with an end date, icon and daily upvote / downvote
- Consistency score (last 30 days), current streak and longest streak
- Calendar view where you can edit any past day
- Active and inactive habits, and a date picker on the home screen
- Daily reminder notification
- Backup and restore through the system file browser, plus daily auto backup
- Theme colors

## Install
**With Obtainium (recommended, gets updates automatically)**
1. Install [Obtainium](https://github.com/ImranR98/Obtainium).
2. Tap **Add App** and paste `https://github.com/arunkrish11/habits.me`.
3. Tap **Add**, then install.

**Manually:** download the APK from the [Releases](https://github.com/arunkrish11/habits.me/releases) page.

## Tech stack
Flutter, Drift (SQLite), Riverpod, shared_preferences, flutter_local_notifications, file_picker.

## Project structure
```
lib/
├── main.dart
├── core/       # theme, stats, backup, notifications, shared widgets
├── data/       # Drift database and providers
└── features/   # dashboard, habit_detail, new_habit, settings
```

## Run it locally
Requirements: Flutter (stable channel), Android SDK, an Android phone or emulator.

```bash
git clone https://github.com/arunkrish11/habits.me.git
cd habits.me
flutter pub get
dart run build_runner build
flutter run
```
Run `dart run build_runner build` again whenever you change a Drift table.

## Build a release APK
Create your own signing key and `android/key.properties` (see `CONTRIBUTING.md`), then:
```bash
flutter build apk --release
```

## Contributing
Contributions are welcome. Please read [CONTRIBUTING.md](CONTRIBUTING.md) first.

## Privacy
The app sends no data anywhere. Backups are files you create and keep yourself.

## License
Add your license here after choosing it (see `LICENSE`).