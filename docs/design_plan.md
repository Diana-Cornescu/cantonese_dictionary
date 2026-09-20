# Cantonese Dictionary App — Design Plan

Status: v1 implemented (see `docs/decisions_log.md` for the build's dated history, including an architecture change from what's described below — read the "Note on implementation" callouts in this document for what changed and why). Not yet built/run on real hardware — that first pass happens on your own machine, per `docs/setup_manual.md`.

## 1. Recommended tech stack

**Flutter (Dart)** is the recommended framework. The main reason is that it is the only realistic option that lets you build one codebase and run it both on Android and on your desktop (Windows) with native windowing, which matters a lot here because two of your features — mouse-drawn handwriting and dynamic split-view resizing — are far easier to develop and test on a desktop window than on a phone screen or emulator. You'd write the app once, run `flutter run -d windows` while developing and testing with your mouse, then build the same code into an Android APK when you're ready to put it on your phone, where the drawing surface will accept touch input with no code changes.

Supporting choices:

- **Local storage (since 2026-09-19):** a local SQLite database through Drift (`lib/data/app_database.dart`), stored inside the project folder (`local_data/`, git-ignored) when run on the Windows laptop, and in app-private storage on Android. Tables: `characters` (including handwriting as a packed binary blob and the flashcard counters), `tags`, `character_tags`, `character_references`, `photos`, `photo_characters`, `app_settings` (schema version 3 since 2026-09-20). See `docs/decisions_log_sqlite_drift.md`. *(v1 used a single hand-written JSON file; the sections below that describe the JSON layout are kept for history.)*
- **State management:** a single `ChangeNotifier` (Flutter's own built-in class, not a package), consumed by widgets via `ListenableBuilder`.
- **Handwriting canvas:** built directly with Flutter's `CustomPainter` + `GestureDetector`/`Listener` APIs — no third-party drawing package needed. This also gives full control over capturing raw stroke point data (with timestamps), which supports things like stroke-order playback later.
- **No network permissions requested at all** in the Android manifest — the app cannot reach the internet even if it wanted to, so "fully local" is enforced at the OS permission level, not just by convention.

One clarification on "limit servicers/external tools": `path_provider` is the ONLY third-party package this app depends on — everything else (persistence, state management, UI) is either hand-written or built directly into Flutter itself. There is no server, daemon, cloud account, or network call involved anywhere.

> **Note on implementation:** the original version of this plan proposed Drift (a SQL/codegen layer) and Riverpod (a state-management package) instead of the above. That changed after implementation started — full story and reasoning in `docs/decisions_log.md`'s "Sandbox constraint" entry, short version: the environment used to build this code turned out to have no path to installing the Flutter/Dart tooling or reaching pub.dev, so nothing could be compiled or run while writing it. Shipping hand-reconstructed codegen output that had never been checked by a real compiler was judged too risky, so the plan simplified to remove codegen entirely — which, as a side effect, also reduces the dependency list, in keeping with your original minimalism request. The data actually stored and the app's behavior are unchanged from what's described below; only the underlying storage/state-management mechanism differs from the original plan.

## 2. Data model

One JSON file, containing a list of character records (each shaped like the "table" below — the three logical record types from the original SQL-based plan are embedded directly rather than split into separate physical tables, since JSON naturally nests):

**Each character record has:**
- `id` (integer)
- `typedCharacter` (text — the actual Chinese character(s))
- `handwrittenSample` (JSON blob: list of strokes, each stroke a list of `{x, y, t}` points — the current drawing for this character; redrawing it simply overwrites this value, no history of past drawings is kept)
- `definition` (text, user-editable)
- `notes` (text, user-editable)
- `tags` (text, simple comma-separated short tags like "food", "verb" — kept as free text rather than a separate table, since you described them as short informal labels, not a controlled taxonomy)
- `isStarred` (bool)
- `isHard` (bool)
- `isArchived` (bool)
- `createdAt`, `updatedAt` (timestamps)
- `flashcardStats`: `{ timesSeen, timesCorrect, timesIncorrect, lastReviewedAt }` (embedded 1:1, was a separate `flashcard_stats` table in the original plan)
- `referencedCharacterIds`: a list of other characters' ids (embedded, was a separate `character_references` join table in the original plan) — kept symmetric/undirected in code: a reference added from either side is written onto both characters' lists in the same operation, and removed from both the same way, so the two sides can never drift out of sync.

## 3. Screens and components

**Main dictionary list.** A scrollable list of rows. Each collapsed row shows, left-to-right: a rendering of the typed character plus its short tag chips, then the custom definition (truncated to one or two lines) on the right. Each row has star, hard-flag, archive, and delete buttons. Tapping a row opens a dedicated character detail screen with:
- **Character window (left half):** a toggle switch lets you flip between the typed character view and the saved handwritten drawing rendered from its stroke data, showing one at a time rather than splitting the space between them.
- **Translation window (right half):** four stacked sections — the editable definition, a notes field, the flashcard stats display (times seen, and a computed correct/incorrect percentage), and the references section with its own search bar (searches every character's `definition` text and lets you add/remove links to other rows).

**Add new character flow.** A dialog/screen that asks you to draw the character on the canvas (saved as its handwritten sample), type the character itself directly — via your keyboard's Chinese/Cantonese input method, or by pasting it in from elsewhere — and enter the definition. There's no auto-recognition step in v1; that idea is parked in `docs/future_ideas.md` for a possible later version.

**Flashcard mode** (redesigned 2026-09-20). Options bar at the top: two dropdowns, *All characters / Hard only / Favorites only* and *Character → Definition / Definition → Character / Bidirectional* (Bidirectional = each card asked a random way). You tap to reveal, then mark correct or incorrect; both directions update the same stats. "Go to character screen" appears after revealing. It opens with All characters + Character → Definition. See `docs/decisions_log.md` (2026-09-20).

**Settings → Backup & restore** (since 2026-09-19; replaced the old JSON export). A gear icon on the home screen opens Settings. Back up saves one `.zip` (database + photos + info) through the system Save window. Restore replaces everything with a chosen backup, after saving an automatic safety copy (with an "Undo last restore" option). See §5.

**Photos** (added 2026-09-20). Photos of characters seen out and about. A Photos row on each character's screen, and a gallery screen (🖼 on the home screen) with every photo. Add by camera or the phone's gallery. One photo can link to several characters and has an optional note. The app stores its own resized copy, and backups include it. See `docs/decisions_log_photo_gallery.md`.

**Navigation** (2026-09-20). The home screen has a ☰ side menu with Flashcards, Photos, Archive and Settings. There are no top-bar icons on the home screen.

**Color theme** (2026-09-20). Settings → Color theme: 8 palettes (blues, teal, purples, slate), chosen so they never clash with the meaning colors red/gold/green. Stored in the `app_settings` table (schema version 3). See `lib/theme/app_palettes.dart`.

**Confirmation dialogs.** A single reusable confirmation dialog component is triggered before committing any edit — this includes editing the definition, editing notes, changing tags, archiving, and deleting. Star/hard toggles are confirmed as the one exception: they stay instant with no popup, since they're trivially reversible with one more tap and would otherwise add real friction to something you'll likely do often and casually.

**Dynamic resizing.** Kept intentionally general for now: screens use flexible/responsive layout containers so panes reflow across different window and screen sizes, but exactly which boundaries (if any) get a draggable resize handle is left open until an early prototype makes it clear what's actually worth making resizable.

## 4. Reference search

The search bar in the reference section runs a simple case-insensitive substring match over every character's `definition` field (plain in-memory filtering — fully adequate at the scale of a personal dictionary, no search index needed) and returns matching rows as candidates to link. The link is written onto both characters' `referencedCharacterIds` in one operation and displayed from both linked rows.

## 5. Backup format (replaced the JSON export on 2026-09-19)

One `.zip` file, named like `cantonese_dictionary_backup_2026-09-19_1432.zip`:
- `backup_info.json`: format name and version, database schema version, creation date, character and photo counts.
- `database.sqlite`: a complete, clean copy of the database (made with SQLite's `VACUUM INTO`).
- `photos/`: every character photo file.

Restore checks the file first (is it one of ours? is it from a newer app version?) and only then replaces all data. The old human-readable JSON export was removed, because backups cover the real need (moving phones, surviving an uninstall). See `docs/decisions_log_backup_and_release.md`.

## 6. Example row

On first launch (when the database is empty), the app seeds one demo character row automatically — a real, simple Cantonese character with a filled-in definition explaining what each field is for, one example tag, starred so you can see what a starred row looks like, and a note pointing out that this row can be deleted once you understand the layout. This satisfies the "fresh install shouldn't be an empty blank screen" requirement.

## 7. Project structure (for reference)

Includes a `docs/` folder for this plan and the project's other written records — setup instructions, limitations, parked ideas, and an ongoing decisions log — alongside the usual `lib/`/`test/` code layout:

```
docs/              # this design plan, setup manual, limitations doc, parked-feature write-ups, and an ongoing decisions/challenges log
  design_plan.md
  future_ideas.md
  setup_manual.md
  limitations_and_roadmap.md
  decisions_log.md
lib/
  main.dart
  data/
    character_entry.dart    # CharacterEntry + FlashcardStats models, toJson/fromJson
    app_database.dart       # Drift tables + database (SQLite); app_database.g.dart is generated
    stroke_codec.dart       # packs/unpacks handwriting strokes to a binary blob
    dictionary_store.dart   # ChangeNotifier: in-memory list + all CRUD/reference/flashcard/query methods
    backup_service.dart     # creates/restores the backup .zip
    photo_entry.dart        # photo model
  features/
    dictionary_list/
    character_detail/
    add_character/
    flashcards/
    settings/          # settings_screen.dart (backup & restore)
    photos/            # gallery, photo viewer, photo picking, character picker
  widgets/          # reusable: confirm dialog, handwriting canvas, tag chip
test/
  dictionary_store_test.dart
  backup_service_test.dart
  photo_store_test.dart
  stroke_codec_test.dart
```

## 8. Documentation to be produced alongside the app

All of this project's documentation lives together in the `docs/` folder shown above:

- **Setup manual** (`docs/setup_manual.md`): step-by-step instructions covering installing the Flutter SDK and Android Studio, running the app on desktop for development/testing, connecting/enabling a physical Android phone (or emulator) and building a debug build onto it, and building + sideloading a signed release APK for daily use without a dev environment attached.
- **Limitations & future improvements** (`docs/limitations_and_roadmap.md`, already written — see below): an honest account of where v1 falls short — e.g., no cloud backup/sync (the data file lives only on your device unless you manually export/back it up), tags being free text rather than a managed list, single-device/single-user only, and the storage architecture's own trade-offs and upgrade triggers — plus concrete ideas for later (Jyutping romanization field, stroke-order playback, audio pronunciation, batch import, backup/restore via file picker, and the parked handwriting recognizer described next).
- **Parked ideas** (`docs/future_ideas.md`, already written — see below): concepts discussed but deliberately left out of v1, starting with the self-learning handwriting recognizer, kept in full so they're easy to revisit later.
- **Decisions log** (`docs/decisions_log.md`, already started — see below): a running, dated record of notable pivots, challenges, and how they got resolved as the app goes from plan to build.

## 9. Status

All planning questions are resolved: Flutter is confirmed as the framework, and tags are confirmed as free-text (a managed/reusable tag list was considered and parked — see `docs/future_ideas.md`). v1 is now implemented (all screens, the data layer, and tests) and hand-reviewed carefully — see the "Note on implementation" in section 1 for why it was hand-reviewed rather than compiler-checked, and `docs/decisions_log.md` for the full dated history. Next step: your first `flutter pub get` / `flutter analyze` / `flutter test` run on your own machine, per `docs/setup_manual.md` — that's the real first verification pass this code gets.
