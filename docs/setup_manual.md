# Setup Manual — Development Environment (Running Checklist)

This is a living checklist of everything needed to develop and run this app, kept up to date as the project grows (see the documentation convention in the root `README.md`). Windows-specific, since that's the machine this project lives on. Work through the phases in order — later phases build on earlier ones.

One important thing to know going in (this applies again to the 2026-09-19 SQLite + Drift change): the code in this project was hand-written and carefully hand-reviewed, but it was never compiled or run anywhere before reaching you — the environment used to build it has no path to installing Flutter or reaching pub.dev (see `docs/decisions_log.md`'s "Sandbox constraint" entry for the full story). That means step 7 below (`flutter pub get` + `flutter analyze` + `flutter test`) is this code's real first check, not a formality. If `flutter analyze` turns up anything, that's expected to be genuinely possible, not a sign something went wrong on your end — just paste the output back and it'll get fixed.

## Phase 1 — Core Flutter setup

1. Install Git for Windows. Not strictly required by Flutter itself, but the standard way to fetch/manage the Flutter SDK and this project's own version history.
2. Download the Flutter SDK (Windows zip, from the official Flutter site) and extract it to a permanent folder with no spaces in the path — e.g. `C:\src\flutter` (avoid `Program Files`).
3. Add `<extracted-path>\flutter\bin` to your Windows PATH environment variable.
4. Open a new terminal (so the PATH change takes effect) and run `flutter doctor`. This checks your setup and lists exactly what's still missing.
5. Enable Windows Developer Mode: Settings → Privacy & Security → For Developers → turn on Developer Mode. Flutter needs this even for Windows-desktop builds, for symlink support.

## Phase 2 — Get this project building for the first time

6. Open a terminal inside this project's folder (the one containing `pubspec.yaml`).
7. Run:
   ```
   flutter create --platforms=android,windows --org com.cantonesedictionary --project-name cantonese_dictionary .
   ```
   This is a one-time step. The environment this app was built in couldn't run the real Flutter tool, so the `android/` and `windows/` platform folders (Gradle files, app icons, the Windows CMake/runner files, etc.) don't exist yet — this command generates them for you. It's safe to run on top of the existing project: it fills in the missing platform folders without touching `lib/`, `test/`, or your `pubspec.yaml` dependencies. If it ever prompts about overwriting a file you don't recognize, it's fine to accept — just don't accept an overwrite of anything under `lib/` or `test/` (it shouldn't ask to).
8. Run `flutter pub get` to fetch dependencies (`path_provider`, `drift`, `drift_flutter`, plus the dev-only tools `drift_dev` and `build_runner`).
   - Then run `dart run build_runner build --delete-conflicting-outputs` to generate `lib/data/app_database.g.dart`. See "Database code generation" below.
9. Run `flutter analyze`. This is the code's first real compile-level check — see the note at the top of this document.
10. Run `flutter test` to run the test suite.

## Database code generation (Drift) — added 2026-09-19

The app stores its data in SQLite through Drift (see `docs/decisions_log_sqlite_drift.md`). Drift turns the table definitions in `lib/data/app_database.dart` into a generated file, `lib/data/app_database.g.dart`. This is a development-time step, like compiling. The phone never runs it.

- **When:** the first time, and again **every time a table in `app_database.dart` changes**. It isn't needed for ordinary builds.
- **Command** (from the project folder): `dart run build_runner build --delete-conflicting-outputs`
- **Commit** the generated `app_database.g.dart` to git, so a fresh clone builds without this step.
- **If `flutter pub get` can't resolve versions:** run `flutter pub add drift drift_flutter dev:drift_dev dev:build_runner`. It picks the newest versions that work together and rewrites `pubspec.yaml` to match.
- **If `flutter test` fails with something like `Failed to load dynamic library 'sqlite3.dll'`:** the tests use SQLite on your PC, not a phone. Depending on the package versions, Windows may need a copy of SQLite: download the "Precompiled Binaries for Windows" 64-bit DLL zip from sqlite.org and put `sqlite3.dll` in the project folder (it's git-ignored), or anywhere on your PATH. The app itself doesn't need this; `drift_flutter` bundles SQLite into the APK and the Windows build.
- **Where the database lives:**
  - **Windows (laptop):** inside the project, at `local_data\cantonese_dictionary.sqlite` (next to `pubspec.yaml`). The folder is git-ignored so your data never gets committed. Back it up by copying that folder. You can open the file with the free "DB Browser for SQLite"; close the app first so the two don't fight over the file.
  - If the app is run from somewhere the project folder can't be found (for example a release `.exe` copied elsewhere), it falls back to `Documents\Cantonese Dictionary\`.
  - **Android:** the app's private storage, which is deleted if the app is uninstalled. Getting data off the phone is the job of the planned backup/export feature.
- **Leftover from before:** the old JSON file (`cantonese_dictionary_entries.json`, in your Documents folder on Windows) is no longer read. It only held test data, so it's safe to delete.

## Phase 3 — Desktop build target (optional — skip straight to Phase 4 if you just want to try the app on your phone and don't need mouse-based desktop testing right now)

11. Install Visual Studio 2022: https://visualstudio.microsoft.com/downloads/ (the free Community edition is enough). During install, check the "Desktop development with C++" workload — this is the actual compiler Flutter uses to build the Windows desktop app.
12. Run `flutter config --enable-windows-desktop` once, to turn on Windows as a build target.
13. Run `flutter doctor -v` again and confirm the Windows toolchain shows a green checkmark.
14. Install an editor: VS Code (recommended, lighter-weight) with the "Flutter" and "Dart" extensions from its marketplace, or Android Studio (heavier, but doubles as your Android tooling in Phase 4) with its Flutter plugin enabled.
15. Run `flutter run -d windows` to launch the app on your desktop.

## Phase 4 — Android build target

16. Install Android Studio: https://developer.android.com/studio (the standard way to get the Android SDK, regardless of whether you use Android Studio itself as your editor). 
17. In Android Studio's SDK Manager, make sure these are installed: Android SDK Platform-Tools, Android SDK Build-Tools, and at least one Android SDK Platform (a recent API level).
- Make sure the cmdline-tools component are active: open Android Studio, go to Settings/Preferences → Languages & Frameworks → Android SDK, then click over to the SDK Tools tab (not SDK Platforms). Check the box for "Android SDK Command-line Tools (latest)" and click Apply/OK to install it. 
18. Run `flutter doctor --android-licenses` and accept the licenses.
19. Run `flutter doctor -v` again and confirm the Android toolchain shows a green checkmark.

## Phase 5 — Running on your actual phone

20. On the phone: Settings → About phone → tap "Build number" 7 times to unlock Developer Options.
21. Settings → Developer Options → enable "USB debugging."
22. Connect the phone to your PC via USB and accept the "Allow USB debugging" prompt on the phone.
23. Run `flutter devices` to confirm the phone shows up.
24. Run `flutter run`, targeting the phone, to install a debug build directly onto it.

## Phase 6 — Release build (for daily use without a dev environment attached)

To be filled in once we reach this stage — will cover generating a signing keystore, configuring release signing, and building/installing a release APK (`flutter build apk --release`) so the app runs standalone on your phone without staying tethered to a development machine.

---

This checklist will keep growing as the project needs new tools or steps (for example, anything requiring extra packages or platform-specific configuration) — kept current per the "docs travel with every change" convention in the root `README.md`.
