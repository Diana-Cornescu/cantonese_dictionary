# Limitations & storage notes

An honest account of where the app falls short today, and why the storage
layer looks the way it does. A living document — update it whenever a
limitation gets fixed or a new one turns up, per the "docs travel with every
change" convention in the root `README.md`.

**What to build next is not here any more** — that's **`roadmap.md`**. This
file says what's *true of the app today*; the roadmap says what's next.
(The filename still says "roadmap" for now; rename it with `git mv` when
convenient.)

## Current limitations (v1)

- **Screens still hold everything in memory** — since 2026-09-19 the data lives in SQLite, but `DictionaryStore` still loads every character into memory at startup and filters in Dart ("storage swap only", decision 6 in `decisions_log_sqlite_drift.md`). Fine at personal-dictionary scale; see the storage section below for when to switch to live database queries.
- **No handwriting recognition** — adding a character means typing/pasting it directly; the app doesn't guess it from your drawing. Fully designed and parked, not forgotten — see `future_ideas.md`.
- **No cloud backup or automatic sync.** Data lives on the device. Since 2026-09-19 you can back up everything (database + photos) to one `.zip` file through Settings and restore it on any device, including after reinstalling. You choose where the file goes (e.g. Google Drive), and it's manual only: nothing backs up automatically.
- ~~**Tags are still typed as free text.**~~ Fixed in 1.3.0: a Tags screen, a pick-from-existing picker, rename-with-merge and delete. Tags no character uses stay in the table and show greyed at 0. **Still missing: filtering the dictionary by tag** — see `roadmap.md`.
- **Single-device, single-user only** — no accounts, no concept of syncing between your phone and desktop copies; they're two independent dictionaries. You can copy one to the other with backup & restore, but restore replaces everything (no merging).
- **Dynamic resizing is breakpoint-based, not a manual drag handle** — the character/translation windows switch between side-by-side and stacked based on screen width, but there's no draggable divider to fine-tune the split yet (deliberately deferred until a working prototype showed what was actually worth making resizable).
- **No Jyutping/romanization field, no audio pronunciation, no stroke-order playback** — the handwriting data model already records a timestamp per point specifically so stroke-order playback could be added later without changing what's stored; it just isn't built yet.
- **No batch import** — characters are added one at a time through the Add screen.
- **Every change repaints the whole app.** `main.dart` wraps `MaterialApp` in a `ListenableBuilder` on the store, so any save rebuilds the Navigator and its overlay too. Works, but it's the one known source of fragility — see Chores in `roadmap.md`.
- **Hand-written without a working compiler** — the environment this app was built in couldn't install the Flutter/Dart tooling, so v1's code (and the 2026-09-19 SQLite + Drift change) was hand-reviewed before reaching you, then compiled and verified on your own laptop. The SQLite change was verified on 2026-09-19. See `decisions_log.md`'s 2026-07-20 entry for the full story.

## Storage architecture: SQLite + Drift (since 2026-09-19)

v1 stored everything in one hand-written JSON file, rewritten in full on every change. On 2026-09-19 that was replaced by a local SQLite database through Drift, the setup the original design plan had called for. The full decisions and reasoning are in `decisions_log_sqlite_drift.md`. In short:

**What changed:**
- Each change now updates only the rows it touches. The JSON file rewrote everything, every time.
- Data is split into real tables: `characters` (including handwriting as a packed binary blob and the flashcard counters), `tags` + `character_tags`, `character_references`, and `character_photos`.
- Deleting a character automatically removes its tag links, references and photo rows (foreign-key cascade).
- Future changes to the tables use Drift's versioned migrations (`schemaVersion` + `onUpgrade` in `app_database.dart`) instead of ad-hoc JSON defaults.

**What's the same:**
- Everything stays offline and on the device.
- `DictionaryStore`'s public API is unchanged, so no screen changed.

**New costs:**
- A code-generation step (`build_runner`) whenever a table changes. See `setup_manual.md`.
- Three more packages (`drift`, `drift_flutter`, and dev-only `drift_dev`/`build_runner`).
- The database isn't plain text. Use "DB Browser for SQLite" to look inside.

**Remaining trade-off:** the store still loads everything into memory and filters in Dart. When to switch the screens to live Drift queries ("watch streams"):
1. The handwriting recognizer in `future_ideas.md` gets built and needs to compare against many stored drawings efficiently.
2. The dictionary grows to many thousands of entries, and startup or search gets noticeably slow.
3. Multi-device sync or a shared version is ever wanted (not a current goal).

## What's next

Not listed here any more, to stop the same idea living in three files with
three different amounts of detail. **`roadmap.md`** holds everything ahead;
**`future_ideas.md`** holds the long write-ups for the big parked designs.
