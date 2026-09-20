# Decisions Log — Photo Gallery

**Started:** 2026-09-20
**Status:** First version tried on the laptop 2026-09-20. The feedback round (below) is written and still to test.

This file is separate from the other decision logs on purpose, so these decisions are easy to find. Add a new dated section whenever a decision here changes.

---

## TL;DR

- **Why:** photos of characters seen out and about (signs, menus…) help recognise different fonts and handwriting styles.
- **Where:** a **Photos** row on each character's screen, plus a **gallery screen** (🖼 icon on the home screen) showing every photo.
- **Adding:** on the phone, **take a photo** or **choose from the gallery**. On the laptop, choose an image file.
- **One photo can show several characters.** Link and unlink them from the photo's screen.
- **Optional note** per photo, e.g. "menu at Tim Ho Wan".
- **The app keeps its own copy** of every photo, resized to at most 1600 px. The original stays in your phone's gallery, untouched. Camera photos are **not** saved to the phone's gallery.
- **Backups include the photo files** themselves, not references.
- **Database schema version 2.** Existing data is upgraded automatically.

---

## Decisions

| # | Topic | Decision | Why |
|---|-------|----------|-----|
| 1 | Where photos show | **Character screen (Photos row) + a gallery screen** from home. | See a character's photos where you study it, and browse all photos in one place. |
| 2 | How to add | **Camera or phone gallery** (phone), image file (laptop). | Both real-life situations: snap it now, or add one taken earlier. |
| 3 | One photo, several characters | **Yes**, many-to-many: new `photos` + `photo_characters` tables. | A sign usually shows several characters. Store the photo once and link it to each. |
| 4 | Note per photo | **Yes, optional.** | Remember where or when you saw it. |
| 5 | Copy or reference | **Copy**, resized to ≤1600 px, JPEG quality 85 (about 200–400 KB). | A reference would break if the original was deleted, and couldn't go into a backup. Resizing keeps the app and backups small. |
| 6 | Camera photos → phone gallery | **Not saved there.** A Settings switch for it is in the backlog (not prioritised, default off). | Your choice: photos stay in the app only. |
| 7 | Deleting a character | Its photos are **kept** (only unlinked) and still show in the gallery. Delete a photo explicitly from its screen. | A photo may show other characters too, so nothing is lost by accident. |

---

## How it works (implementation, 2026-09-20)

**Database (schema version 1 → 2):**
- New `photos` table: id, file_name (only the name, not a full path), note, created_at.
- New `photo_characters` table: photo_id, character_id (many-to-many).
- The old `character_photos` table (one photo, one character) is removed. The upgrade step copies any rows over first. In practice it was always empty, since v1 had no way to add photos.
- The upgrade runs automatically the first time the new app opens an old database, **including when you restore an older backup**.
- **The generated code must be recreated:** run `dart run build_runner build`.

**Code:**
- `lib/data/app_database.dart`: new tables, the upgrade step, and photo query helpers. `deleteCharacter` now only unlinks photos.
- `lib/data/photo_entry.dart` (new): the photo model.
- `lib/data/dictionary_store.dart`: photos load with everything else. New `photos`, `photosFor()`, `addPhoto()` (copies the file into the app's `photos` folder), `updatePhotoNote()`, `setPhotoCharacters()` and `deletePhoto()` (also deletes the file).
- `lib/features/photos/` (new):
  - `gallery_screen.dart`: a grid of all photos, with a + button.
  - `photo_viewer_screen.dart`: the full photo (zoomable), date, note, and linked characters, with edit and delete.
  - `photo_picking.dart`: camera/gallery choice on the phone, file window on the laptop.
  - `character_picker_dialog.dart`: a searchable checklist of characters.
  - `photo_image.dart`: shows a stored photo.
- Character screen: a new **Photos** section at the end, with thumbnails and a ➕ tile. A new photo there is linked to that character.
- Home screen: a new 🖼 **Photos** icon.
- **New package:** `image_picker` (camera and phone gallery).
- **Tests:**
  - `test/photo_store_test.dart`: add (copy + several characters) survives a reload; edit note and links; deleting a character keeps the photo; deleting a photo removes the file; a real **v1 → v2 upgrade**.
  - `test/backup_service_test.dart`: photos are included in a backup and restored.

### Where photos are stored
| | Windows (laptop) | Android |
|---|---|---|
| Photo files | `local_data\photos\` | app-private storage |
| In backups | yes, in the zip's `photos/` folder | yes |

---

## 2026-09-20 — First feedback round

- **Gallery labels:** the characters under a photo are separated by **commas**, and a long list ends with "…".
- **Photo screen:**
  - The button for changing linked characters is now a **+** instead of a link icon.
  - Linked characters are **tappable** and open that character's screen. **Back returns to the photo.** This fell out naturally, since the character screen simply opens on top of the photo.
- **Gallery filters:**
  - An **"Unlinked only"** box shows photos with no character, e.g. to tidy up stale ones.
  - A **search box** matches the linked characters' typed character, definition or tags, or the photo's note.
  - Both work together.
- **Not done yet:** deleting several photos at once. It's in the backlog (Priority 4). For now, delete from each photo's screen.
