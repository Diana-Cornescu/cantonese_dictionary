# Changelog

What changed in each release installed on the phone. Newest first.
How to release: `docs/setup_manual.md`, Phase 6.
Version format: `MAJOR.MINOR.PATCH` (see `pubspec.yaml`).

## 1.3.0 — 2026-09-20

- **Add a photo and references while adding a character.** The Add character screen now has **Photo** and **References** sections next to Tags, so a new character can arrive complete instead of needing a second pass to edit it. Cancelling writes nothing at all.
- **Tags have their own screen.** **Tags** in the ☰ side menu lists every tag with how many characters carry it. Tags nobody uses any more are shown greyed at "0 characters" rather than hidden, so a typo'd tag is findable instead of stuck in the database.
  - Tap a tag for its own screen: the characters that have it (tap one to open it), **Add or remove characters** in a single checklist like the one the photo screen uses, **rename**, and **delete**.
  - **Renaming onto a tag that already exists merges the two** (it asks first). That's the fix for ending up with both "food" and "Food".
  - Deleting a tag removes it from every character; the characters themselves are kept.
  - **+** makes an empty tag and opens it, so you can create one and fill it afterwards.
- **Tags are now picked, not typed.** On the Add character screen and on a character's screen, the comma-separated text box is replaced by a picker: tick the tags that already exist, or type a new one to create it. A tag can no longer contain a comma, which would have silently split it in two.
- **Tag chips open their tag.** Tapping a tag on a character's screen opens that tag's list, the same way a photo's linked characters open theirs.
- **Photos**: move delete button and add a unlink all button.
  - **Delete photo** left the top bar, where it sat right next to **Home** and was easy to hit by mistake. It's now a labelled button at the bottom of the photo screen, below the linked characters.
  - **Unlink all** sits next to it: it drops every character link but keeps the photo, which then turns up under the gallery's "Unlinked only" filter.

## 1.2.0 — 2026-09-20

- **Photos:** add photos of characters seen out and about, by camera or from your phone's gallery. One photo can be linked to several characters and have a note. They show in a new **Photos** row on each character's screen and in a new **gallery** (🖼 on the home screen). Photos are included in backups.
  - In the gallery: names are comma-separated, and you can filter by **Unlinked only** or search by character, definition, tag or note.
  - On a photo: tap a linked character to open it (Back returns to the photo). The **+** button changes which characters are linked.
- **Flashcards:** the character side now always shows your drawing under the typed character, in both directions.
- **Flashcards:** the Back button became **Go to character screen**, shown after you reveal the card. It opens the current card's character, and Back returns to the same card.
- **Photos gallery:** a Home button at the top right.
- **Color themes:** Settings → Color theme lets you pick from 8 colors: Cerulean (default), Cobalt, Teal, Navy, Iris, Violet, Plum, Slate. None of them can be mistaken for the red (hard), gold (favorite) or green (correct) that already mean something. The choice is included in backups. (Database schema version 3.)
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
