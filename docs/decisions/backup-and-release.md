# Backup & restore, and how releases work

**Decided 2026-09-19.** 1.0.0 released to the phone the same day.

How to actually do any of this is in **`setup_manual.md`** (Phase 6). This
file is only the decisions and why they were taken.

---

## Backup

| # | Decision | Why |
|---|----------|-----|
| 1 | **A backup is one `.zip`**: `database.sqlite` + `photos/` + `backup_info.json`. | One file to move around. The info file (versions, date, counts) lets restore refuse a wrong or too-new file instead of corrupting your data. |
| 2 | **The readable JSON export was removed.** | Backups cover the real need — a new phone, surviving an uninstall. A second export format was only more to maintain. |
| 3 | **The system Save / Open window every time, with no default folder.** | The app's own storage is deleted on uninstall, so backups *have* to leave it. The picker needs no permissions, remembers the last folder, and offers Google Drive. A fixed Android folder would need a less-maintained plugin and a folder permission that can expire. |
| 4 | **Restore replaces everything**, after a confirmation, with an automatic safety copy first (newest 5 kept) and an **Undo last restore** button. | Merging two datasets — duplicates, conflicting edits — is a genuinely hard problem and was not worth solving for one person with two devices. The safety copy makes a wrong restore harmless, which is what actually matters. |
| 5 | **Manual only, never automatic.** | Your call. A "last backed up N days ago" nudge is in the roadmap. |

---

## The signing key

**Decision: the key and its passwords live in a local, git-ignored
`android_release_key_private/` folder.**

The deciding factor was that **this repo is public**. A committed key plus
passwords would let anyone sign APKs as you, and git history can't be
cleaned afterwards. For a private repo, committing it would have been fine.

Against that: you wanted everything in one place, and for a personal
sideloaded app the realistic risk is small — **losing** the key is the
bigger practical danger, because Android only installs an update over an
app signed with the same key.

That danger is survivable, which is why local-but-git-ignored won: back up
in the app → uninstall → reinstall signed with a new key → restore. You
lose nothing but the app's install identity.

**So: back that folder up somewhere private.** It isn't in GitHub, so if
the laptop dies it's the only copy.

---

## Versioning

**Decision: plain `MAJOR.MINOR.PATCH` in `pubspec.yaml`, never Flutter's
`+N` build suffix.** One number to reason about instead of two that can
disagree.

**The consequence worth knowing:** Android still needs an integer
`versionCode` that only ever increases, so
`android/app/build.gradle.kts` derives one from the version name as
`MAJOR*10000 + MINOR*100 + PATCH` (`1.2.3` → `10203`).

**That arithmetic is why MINOR and PATCH must stay below 100.** At `1.100.0`
the code would be `20000` — colliding with `2.0.0`, and nothing after it
would install as an update. The build fails with a clear error rather than
letting it happen, but the rule is here because the reason isn't obvious
from reading the formula.

Each release also gets a `CHANGELOG.md` entry and an annotated git tag.

---

## 2026-09-20 — Release builds were silently using the debug key

The Gradle config fell back to the debug key when
`android_release_key_private/key.properties` was missing, and said so only
in a line of build output that's easy to scroll past. A release APK signed
that way won't install over the real app.

It still falls back — failing the build outright would be worse when you
just want `flutter run --release` — but the warning is now loud, and
checking for it is a step in the release checklist.
