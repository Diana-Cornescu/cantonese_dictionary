# Roadmap

**Everything still ahead, in the order it's likely to happen.** Nothing that
already shipped lives here — `CHANGELOG.md` is the history, and the decision
logs hold the reasoning.

### How this file works

- **An item lives in exactly one section.** If it's in two places, one is wrong.
- **"Next up" is capped at four.** If a fifth matters more, something moves
  down. A list of twenty things is a list of nothing.
- **Nothing is numbered.** Promoting an item means moving it up a heading,
  not renumbering the file.
- **When a release ships, delete its items from here.** They're in the
  changelog.
- **New ideas go straight to Inbox, unsorted.** Triage later; don't let
  "where does this go" stop you writing it down.

**What's *true today*, rather than planned, is in `known_limitations.md`.**

---

## Next up — 1.7.0

_Draft. Move things in and out freely — that's the point of the cap._

| What | Notes |
|------|-------|
| **Writing practice (Write tab)** | **Built 2026-09-25, not yet released.** Write a character from a definition, then see it laid over the correct form from bundled open stroke data. Takes the Tags tab's slot; Tags moves into Settings. No scoring yet. Decisions: `decisions/writing-practice.md`. Before release: compile, run the tests, try it on the phone, and read the skipped list in the Write options for how much of your real dictionary is covered. |

---

## After that

Real features, not yet scheduled.

| What | Notes |
|------|-------|
| **🔥 Hard icon readable in dark mode** | **Flagged 2026-09-25: still not happy with it.** 🔥 red is only 2.4:1 on the dark background (gold 4.7, green 3.5), so the fire icons, and the red Delete outline, are hard to see in dark mode. `AppColors` meaning colors are the same in both modes by design; giving them lighter dark-mode shades means moving them into `AppColorRoles` and checking the 45° hue rule (`test/app_palettes_test.dart`) still holds. Green could get the same treatment. |
| **Button coloring consistency** | **Flagged 2026-09-25: "good enough for now", not happy yet.** The tag look for active buttons (`lib/theme/app_button_styles.dart`) covers outlined buttons, but the app still has several button styles side by side: filled (Save, Add character), outlined, text buttons (Choose, Replace), ⭐ / 🔥 flag buttons with their own greys, the filter icon, and the red / green Correct / Incorrect. Needs a pass that looks at every button together in both modes and decides which looks stay, then moves them all into `app_button_styles.dart`. See "Buttons: the tag look when active" in `decisions/ui-conventions.md`. |
| **Dark versions of Slate, Cobalt and Navy** | Light-only since dark mode shipped (1.6.0): their lighter accent is under 4:1 on the dark background (3.97, 3.6, 3.1). Needs a new, lighter dark accent picked for each; `AppPalette.darkAccent` is currently just `tertiary`. The palette test will accept one once it measures ≥4:1. |
| **Flashcard stats as boxes** | Move below the definition. A centered "last reviewed" line, then a row of boxes (Seen, Accuracy), then a row of boxes (Correct, Incorrect). |
| **Save camera photos to the phone's gallery** | A switch in Settings. **Default off** (today: photos stay only in the app). Needs a small extra package; the setting goes in the `app_settings` table. |
| **Delete several photos at once** | Select several in the gallery and delete them together. Today: filter to unlinked and delete one at a time from each photo's screen. The unlinked filter exists to find stale photos; there's no way to act on what it finds. |
| **Practice reminder notifications** | A scheduled nudge to do a flashcard round. Needs a notifications package and Android permission handling. |
| **Jyutping / romanization field** | One more field per character. Never designed. |
| **Batch import** | Add many characters at once, e.g. from a spreadsheet. Characters are one-at-a-time today. |

---

## Someday / big

Each of these is a project, not an afternoon.

| What | Notes |
|------|-------|
| **Rename to "Chinese Dictionary" — on every level** | Planned 2026-09-25, to be done **in one sitting**. Display name, internal IDs, backups, database file, folder and GitHub repo. The full plan, order and traps are written out under the table below. |
| **Tags: decide their permanent home** | Once the Write tab ships, Tags lives in Settings as a stopgap. Decide where it goes for good: folded into the Characters list (e.g. a tag filter in the filter sheet, which would also fix "no filtering by tag" in `known_limitations.md`), or somewhere else. |
| **Write tab: scoring and a tracked statistic** | Deferred from the first version on purpose (2026-09-25): use the overlay for a while first. A score per attempt, and a per-character statistic to track it over time. Tracking over time needs a new table; today the app keeps counters only (`decisions/storage.md`, decision 4). |
| **Handwriting recognition** | Fully designed and parked, 2026-07-19. The design is written out under the table below. |
| **Audio pronunciation** | Record and play back a character. Never designed. |
| **Stroke-order playback** | The data is already being captured — the handwriting model records a timestamp per point precisely so this could be added later without changing what's stored. |
| **Backup merging, or a "last backed up N days ago" nudge** | Restore replaces everything today; merging two dictionaries is a different and much harder job. |
| **Draggable divider between the character and translation windows** | Deliberately deferred until real usage showed what was worth making resizable. It still hasn't. |
| **Live database queries instead of loading everything into memory** | `DictionaryStore` still loads every character at startup and filters in Dart. Fine at personal scale. `known_limitations.md` lists the three things that would make this worth doing. |

### Handwriting recognition — the parked design

Kept here in full so picking it up doesn't mean re-deciding it. Parked
2026-07-19 as too much engineering for what it would add to a nearly-empty
dictionary.

**The idea.** With no internet and no bundled model, recognition works by
comparing a new drawing against the handwriting samples already stored for
*your own* characters. Nothing leaves the device. This fits the app's
self-building framing: a brand-new dictionary recognises almost nothing,
and accuracy grows as you add characters — entirely from your own data.

**How it would work.** Resample each stroke to a fixed number of evenly
spaced points and normalise the character to a fixed bounding box, so
drawings compare regardless of size, speed or position. Match with a
point-cloud approach in the spirit of the **$P recognizer**, which tolerates
strokes drawn in a different order or count from the stored sample — a real
concern for handwritten Chinese, where stroke order varies person to
person. The lowest-distance templates become the top-3 suggestions.

**Why it was parked.** It's a genuine algorithm to design and tune —
resampling, normalisation, distance scoring, and a sensible threshold for
"no good match". And it's least useful exactly when it's hardest to get
right: a new dictionary has nothing to compare against.

**The data-model implication, which is the easy thing to forget.** The app
stores **one** drawing per character, overwritten on every redraw, no
history. Recognition needs its own store of *one or more reference
templates* per character, separate from the single current drawing. That's
a schema change, not just a new screen.

**A refinement if revisited:** save an extra template each time a character
is redrawn correctly during recognition, so frequently-practised characters
keep getting easier to match instead of staying pinned to one original
sample.


### Rename to "Chinese Dictionary" — the plan

Written 2026-09-25 so the rename can be done in one sitting without
re-deciding anything. **Everything below goes in one release** (suggest
**2.0.0**: on Android it's effectively a new app). The name appears in
three layers; do them in this order.

**Before starting**

1. On the **phone**: Settings → Back up, save the `.zip` somewhere off the
   phone (Drive / Downloads). On the **laptop**: copy `local_data\` somewhere
   safe. Commit and push everything, so the rename is its own clean commit.
2. Close Android Studio / VS Code (an open editor has twice saved an old
   copy over a changed file).

**Layer 1 — what people see** (safe)

| Where | Change to |
|---|---|
| `android/app/src/main/AndroidManifest.xml` `android:label` | `Chinese Dictionary` (no underscore — this is the name under the icon) |
| `windows/runner/main.cpp` window title | `Chinese Dictionary` |
| `windows/runner/Runner.rc` FileDescription, InternalName, ProductName, OriginalFilename, CompanyName, LegalCopyright | `Chinese Dictionary` / `chinese_dictionary.exe` |
| `windows/CMakeLists.txt` `project(...)`, `BINARY_NAME` | `chinese_dictionary` |
| `lib/main.dart` `title:`, `dictionary_list_screen.dart` app bar | `Chinese Dictionary` |

**Layer 2 — internal IDs** (each has a trap; all of them must be handled)

| Where | Current | Trap and how to handle it |
|---|---|---|
| `pubspec.yaml` `name:` | `cantonese_dictionary_app` | Change to `chinese_dictionary_app`. **Every** `package:cantonese_dictionary_app/` import in `test/` changes with it. **And** `AppDatabase._findProjectRoot` looks for the exact string `name: cantonese_dictionary_app` to find `local_data\` — change it in the same edit, or the laptop silently opens a new, empty database under Documents. |
| `lib/data/app_database.dart` `fileName` | `cantonese_dictionary` (→ `.sqlite`) | Change to `chinese_dictionary`. On the laptop, rename `local_data\cantonese_dictionary.sqlite` to match **before** the first run. (Or add a one-time "if the old file exists and the new one doesn't, rename it" step in `databaseDirectory`, which also covers the phone if the app ID were kept.) `desktopFallbackFolderName` `Cantonese Dictionary` → `Chinese Dictionary`. |
| `lib/data/backup_service.dart` `formatName` and the suggested file name | `cantonese_dictionary_backup` | Change to `chinese_dictionary_backup`, **but keep accepting the old name on restore**, or every backup made before the rename is refused. Add a test that restores a backup with the old format name. |
| `android/app/build.gradle.kts` `namespace` and `applicationId` | `com.cantonesedictionary.cantonese_dictionary` | New ID, e.g. `com.chinesedictionary.chinese_dictionary`. **Android sees this as a different app**: it installs next to the old one with an empty dictionary. Same signing key is fine. Then: open the new app → Settings → Restore the backup from step 1 → check everything → uninstall the old app. |
| `android/app/src/main/kotlin/com/cantonesedictionary/cantonese_dictionary/MainActivity.kt` | folder + `package` line | Move to `kotlin/com/chinesedictionary/chinese_dictionary/` and update the `package` line to match the new namespace, or the build fails. |
| `lib/data/app_database.g.dart` | generated | Rerun `dart run build_runner build` after the pubspec rename. |

**Layer 3 — folder and GitHub**

1. GitHub: repo → Settings → rename to `chinese_dictionary`. The old URL
   redirects, but update the laptop anyway:
   `git remote set-url origin https://github.com/<you>/chinese_dictionary.git`
2. With every editor closed, rename the project folder to
   `chinese_dictionary`. `local_data\` and `android_release_key_private\`
   move with it (both git-ignored — check `git status` still doesn't list
   them). Rename or regenerate `cantonese_dictionary.iml`; reopen the
   project in Android Studio.
3. Docs pass: README, `CHANGELOG.md` entry, `setup_manual.md` (paths like
   `local_data\cantonese_dictionary.sqlite`), decision logs, and
   `known_limitations.md`. Keep history as history (old changelog entries
   stay as they were). The example character's "(Cantonese: oi3)" is still
   accurate — leave it.

**Check it worked**

- `flutter pub get`, `dart run build_runner build`, `flutter analyze`,
  `flutter test` all pass.
- Laptop: the app opens with **your** characters (not the example row) —
  proves `local_data` and the database file were found.
- Phone: the new app shows "Chinese Dictionary" under its icon; restore the
  backup; spot-check characters, photos, tags, settings (theme, dark mode).
- Settings → Back up makes `chinese_dictionary_backup_….zip`, and an **old**
  `cantonese_dictionary_backup_….zip` still restores.
- `grep -ri cantonese lib test android windows` finds nothing unexpected.

---

## Chores

No user-facing value. Do them when something else is blocked, or when one starts biting.

| What | Notes |
|------|-------|
| **Narrow the app-wide rebuild in `main.dart`** | `main.dart` wraps the entire `MaterialApp` in `ListenableBuilder(listenable: store)`, done for color themes (2026-09-20) so a new palette applies instantly. Side effect: **every** `notifyListeners()` — any save, any tag edit, a restore — rebuilds the whole app including the `Navigator` and its overlay. Nothing looks wrong, but a rebuild landing while a dialog is animating out is what turned one disposed `TextEditingController` into a ten-exception cascade during the tags round (see "Bugs found while testing" in `decisions_log_tags.md`). **Fix:** let `MaterialApp` listen only to the theme — a small `ValueNotifier<String>` for the palette id, or an `InheritedWidget` — and leave each screen listening to the store as they already do. **Check it worked:** Settings → Color theme still recolors instantly, a restore still repaints, every screen still updates. |
| **Watch for a `file_picker` update** | The build warns it uses the old Kotlin Gradle Plugin and that future Flutter versions will refuse to build with it. Nothing's broken today. When a newer `file_picker` supports "Built-in Kotlin": `flutter pub upgrade file_picker`. |
| **Clean up "info" lint hints** | `use_build_context_synchronously` (character detail screen), `prefer_const`. Harmless. |

---

## Inbox

Captured, not yet triaged. Move things out of here rather than answering them in place.

_Empty._
