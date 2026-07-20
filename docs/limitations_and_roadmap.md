# Cantonese Dictionary App — Limitations & Future Roadmap

An honest account of where v1 falls short, plus concrete ideas for later. This is a living document — update it whenever a limitation gets fixed or a new one is discovered, per the "docs travel with every change" convention in the root `README.md`.

## Current limitations (v1)

- **Storage has a scalability ceiling** — the whole dictionary lives in one JSON file that gets fully rewritten on every single change, and no dedicated query engine exists (just in-memory filtering). Not a practical problem at the scale of a personal study dictionary; see the dedicated section below for the detail and the concrete point at which this would be worth revisiting.
- **No handwriting recognition** — adding a character means typing/pasting it directly; the app doesn't guess it from your drawing. Fully designed and parked, not forgotten — see `future_ideas.md`.
- **No cloud backup or multi-device sync** — the data file lives only on this device. The Export feature produces a human-readable JSON snapshot of everything except handwriting and internal ids, which is useful as a portable record, but it isn't a full backup/restore format (re-importing an export isn't built). Back up the real data file directly if you want a true backup; where that file lives is covered in the storage section below.
- **Tags are free text**, not a managed/reusable list. A managed list (pick-from-existing, rename-once-updates-everywhere, browse/filter by tag) was designed and parked — see `future_ideas.md`.
- **Single-device, single-user only** — no accounts, no concept of syncing between your phone and desktop copies; they'd be two independent dictionaries unless you manually export/import between them (and import isn't built yet either).
- **Dynamic resizing is breakpoint-based, not a manual drag handle** — the character/translation windows switch between side-by-side and stacked based on screen width, but there's no draggable divider to fine-tune the split yet (deliberately deferred until a working prototype showed what was actually worth making resizable).
- **No Jyutping/romanization field, no audio pronunciation, no stroke-order playback** — the handwriting data model already records a timestamp per point specifically so stroke-order playback could be added later without changing what's stored; it just isn't built yet.
- **No batch import** — characters are added one at a time through the Add screen.
- **Hand-written without a working compiler** — the environment this app was built in couldn't install the Flutter/Dart tooling, so v1's code was carefully hand-reviewed but never compiled or run before reaching you. Your first `flutter pub get` / `flutter analyze` / `flutter test`, per `setup_manual.md`, is this code's real first check. See `decisions_log.md`'s 2026-07-20 entry for the full story.

## Storage architecture: JSON file vs. an embedded database — trade-offs and when to revisit

v1 stores everything in a single hand-written JSON file (via `StorageService`/`DictionaryStore`) instead of the SQL database (Drift) originally planned in `design_plan.md`. That change happened because the build environment had no way to compile or check generated database code — see `decisions_log.md` for the full reasoning. Independent of why it happened, it's worth understanding the trade-off on its own terms now that it's a real part of the app.

**What you don't lose:** data integrity for normal use. Every save writes to a temporary file first and only then atomically replaces the real one, so an interrupted write (app killed mid-save, phone dies) can never leave you with a half-written, corrupted file — you either keep the old version intact or get the fully-written new one. For a single-user, single-device app, this covers the realistic failure mode.

**What you do lose, in principle:**
- **Write efficiency at scale.** Every change — even starring one character — rewrites the entire file, not just the one record that changed. A real database only touches the changed row.
- **A query engine.** Every lookup (search, filters, the reference search bar) is a plain in-memory loop over Dart objects rather than an indexed SQL query. Fine for the filters that exist today; each new kind of lookup added later is hand-written code rather than a query.
- **Schema migrations.** Drift has built-in, versioned support for evolving a data model without breaking existing users' saved data. The hand-rolled version relies on the JSON parser defaulting missing fields sensibly — workable, but ad hoc rather than tested infrastructure. Changing the shape of a character record later needs care by hand.

**What you actually gain:** one fewer moving part in the build (no code-generation step required), one fewer third-party dependency, and a data file that's plain, human-readable JSON — you can open it yourself and see exactly what's in there, which a SQLite database file doesn't offer without a separate DB browser tool. That fits a self-built, hands-on project well.

**Where the practical ceiling actually is:** for a personal study dictionary — realistically hundreds to a few thousand characters, even with hand-drawn strokes attached to each — a full-file rewrite is still comfortably sub-second on any modern phone or PC. This is not expected to be something you feel in daily use.

**Concrete triggers to revisit this decision:**
1. The handwriting recognizer in `future_ideas.md` gets built — it needs to compare a new drawing against *every* stored template, which benefits substantially from an indexed data store instead of a linear scan.
2. The managed tag list in `future_ideas.md` gets built — a real many-to-many relationship is a more natural fit for a relational database than hand-maintained id lists.
3. Multi-device sync or a shared/multi-user version is ever wanted (not a current goal, noted here only as a trigger).
4. The dictionary grows dramatically larger than a personal study tool would realistically reach (tens of thousands of entries with substantial attached data).

If any of those happen, the migration is contained: every screen talks to storage only through `DictionaryStore`'s methods, never directly, so swapping the underlying storage mechanism would mean rewriting `lib/data/` without touching the UI layer.

## Future improvement ideas

Two are already fully designed and parked, not just brainstormed — see `future_ideas.md` for the complete write-up of each:
- Handwriting recognition (self-learning template matching against your own saved samples).
- A managed/reusable tag list.

Others, not yet designed in detail:
- Jyutping (romanization) field per character.
- Audio pronunciation recording/playback.
- Stroke-order playback (the data needed for this is already being captured — see the limitations list above).
- Batch import of characters (e.g., from a spreadsheet or another export file).
- Backup/restore via a file picker, including re-importing an export file (today, export is one-way).
- A manual draggable resize handle between the character and translation windows, once real usage shows what's worth making resizable.
