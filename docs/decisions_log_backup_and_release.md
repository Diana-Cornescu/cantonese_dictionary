# Decisions Log — Backup & Restore, and First Release Build

**Started:** 2026-09-19
**Status:** ✅ Done. **1.0.0 released to the phone 2026-09-19.**

This file is separate from the other decision logs on purpose, so these decisions are easy to find. Add a new dated section whenever a decision here changes.

---

## TL;DR

- **Settings screen** (gear icon on the home screen) with **Back up**, **Restore** and **Undo last restore**. More settings go here later.
- **A backup is one `.zip`** containing the database, a `photos/` folder, and an info file (versions, date, counts).
- **The system Save / Open window is used every time**, with no default folder. On Android you can pick Downloads, Google Drive, etc.
- **Restore replaces everything**, after automatically saving a safety copy of the current data.
- **Manual only**, nothing automatic.
- **The readable JSON export was removed.**
- **Release builds are signed with your own key.** The key and passwords live in a local, **git-ignored** `android_release_key_private/` folder, because the repo is public.
- **Versioning:** plain `MAJOR.MINOR.PATCH` in `pubspec.yaml` (first release **1.0.0**, never `+N`), a `CHANGELOG.md`, and a git tag per release.

---

## Decisions

| # | Topic | Decision | Why |
|---|-------|----------|-----|
| 1 | What's in a backup | **One `.zip`**: `database.sqlite` + `photos/` + `backup_info.json`. | One file to move around. Ready for photos later. The info file lets restore refuse wrong or too-new files. |
| 2 | Readable JSON export | **Removed** (button, code and test). | Backups cover the real need (new phone, surviving an uninstall). A second export format was just more to maintain. |
| 3 | Where backups are saved | **System "Save as" / "Open" window every time.** No default folder. On Windows it opens in `local_data\backups\`. | The app's own storage is deleted on uninstall, so backups have to go outside it. The picker needs no permissions, remembers the last folder, and offers Google Drive. A fixed default folder on Android would need a less-maintained plugin and a folder permission that can expire. |
| 4 | Restore behaviour | **Replace everything**, after a confirmation. An **automatic safety copy** is saved first (newest 5 kept), plus an **"Undo last restore"** button. | Merging two datasets (duplicates, conflicting edits) is complicated and error-prone. The safety copy makes a wrong restore harmless. |
| 5 | Where the buttons live | **⚙️ Settings screen** from the home screen. | Room for future settings. Replaces the old export icon. |
| 6 | Automatic backups | **None, manual only.** | Your choice. A "last backed up X days ago" reminder could come later. |
| 7 | Signing key location | **Local `android_release_key_private/` folder, git-ignored.** Not in GitHub. | The repo is **public**: a committed key plus passwords would let anyone sign APKs as you, and git history can't be cleaned afterwards. Keeping it local still keeps it in the project folder. **Back up the folder privately.** |

### Thought process on the signing key
- You wanted everything in one place. The honest risk for a personal, sideloaded app is small, and **losing** the key is the bigger practical danger.
- The deciding factor was that the **repo is public**. For a private repo, committing it would have been fine.
- Losing the key is no longer a disaster: back up in the app, uninstall, reinstall with a new key, restore.

---

## How it works (implementation, 2026-09-19)

- `lib/data/backup_service.dart` (new):
  - **Back up:** SQLite's `VACUUM INTO` makes a clean copy of the live database, which is zipped with the photos and the info file.
  - **Restore:** it first checks the file: is it our format, is it from a newer app version (then it refuses, "update the app first"), and does the database look like a real SQLite file. Only then does it save the safety copy, close the database, swap in the new file (written to a temp name, then renamed), restore the photos, and reopen and reload.
  - Photo names inside a zip are checked so a bad file can't write outside the photos folder.
- `DictionaryStore.replaceDatabase()` (new) closes, swaps and reopens the database, and the screens refresh by themselves. `main.dart` passes `reopen: AppDatabase.new`.
- `AppDatabase`: new `currentSchemaVersion`, `databaseFile()`, `photosDirectory()`, `safetyBackupsDirectory()`, `copyTo()`. Photo rows now store a **file name only**, not a full path, so they still work after restoring on another device.
- `lib/features/settings/settings_screen.dart` (new). The home screen's export icon became a gear icon.
- **Removed:** `lib/features/export/export_service.dart` and `test/export_service_test.dart`.
- **New packages:** `archive` (zip) and `file_picker` (Save/Open window).
- **Tests:** `test/backup_service_test.dart` covers backup → change → restore bringing the old data back, undo restore, rejecting a non-backup file without changing anything, and rejecting a backup from a newer version.

### Where things are stored
| | Windows (laptop) | Android |
|---|---|---|
| Database | `local_data\cantonese_dictionary.sqlite` | app-private storage |
| Photos | `local_data\photos\` | app-private storage |
| Safety copies | `local_data\safety_backups\` | app-private storage (deleted on uninstall, but they're only there to undo a restore) |
| Your backups | wherever you choose (the Save window starts in `local_data\backups\`) | wherever you choose (Downloads, Drive, …) |

## Release & versioning

- `android/app/build.gradle.kts` reads `android_release_key_private/key.properties`. If it's missing, it prints a WARNING and uses the debug key.
- Version is **`1.0.0`**, the first release. `CHANGELOG.md` was added.
- **The first switch needs one uninstall** (debug key → your key): back up, uninstall, install the release, restore.
- The full steps are in `docs/setup_manual.md`, Phase 6.

---

## 2026-09-19 — Change: version numbers without "+N"

- **Decision:** the first release is **1.0.0** (not 0.2.0+2). Versions are always plain `MAJOR.MINOR.PATCH` and never get a `+N` build number.
- **Why:** it's cleaner and easier to read. 1.0.0 fits a first release.
- **How Android still gets an increasing build number:** `android/app/build.gradle.kts` calculates it from the version, `MAJOR*10000 + MINOR*100 + PATCH` (1.0.0 → 10000, 1.2.3 → 10203). So a higher version always installs as an update. The one rule is to keep MINOR and PATCH below 100; the build stops with a clear error otherwise.
- **Cleanup:** the empty `lib/features/export/` folder can be deleted along with its file.

---

## 2026-09-19 — Verified on the laptop ✅

- `flutter pub get`, `flutter analyze` and `flutter test` (including the 4 backup tests) pass. Back up, Restore and Undo work on Windows.
- The `lib/features/export/` folder and the export test were deleted.
- Next: `setup_manual.md` Phase 6 (signing key → switch the phone to the release app → release 1.0.0).

---

## 2026-09-19 — Change: key folder renamed

- **Decision:** the key folder is now **`android_release_key_private/`** (it was `signing/`).
- **Why:** "signing" alone didn't say what the folder is or that it must stay private. The new name says both.
- Also fixed in the setup manual: in PowerShell, a quoted program path needs `&` in front of it, and `keytool.exe` sits directly in `jbr\bin\` (`flutter doctor` shows `jbr\bin\java`, which is the Java program, not a folder).

---

## 2026-09-19 — Released 1.0.0 ✅

- The signing key was created in `android_release_key_private/` (git-ignored, backed up privately).
- Phone test data was wiped by uninstalling, so no backup/restore was needed for the switch.
- `flutter build apk --release` and `flutter install --release` worked. There's no debug banner, and the app runs without the laptop.
- Back up and Restore work on Android through the system Save/Open window.
- Tagged `v1.0.0` in git.
- Also added the "Reset: wipe test data" checklist to `setup_manual.md`.

---

## 2026-09-20 — Fix: release builds were using the debug key

- **What happened:** the key-folder rename (`signing/` → `android_release_key_private/`) reached `.gitignore` and the docs, but **not** `android/app/build.gradle.kts`. That file still looked in `signing/`, didn't find the key, and fell back to the debug key. This showed up as a WARNING while building 1.1.0. **So 1.0.0 on the phone is almost certainly debug-signed too.**
- **Fix:** `build.gradle.kts` now reads `android_release_key_private/key.properties`.
- **Consequence:** the first properly signed install needs the one-time switch again (Settings → Back up, uninstall, install, Restore). After that, updates install over the top as intended.
- **Lesson:** after a release build, check that the WARNING about the key is **not** printed. That check is now part of setup_manual Phase 6c.
