# Roadmap

**Everything still ahead, in the order it's likely to happen.** Nothing that
already shipped lives here — `CHANGELOG.md` is the history, and the decision
logs hold the reasoning.

### How this file works

- **An item lives in exactly one section.** If it's in two places, one is wrong.
- **"Next up" is capped at four.** If a fifth matters more, something moves
  down. A list of twenty things is a list of nothing.
- **Nothing is numbered.** Promoting an item means moving it up a heading,
  not renumbering the file.
- **When a release ships, delete its items from here.** They're in the
  changelog.
- **New ideas go straight to Inbox, unsorted.** Triage later; don't let
  "where does this go" stop you writing it down.

---

## Next up — 1.6.0

_Draft. Move things in and out freely — that's the point of the cap._

| | What | Why now |
|---|------|---------|
| **Flashcard stats as boxes** | Move below the definition. A centered "last reviewed" line, then a row of boxes (Seen, Accuracy), then a row of boxes (Correct, Incorrect). | Asked for twice in `Personal_notes.md` and still not done. The only item on this list you've requested more than once. |
| **Filter by tag** | On the home list and in the photo gallery. Needs a picker rather than one more toggle, since there can be any number of tags. The Tags screen already lists a tag's characters, so this is about filtering *in place* rather than navigating away. | Finishes the filter row started in 1.4.0 — ⭐ and 🔥 are done on both screens, tag is the obvious gap. |
| **Delete several photos at once** | Select several in the gallery and delete them together. Today: filter to unlinked and delete one at a time from each photo's screen. | The unlinked filter exists to find stale photos; there's no way to act on what it finds. |
| **Narrow the app-wide rebuild in `main.dart`** | See **Chores** for the full context. | Not user-facing, but it's the one known source of fragility, and it caused a real bug during the tags round. Promote it if 1.6.0 has room. |

---

## After that

Real features, not yet scheduled.

| What | Notes |
|------|-------|
| **Dark mode** | A dark theme for the whole app, alongside the 8 color themes in Settings. |
| **Save camera photos to the phone's gallery** | A switch in Settings. **Default off** (today: photos stay only in the app). Needs a small extra package; the setting goes in the `app_settings` table. |
| **Practice reminder notifications** | A scheduled nudge to do a flashcard round. Needs a notifications package and Android permission handling. |
| **Jyutping / romanization field** | One more field per character. Never designed. |
| **Batch import** | Add many characters at once, e.g. from a spreadsheet. Characters are one-at-a-time today. |

---

## Someday / big

Each of these is a project, not an afternoon.

| What | Notes |
|------|-------|
| **Handwriting recognition** | Fully designed and parked. Self-learning template matching against your own saved drawings — no internet, no bundled model. The complete write-up, including the data-model implication, is in **`future_ideas.md`**. |
| **Audio pronunciation** | Record and play back a character. Never designed. |
| **Stroke-order playback** | The data is already being captured — the handwriting model records a timestamp per point precisely so this could be added later without changing what's stored. |
| **Backup merging, or a "last backed up N days ago" nudge** | Restore replaces everything today; merging two dictionaries is a different and much harder job. |
| **Draggable divider between the character and translation windows** | Deliberately deferred until real usage showed what was worth making resizable. It still hasn't. |
| **Live database queries instead of loading everything into memory** | `DictionaryStore` still loads every character at startup and filters in Dart. Fine at personal scale. `limitations_and_roadmap.md` lists the three things that would make this worth doing. |

---

## Chores

No user-facing value. Do them when something else is blocked, or when one starts biting.

| What | Notes |
|------|-------|
| **Narrow the app-wide rebuild in `main.dart`** | `main.dart` wraps the entire `MaterialApp` in `ListenableBuilder(listenable: store)`, done for color themes (2026-09-20) so a new palette applies instantly. Side effect: **every** `notifyListeners()` — any save, any tag edit, a restore — rebuilds the whole app including the `Navigator` and its overlay. Nothing looks wrong, but a rebuild landing while a dialog is animating out is what turned one disposed `TextEditingController` into a ten-exception cascade during the tags round (see "Bugs found while testing" in `decisions_log_tags.md`). **Fix:** let `MaterialApp` listen only to the theme — a small `ValueNotifier<String>` for the palette id, or an `InheritedWidget` — and leave each screen listening to the store as they already do. **Check it worked:** Settings → Color theme still recolors instantly, a restore still repaints, every screen still updates. |
| **Watch for a `file_picker` update** | The build warns it uses the old Kotlin Gradle Plugin and that future Flutter versions will refuse to build with it. Nothing's broken today. When a newer `file_picker` supports "Built-in Kotlin": `flutter pub upgrade file_picker`. |
| **Clean up "info" lint hints** | `use_build_context_synchronously` (character detail screen), `prefer_const`. Harmless. |

---

## Inbox

Captured, not yet triaged. Move things out of here rather than answering them in place.

_Empty._
