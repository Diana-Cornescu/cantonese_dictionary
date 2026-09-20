# Changelog

What changed in each release installed on the phone. Newest first.
How to release: `docs/setup_manual.md`, Phase 6.
Version format: `MAJOR.MINOR.PATCH` (see `pubspec.yaml`).

## 1.2.0 — 2026-09-20

- **Photos:** add photos of characters seen out and about, by camera or from your phone's gallery. One photo can be linked to several characters and have a note. They show in a new **Photos** row on each character's screen and in a new **gallery** (🖼 on the home screen). Photos are included in backups.
  - In the gallery: names are comma-separated, and you can filter by **Unlinked only** or search by character, definition, tag or note.
  - On a photo: tap a linked character to open it (Back returns to the photo). The **+** button changes which characters are linked.
- **Flashcards:** the character side now always shows your drawing under the typed character, in both directions.
- **Flashcards:** the Back button became **Go to character screen**, shown after you reveal the card. It opens the current card's character, and Back returns to the same card.
- **Photos gallery:** a Home button at the top right.
- **Hard icon:** the "hard" flag is now a red 🔥 fire icon (was "!").
- **Flashcard options redesigned:** two matching dropdowns: which cards (**All characters**, **Hard only**, **Favorites only**) and which way (**Character → Definition**, **Definition → Character**, **Bidirectional**, a random direction per card).
- **Side menu:** a ☰ menu on the home screen replaces the row of top-bar icons, with Flashcards, Photos, Archive and Settings.

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
