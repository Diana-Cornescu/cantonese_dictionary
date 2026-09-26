# Setup Manual — Development Environment (Running Checklist)

This is a living checklist of everything needed to develop and run this app, kept up to date as the project grows (see the documentation convention in the root `README.md`). Windows-specific, since that's the machine this project lives on. Work through the phases in order — later phases build on earlier ones.

One thing to know going in: code written for this project in an assistant session is **never compiled or run before it reaches you** — that environment can't install Flutter or reach pub.dev (see `docs/known_limitations.md`). So `flutter analyze` + `flutter test` on your own machine is the real first check, not a formality. If analyze turns something up, that's genuinely possible rather than a sign something went wrong on your end — paste the output back and it gets fixed.

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
8. Run `flutter pub get` to fetch dependencies (`path_provider`, `drift`, `drift_flutter`, `archive`, `file_picker`, `image_picker`, plus the dev-only tools `drift_dev` and `build_runner`).
   - Then run `dart run build_runner build` to generate `lib/data/app_database.g.dart`. See "Database code generation" below.
9. Run `flutter analyze`. This is the code's first real compile-level check — see the note at the top of this document.
10. Run `flutter test` to run the test suite.

## Database code generation (Drift) — added 2026-09-19

The app stores its data in SQLite through Drift (see `docs/decisions_log_sqlite_drift.md`). Drift turns the table definitions in `lib/data/app_database.dart` into a generated file, `lib/data/app_database.g.dart`. This is a development-time step, like compiling. The phone never runs it.

- **When:** the first time, and again **every time a table in `app_database.dart` changes**. It isn't needed for ordinary builds.
- **Command** (from the project folder): `dart run build_runner build`
- **Commit** the generated `app_database.g.dart` to git, so a fresh clone builds without this step.
- **If `flutter pub get` can't resolve versions:** run `flutter pub add drift drift_flutter archive file_picker image_picker dev:drift_dev dev:build_runner`. It picks the newest versions that work together and rewrites `pubspec.yaml` to match.
- **If `flutter test` fails with something like `Failed to load dynamic library 'sqlite3.dll'`:** the tests use SQLite on your PC, not a phone. Depending on the package versions, Windows may need a copy of SQLite: download the "Precompiled Binaries for Windows" 64-bit DLL zip from sqlite.org and put `sqlite3.dll` in the project folder (it's git-ignored), or anywhere on your PATH. The app itself doesn't need this; `drift_flutter` bundles SQLite into the APK and the Windows build.
- **Where the database lives:**
  - **Windows (laptop):** inside the project, at `local_data\cantonese_dictionary.sqlite` (next to `pubspec.yaml`). The folder is git-ignored so your data never gets committed. Back it up by copying that folder. You can open the file with the free "DB Browser for SQLite"; close the app first so the two don't fight over the file.
  - If the app is run from somewhere the project folder can't be found (for example a release `.exe` copied elsewhere), it falls back to `Documents\Cantonese Dictionary\`.
  - **Android:** the app's private storage, which is deleted if the app is uninstalled. Get data off the phone with Settings → Back up.
- **Leftover from before:** the old JSON file (`cantonese_dictionary_entries.json`, in your Documents folder on Windows) is no longer read. It only held test data, so it's safe to delete.

## Stroke data for the Write tab — added 2026-09-25

`assets/stroke_reference.bin` is committed, so ordinary builds need nothing. It's only rebuilt if the source data or its file layout changes; the steps are at the end of `docs/decisions/writing-practice.md` (needs Python 3). The APK is about 8.5 MB bigger because of it.

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

## Reset: wipe test data (added 2026-09-19)

Use this whenever you want the app to start completely empty again. Afterwards it opens fresh, with only the example character 愛.

### Windows (laptop)

All of the laptop app's data lives in **one folder**: `local_data\` in the project, next to `pubspec.yaml`.

| Inside `local_data\` | What it is |
|---|---|
| `cantonese_dictionary.sqlite` | the database (all characters, tags, stats, drawings) |
| `photos\` | character photos (none yet) |
| `safety_backups\` | automatic copies made before each Restore |
| `backups\` | where the Back up window starts. **Keep anything here you want to keep** |

1. **Close the app completely**, including stopping `flutter run` in the terminal (press `q`). Windows won't delete a database that's still open.
2. **Keep anything you want?** Move it out of `local_data\backups\` first.
3. **Delete the folder.** Either delete `local_data` in File Explorer, or in PowerShell from the project folder:
   ```
   Remove-Item -Recurse -Force local_data
   ```
4. Start the app (`flutter run -d windows`). It creates a new, empty `local_data` with just the example character.

This never touches the code, git, or the `android_release_key_private` folder. `local_data` is git-ignored, so git doesn't notice.

### Android (phone)

- **Easiest:** uninstall the app, then install it again.
- **Without reinstalling:** phone Settings → Apps → Cantonese Dictionary → Storage → **Clear storage**.
- Either way, **all data on the phone is gone**. Back up first (Settings → Back up) if any of it matters.

## Phase 6 — Release build on your phone (added 2026-09-19)

A release build runs on its own, with no laptop, cable or debug banner, and it's faster. It's installed locally over USB, not through the Play Store.

### 6a. One-time: create your release signing key

Android only installs an update over an existing app if both are signed with the **same key**. Your key lives in the **`android_release_key_private`** folder at the project root. It's **git-ignored** because the repo is public, and the name is meant to remind you of both facts.

1. In the project folder (PowerShell): `mkdir android_release_key_private`
2. Find `keytool.exe`. It's in the `jbr\bin\` folder of Android Studio. `flutter doctor -v` shows a line like `Java binary at: ...\jbr\bin\java`. That `java` is the Java program itself, so `keytool.exe` sits **next to it** in the same `bin` folder. On this laptop that's `C:\Users\Personal\app_making\android_studio\jbr\bin\keytool.exe`.
3. Run this as one line. The **`&`** at the start is needed in PowerShell to run a program whose path is in quotes:
   ```
   & "C:\Users\Personal\app_making\android_studio\jbr\bin\keytool.exe" -genkey -v -keystore android_release_key_private\release.jks -keyalg RSA -keysize 2048 -validity 10000 -alias release
   ```
   It asks for a password (write it down) and some name fields (anything is fine).
4. Create `android_release_key_private\key.properties` containing (use your password):
   ```
   storeFile=release.jks
   storePassword=YOUR_PASSWORD
   keyAlias=release
   keyPassword=YOUR_PASSWORD
   ```
5. Check git ignores it: `git status` must **not** list `android_release_key_private/`.
6. **Back up the `android_release_key_private` folder somewhere private** (a password manager, or a private cloud folder). It isn't in GitHub, so if the laptop dies this copy is the only one.
   - If the key is ever lost, you can recover: in the app, Settings → Back up; then uninstall; install with a new key; Settings → Restore.

If `android_release_key_private/key.properties` is missing, the build prints a WARNING and signs with the debug key instead.

### 6b. One-time: switch the phone from the debug app to the release app

The app on your phone now is signed with Flutter's debug key, so the release version can't install over it. You have to go through one uninstall:

1. `flutter run` to the phone (debug) so it has the new Settings screen, then **Settings → Back up** and save to Downloads or Google Drive.
2. Uninstall the app on the phone.
3. Build and install the release (6c below).
4. Open the app → **Settings → Restore** → pick the backup.

After this, future releases install over the top and keep your data.

### 6c. Every release: build, install, record

1. **Bump the version** in `pubspec.yaml`, e.g. `1.0.0` → `1.1.0`. Use MAJOR.MINOR.PATCH only, never `+N`:
   - **PATCH** (1.0.**1**) for bug fixes.
   - **MINOR** (1.**1**.0) for new features.
   - **MAJOR** (**2**.0.0) for big changes.
   - The version must always go **up**. Android's internal build number is calculated from it automatically (`1.2.3` → `10203`, in `android/app/build.gradle.kts`), so a lower version won't install over a higher one. Keep MINOR and PATCH below 100.
2. **Write what changed** at the top of `CHANGELOG.md`.
3. **Test:** `flutter analyze` and `flutter test`.
4. **Build:** `flutter build apk --release`. The file is `build\app\outputs\flutter-apk\app-release.apk`.
   - ⚠️ **Check the output does NOT say `WARNING: ... key.properties not found`.** If it does, the APK is signed with the debug key and won't update your phone's app properly. Fix the key folder before installing.
5. **Install:** phone plugged in, `flutter install --release`. It installs over the existing app and keeps the data. (Or copy the `.apk` to the phone and open it; Android asks to allow installing from that source.)
6. **Record it in git:**
   ```
   git add -A
   git commit -m "Release 1.1.0"
   git tag -a v1.1.0 -m "What changed in one line"
   git push
   git push origin v1.1.0
   ```
   The tag marks exactly which code is on your phone.
   - ⚠️ **`git push --tags` on its own is not enough** — it pushes tags and
     *not* your commits, so GitHub ends up with a tag pointing at a commit
     it doesn't have. Push the commits first, then the tag. (`git push
     --follow-tags` does both in one go, for annotated tags only.)
   - `-a` makes an **annotated** tag, which stores who made it, when, and a
     message. `git tag v1.1.0` alone makes a lightweight tag — just a
     pointer, no metadata. Use `-a` for anything you release.

---

This checklist will keep growing as the project needs new tools or steps (for example, anything requiring extra packages or platform-specific configuration) — kept current per the "docs travel with every change" convention in the root `README.md`.
