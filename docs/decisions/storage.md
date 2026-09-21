# Decisions Log — SQLite + Drift Backend Migration

**Started:** 2026-09-19
**Status:** ✅ Done and verified 2026-09-19. Build, analyze, tests and manual testing all pass. Export/backup (#7) postponed.

This file is kept separate from `decisions_log.md` on purpose, so the database migration decisions are easy to find. Add a new dated section whenever a decision here changes.

---

## TL;DR

- We're replacing the single JSON file with **SQLite** (a small database engine bundled inside the app) and **Drift** (a Dart library that generates type-checked code for reading and writing SQLite tables).
- Everything stays **fully offline and on the device**. On Android the database is one file in the app's private storage, which other apps can't see. Windows works the same way.
- **Only `lib/data/` gets rewritten.** Screens keep talking to `DictionaryStore`, so the UI doesn't change.
- We're **starting fresh**, because the existing JSON data is fake test data.
- New tables for **tags** and **photos** get created now, even though the UI for them comes later, so a future schema migration isn't needed just to add them.

---

## Background: how this works on Android

1. The APK ships its own copy of SQLite through the `drift_flutter` package (which handles the native library).
2. On first launch the app creates the database file in its private app folder. Uninstalling the app deletes it, which is why backup/export matters later (see open item 7).
3. Each change updates only the rows it touches. The JSON approach rewrote the whole file on every change.
4. Future changes to the tables are handled by Drift's **schema version number + migration steps**, so saved data survives app updates.

## Why code generation happens on the laptop (question 0)

- Drift reads the table definitions and **writes Dart code for you** (a `*.g.dart` file) using a tool called `build_runner`.
- That's a **development-time step, like compiling**. It isn't something the app does while running. The phone never runs it; the phone only runs the finished APK, and the APK is built on the laptop anyway (`flutter build apk`).
- It's only needed **when the tables change**, not on every build. The generated file is committed to git, so a fresh clone works without regenerating.
- This isn't leftover logic from the old sandbox problem. It's how Drift is designed. The alternative without code generation is `sqflite` (raw SQL strings, no type checking). We rejected it because Drift catches mistakes at compile time and has built-in migrations.
- Command: `dart run build_runner build` (to be added to `setup_manual.md`).

---

## Decisions

| # | Topic | Decision | Why |
|---|-------|----------|-----|
| 1 | Existing JSON data | **Start fresh.** No import step. | Current data is fake test data, so an importer would be wasted effort. |
| 2 | Tags | **Separate `tags` table + `character_tags` link table**, built now. Tag-picker UI later. | Adding it now is cheap. Adding it later needs a data migration. Enables rename-once, filter-by-tag, and pick-from-existing (designed in `future_ideas.md`). |
| 3 | Handwriting strokes | **One blob per character**, stored as packed binary rather than JSON text. | Nothing needs to search inside individual points. Packed binary is roughly 3x smaller than JSON text. See the size notes below. |
| 4 | Flashcard stats | **Counters only**: seen / correct / incorrect / last reviewed, updated in place (+1, new date). No per-answer history log. | Matches how the stats are actually used today. Progress-over-time and spaced repetition aren't wanted. If they ever are, a log table can be added then; history before that point just won't exist (accepted). |
| 5 | Photo gallery | **Create a `character_photos` table now; build the screens later.** Photos are stored as **image files** in the app folder, and the database stores only each file's path and which character it belongs to. | Standard practice. Putting images inside the database bloats it and slows every query. |
| 6 | Reactive UI | **Storage swap only.** Keep `ChangeNotifier` + in-memory list. No Drift "watch" streams yet. | Smallest change, so it's easy to confirm the migration works before touching any screens. Can revisit later. |

### Size notes for strokes (question 3)
- One point = x, y, and a timestamp. Packed as binary that's about **8–12 bytes**. As JSON text it's about 30–40 bytes.
- A typical character is roughly 10–20 strokes × ~50 points, so about **1,000 points ≈ 10 KB**.
- **1,000 characters ≈ 10 MB**, about the size of 2–3 phone photos. That's a non-issue for a personal dictionary.
- If it ever matters, points can be downsampled (fewer points per stroke) with no visible difference.

### Pros and cons: storage swap only vs. reactive streams (question 6)

**One-line version:** A = keep everything in memory, and the database is just where it's saved. B = don't keep a copy; ask the database each time a screen needs data. Querying SQLite on the phone takes milliseconds, so B isn't slow. It just means the screens get rewritten to ask for data.

**A) Storage swap only (chosen)**
- How it works: on launch, load everything from SQLite into memory. Every change writes to SQLite **and** updates the in-memory list, then `notifyListeners()` refreshes the screens. The same pattern as today, with a different storage layer underneath.
- ✅ Screens don't change at all, so the change stays small and there's less risk of breaking them.
- ✅ Easy to reason about.
- ❌ Two copies of the truth (memory + database) that the code has to keep in sync by hand.
- ❌ Everything gets loaded into memory. Fine at hundreds to a few thousand characters, less so at huge scale.

**B) Drift watch streams (maybe later)**
- How it works: each screen asks the database directly ("watch the list of non-archived characters"), and Drift automatically re-sends the results whenever those tables change.
- ✅ Only one copy of the truth, the database.
- ✅ Screens load only what they need, so it scales better.
- ✅ Filtering and search happen as real SQL queries.
- ❌ Every screen has to be rewritten to use `StreamBuilder`.
- ❌ More moving parts to learn and debug.

---

## Open items

- **7 — Export / backup / restore.** Postponed. The goal: package all data to move to a new phone or protect against the app being deleted, and re-import it, triggered manually. Details TBD.

---

## Table layout (approved 2026-09-19)

- **characters**: id, typed_character (defaults to "?"), definition, notes, is_starred, is_hard, is_archived, created_at, updated_at, handwriting (packed binary blob, nullable), times_seen, times_correct, times_incorrect, last_reviewed_at (nullable)
  - The flashcard counters are columns on the character row rather than a separate table. There's exactly one set per character, so a separate table would only add a join.
- **tags**: id, name (unique)
- **character_tags**: character_id → characters, tag_id → tags, position (keeps tags in typed order)
- **character_references**: character_a_id, character_b_id (each pair stored once; both sides see it)
- **character_photos**: id, character_id → characters, file_path, created_at
- Deleting a character automatically removes its tag links, references and photo rows ("cascade"). Photo **files** get deleted by app code.

---

## 2026-09-19 — Implementation

**What changed in the code:**
- `lib/data/app_database.dart` (new): the Drift tables above plus the `AppDatabase` class with small query helpers. `DictionaryStore` is the only thing that uses it.
- `lib/data/stroke_codec.dart` (new): packs handwriting into the binary blob (12 bytes per point) and unpacks it. It has a version byte, so the format can change later without breaking saved drawings.
- `lib/data/dictionary_store.dart`: same public API, now backed by the database. Each change is written to SQLite first and then applied in memory.
- `lib/data/storage_service.dart`: **deleted** (the JSON file is no longer used).
- `lib/data/character_entry.dart`: gained a shared `parseTags()`. `widgets/tag_chip.dart` now uses it.
- `lib/main.dart`: opens `AppDatabase()` instead of the JSON storage.
- `pubspec.yaml`: added `drift`, `drift_flutter`, and dev-only `drift_dev` and `build_runner`. `build.yaml` (new): dates are stored as readable text with millisecond precision.
- Tests: the store tests now run on SQLite, including new "survives a reload" tests. New `stroke_codec_test.dart`. `widget_test.dart` replaced Flutter's leftover counter template with a real "app starts" smoke test.

**Smaller choices made along the way:**
- **Database location:** app-private storage on Android. ~~`%APPDATA%` on Windows~~ changed the same day, see below.
- **Tags stay a comma-separated string in the UI.** The store splits it into the tag tables on save and joins it back on load, which is why no screen had to change. Saving also tidies it up: trims spaces, drops empties, removes duplicates.
- **Unused tags are kept** in the `tags` table, so the future tag picker can offer them.
- **The example character is seeded only when the database is first created.** If you delete it, it doesn't come back on the next launch. The old JSON version had the same intent.
- **Deleting a character also deletes its photo files.** The database cascade removes the photo rows, and the code deletes the image files.

**Not verified yet:** the cloud environment still can't reach pub.dev, so nothing was compiled or run. The first real check is on your laptop:
1. `flutter pub get`
2. `dart run build_runner build`
3. `flutter analyze`
4. `flutter test`

If anything fails, paste the output back.

---

## 2026-09-19 — Change: database location on Windows

- **Decision:** on Windows, the database now lives in a visible folder: `Documents\Cantonese Dictionary\cantonese_dictionary.sqlite`. It was in `%APPDATA%`.
- **Why:** `%APPDATA%` is hidden, so it's easy to forget the data exists, which makes it easy to lose or never back up. A named folder in Documents is easy to find and easy to copy.
- **Android is unchanged** (app-private storage). That's the phone standard. A visible location there needs extra storage permissions and fights Android's storage rules. Getting data off the phone will be handled by the backup/export feature (open item 7).
- **Code:** `AppDatabase.databaseDirectory()` in `lib/data/app_database.dart` picks the folder per platform.

---

## 2026-09-19 — Change again: database inside the repo (Windows)

- **Decision:** on the Windows laptop the database lives **inside the project folder**: `local_data\cantonese_dictionary.sqlite`, next to `pubspec.yaml`. This replaces the `Documents\Cantonese Dictionary\` location from the entry above.
- **Why:** it keeps the data next to the code where it can't be forgotten, rather than in a separate place on the laptop.
- **Git-ignored:** `/local_data/` is in `.gitignore`. The database holds personal data, and it's a binary file that changes constantly, which would clutter git history. Back it up by copying the folder.
- **How the app finds the folder:** it walks up from where it was started, and from where its `.exe` lives, until it finds this app's `pubspec.yaml`. If it can't find it (e.g. a release `.exe` copied elsewhere), it falls back to `Documents\Cantonese Dictionary\`.
- **Android unchanged:** app-private storage. The phone has no copy of the repo.
- **Trade-off noted:** normally an app's data doesn't live inside its source folder (your earlier note: a running app shouldn't be editing its own files). That's acceptable here because it's only on the development laptop and it's git-ignored. The phone, where the app will actually live, uses standard app storage.

---

## 2026-09-19 — First real build on the laptop

- **`build_runner`** worked. It printed 5 warnings: *"This parameter should be a simple class name"* on every `.references(DbCharacters, #id, ...)`.
  - **Fix:** the foreign keys are now plain SQL in each table's `customConstraints` instead of `.references(...)`. `deleteCharacter` also removes a character's tag links, references and photo rows **explicitly** in one transaction, so deleting is correct even without the cascade. A new test checks that a deleted character's links are gone after reopening the database.
  - Since the table definitions changed, **rerun `build_runner`**. If a `local_data` folder was already created, delete it so the database is rebuilt with the new constraints (it only held test data).
- The newer `build_runner` **no longer accepts `--delete-conflicting-outputs`** (it's ignored). The docs now just say `dart run build_runner build`.
- **`flutter analyze`:** 0 errors, 15 info-level hints. The two from this change were fixed (a double-quoted string, an unneeded `dart:async` import). The rest are older style hints in the screens and theme (`use_build_context_synchronously`, deprecated `withOpacity`, `prefer_const`). They're harmless and left for a separate cleanup.

---

## 2026-09-19 — Verified ✅

- `build_runner` (no warnings), `flutter analyze` (info hints only) and `flutter test` all pass.
- Manual testing works as intended: adding/editing characters, drawings, tags, star/hard, references, flashcards, archiving and deleting, with everything still there after a full restart.
- **Migration complete.** Still open: export/backup/restore (#7), and the leftover info-level lint hints in the screens and theme (optional cleanup).
