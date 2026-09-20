# Backlog

**Last updated:** 2026-09-20

What's still to do, in priority order. This is the single place to check "what's next". Detailed reasoning lives in the decision logs; this file only tracks what's left and how important it is.

**Priority:** lower number = sooner. Work top to bottom.

---

## Priority 1

_Nothing left. Everything below moves up._

## Priority 2

_Nothing left. Everything below moves up._

## Priority 3: next up

| Item | Notes | Source |
|------|-------|--------|
| **Photo gallery screens** | 🧪 **Code written 2026-09-20, to test.** First round of feedback also written: comma-separated names in the gallery; a + icon for changing characters; tappable linked characters (Back returns to the photo); gallery filters ("Unlinked only" plus a search by character, definition, tag or note). See `decisions_log_photo_gallery.md`. Photos of characters seen out and about, for font identification. **Decided 2026-09-20:** a Photos section on the character screen **plus** a gallery screen from home; add by **camera or phone gallery**; one photo can link to **several characters**; an optional **note** per photo (schema version 2). The app keeps its own resized **copy** (included in backups). Camera photos are **not** saved to the phone's gallery. | Personal_notes; `decisions_log_sqlite_drift.md` decision 5 |

## Priority 4

| Item | Notes | Source |
|------|-------|--------|
| **Delete several photos at once** | For tidying up stale unlinked photos: select several in the gallery and delete them together. For now, filter "Unlinked only" and delete one at a time from each photo's screen. | You, 2026-09-20 (suggested) |
| **Restyle flashcard stats as boxes** | Move below the definition. A centered "last reviewed" line, then a row of boxes (Seen, Accuracy), then a row of boxes (Correct, Incorrect). | Personal_notes |
| **Watch for a `file_picker` update (Kotlin warning)** | The build warns that `file_picker` uses the old Kotlin Gradle Plugin, and that future Flutter versions will refuse to build with it. Nothing's broken today. When a newer `file_picker` supports "Built-in Kotlin", run `flutter pub upgrade file_picker`. | Build output, 2026-09-20 |
| **Clean up "info" lint hints** | `use_build_context_synchronously` (character detail screen), deprecated `withOpacity` (theme), `prefer_const`. Harmless style hints. | `flutter analyze`, 2026-09-19 |

## Not prioritized yet

| Item | Notes | Source |
|------|-------|--------|
| **Setting: save camera photos to the phone's gallery** | A switch in Settings to also save photos taken in the app to the phone's gallery. **Default off** (today's behaviour: photos stay only in the app). Needs a small extra package and a stored setting (e.g. a settings table, so it's in backups). | You, 2026-09-20 |
| **Tag picker / managed tags UI** | Pick existing tags, rename once, filter by tag. The storage already exists. | `future_ideas.md`; decision 2 |
| **Handwriting recognition** | Designed and parked. | `future_ideas.md` |

---

## Removed

- **Remove the debug banner** (2026-09-19): not needed. The "DEBUG" corner banner only appears in debug builds, and release builds never show it. If it ever showed up in a release build, it would come back here as Priority 2.

## Done

- **Flashcards in both directions** (Priority 2, tested 2026-09-20): Hard only / Character → Definition / Definition → Character toggle boxes, random direction per card when both are on. The definition is now required. Goes out in 1.1.0.
- **Shorter "back" history, option A** (Priority 2, tested 2026-09-20): a reference replaces the character screen, so Back goes to the list. Goes out in 1.1.0.

- **Undo last stroke / clear drawing** (Priority 2, tested 2026-09-20): two small buttons in the top-right corner of every drawing box (Add character screen and the Redraw window). Before, a mistake meant finishing with "Done" and redrawing. Goes out in 1.1.0.

- **Released 1.0.0 to the phone** (2026-09-19): signed with your own key, installed locally, Back up/Restore checked on Android. Tagged `v1.0.0`.
- **Backup & restore + choosing where it's saved** (2026-09-19). Settings screen, one `.zip`, system Save/Open window. See `decisions_log_backup_and_release.md`.

- **Move storage to SQLite + Drift** (2026-09-19). See `decisions_log_sqlite_drift.md`.
- **Two rounds of UI edits** from Personal_notes (tags in the character screen, yellow star, colored accuracy, home button, hard-mode toggle, archive/delete moved, handwriting-only required, drawing clipped, SafeArea buttons). Done by 2026-07-23.
