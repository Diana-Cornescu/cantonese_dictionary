# Cantonese Dictionary App — Decisions Log

A running, dated record of notable pivots, challenges hit, and how they were resolved, from initial planning through active development.

## 2026-07-19 — Initial planning round

- **Character detail view:** tapping a row opens a dedicated detail screen rather than expanding in place — simpler to implement inside a scrolling list.
- **Character window:** typed and handwritten views are shown via a toggle switch, not a resizable split.
- **Confirmation dialogs:** required before committing definition/notes/tag edits, archiving, or deleting. Star/hard shortlist toggles are the one exception and stay instant, since they're low-stakes and reversible with one more tap.
- **Handwriting storage:** only a single current drawing is kept per character — redrawing it overwrites the previous one, with no version history.
- **Handwriting recognition:** parked out of v1 as too complex for the value it would add this early; see `future_ideas.md`. Adding a character instead takes a typed/pasted character directly, alongside its handwritten drawing, with no auto-suggestion step.
- **Dynamic resizing:** left intentionally general until an early prototype clarifies which panes are actually worth making resizable.
- **Export format:** JSON only, no CSV option, since it represents tags and references cleanly without a second, lossier export path to maintain.
- **Documentation:** all project docs (this log, the plan, the setup manual, the limitations/roadmap doc, and parked ideas) live together under `docs/`.

## 2026-07-19 — Follow-up: framework, tags, and process conventions

- **Framework:** Flutter confirmed. No strong prior opinion on alternatives, comfortable proceeding on the recommendation.
- **Tags:** confirmed free-text for v1. A managed/reusable tag list was considered and parked — see `future_ideas.md`.
- **Documentation convention established:** every future change (feature, scope, or architecture) must be accompanied by corresponding updates to `README.md` and any other affected file under `docs/`. This is now written into the project `README.md` itself so it's discoverable in any future session, not just remembered in conversation.
- **Setup manual started:** `docs/setup_manual.md` created as a running checklist of everything needed to develop/run the app, to be kept current as new tools or steps are introduced (e.g., release signing, once we reach that point) rather than written only at the end.

No open questions remain from the initial planning round. Ready to move into implementation.

## 2026-07-20 — Implementation: sandbox constraint and architecture pivot

- **Sandbox constraint discovered:** the cloud environment used to write this app's code has no path to github.com, pub.dev, storage.googleapis.com, or any OS package mirror (all blocked at the network level). That meant the Flutter/Dart SDK could not be installed there, and `flutter pub get`/`analyze`/`test` could not be run there either — the code had to be hand-written and hand-reviewed, with no compiler available at any point during the build. This is a limitation of the cloud build environment only — your own Windows machine has normal internet access and none of this applies once the project is in your hands.
- **Architecture simplified as a direct result:** the original plan (section 1/2 of `design_plan.md`) called for Drift (SQL + code generation) and Riverpod (a state-management package). Both were dropped. Reasoning: Drift's codegen produces a generated file that's normally machine-checked by `build_runner`; hand-writing a stand-in for that generated code with no compiler to check it against was judged too risky to ship. Rather than hand-fake the generated output, the plan was simplified to remove the need for it entirely: persistence is now a single hand-written JSON file (atomic temp-file-then-rename writes, via `dart:io`/`dart:convert`), and state management is a plain `ChangeNotifier` (built into Flutter, not a package). `path_provider` remains the only third-party dependency. Net effect: fewer dependencies than originally planned (a bonus given the original minimalism request), same data actually stored, same app behavior — see the updated section 1/2 of `design_plan.md` for the corrected description.
- **Verification approach given no compiler:** every file was manually cross-checked after writing — imports resolve to real files, cross-file method/class references match actual declarations, and brace/paren/bracket balance was verified with a small purpose-built script (a naive first attempt at that script produced false positives from apostrophes inside string literals like "you're" — worth remembering if this comes up again). This is a careful hand-review, not a substitute for a real compile — your first `flutter pub get` / `flutter analyze` / `flutter test` run, per the updated `docs/setup_manual.md`, is this code's actual first verification pass. If it surfaces anything, that's expected to be genuinely possible, not a sign of a process failure.
- **`docs/setup_manual.md` updated:** added a step to run `flutter create --platforms=android,windows --org com.cantonesedictionary --project-name cantonese_dictionary .` inside the project as a one-time first action, since the `android/`/`windows/` platform folders (Gradle files, icons, Windows runner/CMake files) also couldn't be generated without the real Flutter tool.
- **`docs/limitations_and_roadmap.md` written:** this doc was planned from the start of the project but never actually produced until now — prompted by a question about the JSON-vs-database trade-off, which turned out to be exactly what this doc is for. It covers all current v1 limitations, a detailed breakdown of the storage architecture's trade-offs and concrete triggers for revisiting it, and the future-improvement roadmap (rolling up the two fully-designed parked ideas in `future_ideas.md` plus lighter-weight ideas not yet designed in detail).

## 2026-09-19 — Storage moved to SQLite + Drift

- The JSON file storage was replaced with a local SQLite database through Drift, the setup the original plan had called for. Screens are unchanged; only `lib/data/` was rewritten.
- The full decisions, reasoning and TL;DR are in their own file: **`docs/decisions_log_sqlite_drift.md`**.

## 2026-09-19 — Backup & restore, first release build

- Settings screen with backup/restore (one `.zip`) replaced the JSON export. Release signing and versioning were set up.
- Full decisions and reasoning: **`docs/decisions_log_backup_and_release.md`**.

## 2026-09-19 — Shorter "back" history (option A)

- **Problem:** following references from character to character stacked up screens, so getting back took many presses.
- **Options considered:** A) replace the screen instead of stacking; B) keep only the last few characters; C) jump back to an already-open character instead of opening it again.
- **Decision: A**, "for the moment". A reference opens in place of the current character screen, so Back always returns to the list you came from (home or archive). Simplest, and nothing piles up. The trade-off: Back no longer goes to the *previous character*. B or C could be added later if that's missed.
- **Code:** one change in `character_detail_screen.dart` (`Navigator.push` → `Navigator.pushReplacement`).

## 2026-09-20 — Undo / clear buttons while drawing

- **Request (Priority 2):** undo the last stroke, or reset the drawing, inside the drawing window. Before, you had to press "Done" and redraw.
- **Decision:** the buttons are built into the drawing box itself (`widgets/handwriting_canvas.dart`), so every place you draw gets them automatically: the Add character screen and the Redraw window on the character screen. They're two small icons in the top-right corner (Undo ↶, Clear 🗑) that don't take space from the drawing, and they're greyed out while the box is empty.
- **Detail:** if you clear the Redraw window and then press "Use this drawing", nothing changes. An empty drawing never replaces a saved one. On the Add screen, a cleared drawing counts as "not drawn yet", which the required-drawing check already handles.

## 2026-09-20 — Flashcards in both directions

- **Request (Priority 2):** practise Definition → Character too, not only Character → Definition, or a mix of both.
- **New flashcard screen layout:** three rounded toggle boxes at the top replace the old "Hard" switch:
  - **Hard only**: only hard-flagged characters.
  - **Character → Definition**: the front shows the character, the back shows the definition.
  - **Definition → Character**: the front shows the definition, the back shows the typed character **plus your drawing** (scaled to fit).
  - With **both directions on**, every card randomly picks one. A small label on the card says which way it's being asked.
- **Behaviour you chose:**
  - **Default on every open:** only Character → Definition on, Hard only off (same as before).
  - **Stats:** one shared set of counters for both directions, so no database change.
  - **Definitions are now required** when adding a character (Save stays disabled until there is one), and can't be emptied when editing. This way every card works in both directions.
- **Smaller choices made along the way:**
  - At least one direction must stay on. Trying to turn off the last one shows a short message instead.
  - Changing any box reshuffles and starts again from card 1 (like the Hard switch did).
  - Older characters without a definition, if any, are skipped when only Definition → Character is on, and always asked Character → Definition in mixed mode.
- **Code:** `flashcard_mode_screen.dart` (rewritten); `handwriting_canvas.dart` gained a `fitToBox` option for small previews; the add and character screens now require a definition.

## 2026-09-20 — Tested ✅

- Tested on the laptop and working: undo/clear while drawing, the shorter back history, flashcards in both directions, and the required definition. Ready for release 1.1.0.

## 2026-09-20 — Photo gallery (schema version 2)

- Photos of characters seen out and about: a Photos row on the character screen, a gallery screen, camera or gallery input, several characters per photo, and an optional note.
- Full decisions and reasoning: **`docs/decisions_log_photo_gallery.md`**.

## 2026-09-20 — Flashcards: drawing on the character side in both directions

- **Change:** in **Character → Definition**, the question side now also shows your drawing under the typed character, just like the answer side of Definition → Character. It shows whenever a drawing exists.
- **Why:** your request, so both directions look the same and you see your own handwriting every time.
