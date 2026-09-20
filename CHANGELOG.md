# Changelog

What changed in each release installed on the phone. Newest first.
How to release: `docs/setup_manual.md`, Phase 6.
Version format: `MAJOR.MINOR.PATCH` (see `pubspec.yaml`).

## 1.1.0 — 2026-09-20

- **Flashcards both ways:** new toggle boxes on the flashcard screen: *Hard only*, *Character → Definition*, *Definition → Character*. With both directions on, each card is asked a random way. Definition → Character shows the typed character and your drawing as the answer.
- **Definition is now required** when adding a character (and can't be emptied when editing).
- **Undo / clear while drawing:** the drawing box has an Undo button (removes the last stroke) and a Clear button (removes everything), so a mistake no longer means saving and redrawing.
- **Shorter "back" history:** tapping a referenced character now replaces the current character screen instead of stacking a new one. Back always returns to the list.

## 1.0.0 — 2026-09-19 (first release)

- **Storage moved to SQLite + Drift.** Faster saves, proper tables for tags, references and (future) photos. See `docs/decisions_log_sqlite_drift.md`.
- **New Settings screen** (gear icon on the home screen) with:
  - **Back up**: saves everything to one `.zip` file wherever you choose (Downloads, Google Drive, …).
  - **Restore**: replaces all data with a backup, after saving an automatic safety copy.
  - **Undo last restore**.
- **Removed** the readable JSON export (replaced by backups).
- First build signed with your own release key.

## 0.1.0 — 2026-07-23 (development only, never released)

- First version: dictionary list, character detail, add character with handwriting, star/hard/archive, references, flashcards, JSON export. Installed as a debug build only.
