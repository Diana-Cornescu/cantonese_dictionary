# Backlog

**Last updated:** 2026-09-20

What's still to do, in priority order. This is the single place to check "what's next". Detailed reasoning lives in the decision logs; this file only tracks what's left and how important it is.

**Priority:** lower number = sooner. Work top to bottom.

---

## Priority 1

_Nothing left. Everything below moves up._

## Priority 2

_Nothing left. Everything below moves up._

## Priority 3

_Nothing left. Everything below moves up._

## Priority 4

| Item | Notes | Source |
|------|-------|--------|
| **Delete several photos at once** | For tidying up stale unlinked photos: select several in the gallery and delete them together. For now, filter "Unlinked only" and delete one at a time from each photo's screen. | You, 2026-09-20 (suggested) |
| **Restyle flashcard stats as boxes** | Move below the definition. A centered "last reviewed" line, then a row of boxes (Seen, Accuracy), then a row of boxes (Correct, Incorrect). | Personal_notes |
| **Add filter icons to the photo gallery** | Hard / starred / tag filters in the gallery, alongside the existing "Unlinked only" box. The **home screen half is done** (⭐/🔥 right of the search box, 1.4.0); filtering by **tag** is still to do on either screen. |  You, 2026-09-20 (suggested) |
| **Enter in the definition field saves and closes the keyboard** | Pressing Enter while typing a definition should dismiss the keyboard and save, instead of adding a newline. | You, 2026-09-20 (phone note) |
| **Flashcards: toggle text-only vs text + handwriting** | A switch for whether the character side shows only the typed character or the drawing too. Recognising your own handwriting is a way of cheating — it doesn't generalise to characters seen in the wild. | You, 2026-09-20 (phone note) |
| **Narrow the app-wide rebuild in `main.dart`** | **Context for a fresh session:** `main.dart` wraps the entire `MaterialApp` in `ListenableBuilder(listenable: store)`. That was done for color themes (2026-09-20) so a new palette applies instantly. The side effect is that **every** `notifyListeners()` on `DictionaryStore` — any character save, any tag edit, a restore — rebuilds the whole app including the `Navigator` and its overlay. Nothing is visibly wrong, but it makes the app fragile: a rebuild landing while a dialog route is still animating out is what turned one disposed `TextEditingController` into a ten-exception cascade during the tags testing round (duplicate GlobalKeys, detached render boxes, overlay assertions — see "Bugs found while testing" in `decisions_log_tags.md`). It also means a loop of saves repaints the app once per item. **Fix:** let `MaterialApp` listen only to the theme — a small `ValueNotifier<String>` for the palette id, or read it from an `InheritedWidget` — and leave each screen listening to the store as they already do. **How to check it worked:** Settings → Color theme still recolors the whole app immediately, restoring a backup still repaints, and every screen still updates on a change. | 2026-09-20 debugging session |
| **Watch for a `file_picker` update (Kotlin warning)** | The build warns that `file_picker` uses the old Kotlin Gradle Plugin, and that future Flutter versions will refuse to build with it. Nothing's broken today. When a newer `file_picker` supports "Built-in Kotlin", run `flutter pub upgrade file_picker`. | Build output, 2026-09-20 |
| **Clean up "info" lint hints** | `use_build_context_synchronously` (character detail screen), `prefer_const`. (The `withOpacity` ones were fixed with the color themes, 2026-09-20.) Harmless style hints. | `flutter analyze`, 2026-09-19 |

## Priority 5

| Item | Notes | Source |
|------|-------|--------|
| **Dark mode** | A dark theme for the whole app, alongside the 8 color themes already in Settings. | You, 2026-09-20 (phone note) |

## Priority 6

| Item | Notes | Source |
|------|-------|--------|
| **Reminder notifications to practice** | A scheduled notification nudging you to do a flashcard round. Needs a notifications package and Android permission handling. | You, 2026-09-20 (phone note) |

## Not prioritized yet

| Item | Notes | Source |
|------|-------|--------|
| **Setting: save camera photos to the phone's gallery** | A switch in Settings to also save photos taken in the app to the phone's gallery. **Default off** (today's behaviour: photos stay only in the app). Needs a small extra package. The setting itself can go in the `app_settings` table (added 2026-09-20 for color themes). | You, 2026-09-20 |
| **Handwriting recognition** | Designed and parked. | `future_ideas.md` |

---

## Removed

- **Remove the debug banner** (2026-09-19): not needed. The "DEBUG" corner banner only appears in debug builds, and release builds never show it. If it ever showed up in a release build, it would come back here as Priority 2.

## Done

- **Filter the home list by favorite / hard** (Priority 4, 2026-09-20): ⭐ and 🔥 toggle buttons right of the search box, independent of each other and combining with the search text. Active ones fill in with a tinted background and coloured icon. The photo gallery and tag filtering are still open — see the remaining Priority 4 row. Goes out in 1.4.0.

- **Star / hard from the character screen** (Priority 4, 2026-09-20): **Favorite** and **Hard** buttons directly under the character box, styled like the Typed/Handwritten pair, with the same icons, colors and instant behaviour as the list rows. Goes out in 1.4.0.

- **"Add character" in a fixed bottom bar** (Priority 3, 2026-09-20): the floating round button in the corner became a full-width **Add character** bar pinned under the list, so it no longer covers the last row's star and fire icons. The list scrolls in its own space above it. The archive view has no bar. Not released yet.

- **Photo + references while adding a character** (Priority 3, 2026-09-20): the Add character screen now has **Photo** and **References** sections alongside Tags. Both need the character's id, so they're held in the screen's state and written straight after `addCharacter` returns — cancelling writes nothing, not even a stray photo copy. See `decisions_log.md`. Not released yet.

- **Tags screen / managed tags** (Priority 3, 2026-09-20): **Tags** in the ☰ side menu — every tag with its character count, orphans greyed at 0. A tag's own screen lists its characters, adds or removes them in one checklist, renames (merging if the name exists) and deletes. Tags are now chosen with a picker on the Add and character screens instead of typed as free text, and tag chips open the tag. No database change. See `decisions_log_tags.md`. Not released yet.

- **Photo delete button moved away from Home** (Priority 4, 2026-09-20): on a photo's screen, **Delete photo** left the app bar and became a labelled button at the bottom, below the linked characters, next to a new **Unlink all** button. The app bar now holds only Home. See `decisions_log_photo_gallery.md`. Not released yet.

- **Released 1.2.0** (2026-09-20): photo gallery (with feedback round), side menu, "Go to character screen" in flashcards (shown after revealing), drawing on both flashcard sides, a Home button in the gallery, redesigned flashcard options (card dropdown: All / Hard only / Favorites only; direction dropdown with Bidirectional), 🔥 fire icon for hard, color themes in Settings (8 palettes, schema version 3).

- **Flashcards in both directions** (Priority 2, tested 2026-09-20): Hard only / Character → Definition / Definition → Character toggle boxes, random direction per card when both are on. The definition is now required. Goes out in 1.1.0.
- **Shorter "back" history, option A** (Priority 2, tested 2026-09-20): a reference replaces the character screen, so Back goes to the list. Goes out in 1.1.0.

- **Undo last stroke / clear drawing** (Priority 2, tested 2026-09-20): two small buttons in the top-right corner of every drawing box (Add character screen and the Redraw window). Before, a mistake meant finishing with "Done" and redrawing. Goes out in 1.1.0.

- **Released 1.0.0 to the phone** (2026-09-19): signed with your own key, installed locally, Back up/Restore checked on Android. Tagged `v1.0.0`.
- **Backup & restore + choosing where it's saved** (2026-09-19). Settings screen, one `.zip`, system Save/Open window. See `decisions_log_backup_and_release.md`.

- **Move storage to SQLite + Drift** (2026-09-19). See `decisions_log_sqlite_drift.md`.
- **Two rounds of UI edits** from Personal_notes (tags in the character screen, yellow star, colored accuracy, home button, hard-mode toggle, archive/delete moved, handwriting-only required, drawing clipped, SafeArea buttons). Done by 2026-07-23.
