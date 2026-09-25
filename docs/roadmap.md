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

**What's *true today*, rather than planned, is in `known_limitations.md`.**

---

## Next up — 1.6.0

_Draft. Move things in and out freely — that's the point of the cap._

| | What | Why now |
|---|------|---------|
| **Add date-added field** | Date character added when new characters added, defaults to today. Not editable after character creation. | Should be added sooner than later. |
| **Filter icon** | On the home list and in the photo gallery. Needs a picker with a typical filter icon. This way can filter for the Star, Fire, and as well as sort by Oldest, most Recent, and Clear filters.| . |
| **Change Navigation Method** | Match Instagrams navigation bar at the bottom to get to all the relevent tabs, and the center button to be slightly enlaged, rounded icon. The Icon would be + for all of the tags, photos, character screen -> which would trigger the add X feature, or ... for Flashcard screen, that would bring up the setting options in the flashcard. will also move the Gog wheel to the top right where the Home button currently is and move archive within the setting screen.. | Annoying to navigate.|
| **Dark mode** | A dark theme for the whole app, alongside the 8 color themes in Settings. | too bright at night |

---

## After that

Real features, not yet scheduled.

| What | Notes |
|------|-------|
| **Flashcard stats as boxes** | Move below the definition. A centered "last reviewed" line, then a row of boxes (Seen, Accuracy), then a row of boxes (Correct, Incorrect). |
| **Save camera photos to the phone's gallery** | A switch in Settings. **Default off** (today: photos stay only in the app). Needs a small extra package; the setting goes in the `app_settings` table. |
| **Delete several photos at once** | Select several in the gallery and delete them together. Today: filter to unlinked and delete one at a time from each photo's screen. The unlinked filter exists to find stale photos; there's no way to act on what it finds. |
| **Practice reminder notifications** | A scheduled nudge to do a flashcard round. Needs a notifications package and Android permission handling. |
| **Jyutping / romanization field** | One more field per character. Never designed. |
| **Batch import** | Add many characters at once, e.g. from a spreadsheet. Characters are one-at-a-time today. |

---

## Someday / big

Each of these is a project, not an afternoon.

| What | Notes |
|------|-------|
| **stroke writing character** | eventual stroke writing checker (but that will bring in the issue of it not being even - big new feature and location will need to be thought of). |
| **Handwriting recognition** | Fully designed and parked, 2026-07-19. The design is written out under the table below. |
| **Audio pronunciation** | Record and play back a character. Never designed. |
| **Stroke-order playback** | The data is already being captured — the handwriting model records a timestamp per point precisely so this could be added later without changing what's stored. |
| **Backup merging, or a "last backed up N days ago" nudge** | Restore replaces everything today; merging two dictionaries is a different and much harder job. |
| **Draggable divider between the character and translation windows** | Deliberately deferred until real usage showed what was worth making resizable. It still hasn't. |
| **Live database queries instead of loading everything into memory** | `DictionaryStore` still loads every character at startup and filters in Dart. Fine at personal scale. `known_limitations.md` lists the three things that would make this worth doing. |

### Handwriting recognition — the parked design

Kept here in full so picking it up doesn't mean re-deciding it. Parked
2026-07-19 as too much engineering for what it would add to a nearly-empty
dictionary.

**The idea.** With no internet and no bundled model, recognition works by
comparing a new drawing against the handwriting samples already stored for
*your own* characters. Nothing leaves the device. This fits the app's
self-building framing: a brand-new dictionary recognises almost nothing,
and accuracy grows as you add characters — entirely from your own data.

**How it would work.** Resample each stroke to a fixed number of evenly
spaced points and normalise the character to a fixed bounding box, so
drawings compare regardless of size, speed or position. Match with a
point-cloud approach in the spirit of the **$P recognizer**, which tolerates
strokes drawn in a different order or count from the stored sample — a real
concern for handwritten Chinese, where stroke order varies person to
person. The lowest-distance templates become the top-3 suggestions.

**Why it was parked.** It's a genuine algorithm to design and tune —
resampling, normalisation, distance scoring, and a sensible threshold for
"no good match". And it's least useful exactly when it's hardest to get
right: a new dictionary has nothing to compare against.

**The data-model implication, which is the easy thing to forget.** The app
stores **one** drawing per character, overwritten on every redraw, no
history. Recognition needs its own store of *one or more reference
templates* per character, separate from the single current drawing. That's
a schema change, not just a new screen.

**A refinement if revisited:** save an extra template each time a character
is redrawn correctly during recognition, so frequently-practised characters
keep getting easier to match instead of staying pinned to one original
sample.

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
