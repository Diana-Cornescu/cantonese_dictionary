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

## 2026-09-20 — Side menu and "Go to character screen" in flashcards

- **Side menu:** the home screen now has a ☰ button at the top left that opens a side menu taking about 80% of the screen width (capped at 360 px on the laptop). It holds **Flashcards, Photos, Archive** and, after a divider, **Settings**. This replaces the row of four icons in the top bar, which was getting crowded and will have room for more entries later. The archive view keeps its back arrow and has no menu.
- **Flashcards, "Go to character screen":** replaces the old Back button under the card. It opens the current card's character screen, and **Back returns to the flashcards, on the same card**. Any edits made there show on the card when you return. If you deleted the character, the card is skipped. Leaving flashcards is still possible with the top-left back arrow or Home.

## 2026-09-20 — "Go to character screen" only after revealing; release 1.2.0

- The flashcard **Go to character screen** button now shows only once the card is revealed, together with Correct/Incorrect, so it can't give the answer away before you've guessed.
- The photo gallery got a Home button.
- Released as **1.2.0**: photo gallery, side menu, flashcard changes. See `CHANGELOG.md`.

## 2026-09-20 — Flashcard options: switch + dropdown

- **Change:** the three toggle chips on the flashcard screen were replaced, following your mock-up:
  - a two-part switch **Hard only | All cards**,
  - a divider,
  - a rounded dropdown (⇄ icon) with **Character → Definition**, **Definition → Character** and **Bidirectional**.
- **Behaviour is the same as before:** Bidirectional = both directions on, and each card picks one at random. Default on every open: **All cards + Character → Definition**. Changing either option reshuffles.
- **Simpler than before:** you can no longer end up with no direction selected, so the "Keep at least one direction on" message is gone.
- Part of **1.2.0**.

### Same day, revised

- **Divider removed.**
- The two-part "Hard only | All cards" switch went **back to a simple on/off "Hard mode" switch**.
- Both controls are now **matching outlined pills of the same height** (40 px): "Hard mode" with its switch, and the ⇄ direction dropdown.
- The direction dropdown no longer stays **highlighted in blue** after you choose an option (the focus highlight was removed).
- **Hard icon:** the "hard" flag on the list rows is now a **fire icon** 🔥, red and filled when on, an outline when off (it was "!"). The Hard mode pill in flashcards shows the same red fire icon.

### Same day, final version of the flashcard options

- The Hard mode switch became a **dropdown in the same style as the direction dropdown**: **All characters**, **Hard only** (🔥) or **Favorites only** (⭐, new). Its icon changes with the choice.
- Both dropdowns are identical outlined pills of the same height. Default on every open: **All characters + Character → Definition**.
- An empty Hard or Favorites list shows a hint and a "Show all characters instead" button.

## 2026-09-20 — Color themes (schema version 3)

- **Request:** choose the app's color in Settings instead of always blue, with many options, while keeping the colors that already have a meaning recognisable.
- **Colors that already mean something** (`lib/theme/app_colors.dart`): **red** = hard / incorrect / delete, **gold** = favorite / mid accuracy, **green** = correct / high accuracy.
- **Decision: 8 themes, all blues, teal, purples and a neutral:** Cerulean (the original, default), Cobalt, Teal, Navy, Iris, Violet, Plum, Slate.
  - Every theme's hue is **at least 45° away** on the color wheel from red, gold and green. A test (`test/app_palettes_test.dart`) checks this, so a future theme can't accidentally break it.
  - Teal was nudged towards blue (hue ~191°) for this reason.
  - Deliberately **no red, pink, orange, brown, yellow or green** themes.
- **How it looks:** Settings → **Color theme** shows a row of round swatches with a ✓ on the current one. Tapping one changes the whole app straight away: buttons, switches, the + button, highlights and text fields.
- **Where it's saved:** a new **`app_settings`** table (key/value) in the database. That's **schema version 3**, and existing data upgrades automatically. It's also included in backups, so a restore brings back your theme. The table can hold future settings too (e.g. the "save camera photos to gallery" idea in the backlog).
- **Side effect:** the theme code now uses `withValues(alpha: …)` instead of the deprecated `withOpacity`, which removes 5 of the old "info" hints.
- ⚠️ **Tables changed:** run `dart run build_runner build` before building.

## 2026-09-20 — Tags became a real feature (no schema change)

- The 2026-07-19 decision "tags stay free-text for v1, a managed tag list is parked" is now **superseded**. Tags have their own screen, a picker instead of a free-text field, and rename/merge/delete.
- **No tables changed** — the `tags` / `character_tags` tables from decision 2 already held everything; nothing had ever read the tag list as a whole. **No `build_runner` run needed.**
- Full reasoning in **`decisions_log_tags.md`**.

## 2026-09-20 — Photo and references while adding a character

- **Request:** the Add character screen should attach a photo and link references there and then, instead of saving first and editing afterwards.
- **The constraint:** both need the character's **id**, which SQLite only assigns on insert. A photo link is a `photo_characters` row and a reference is a `character_references` pair — neither can exist before the character does.
- **Decision: hold them in the screen's state, write them straight after the insert.** `addCharacter` returns the stored entry, so `_save` then calls `addReference` for each chosen character and `addPhoto` for the picked file.
- **Cancelling writes nothing.** In particular the photo is only the picker's temporary file until save, so backing out never leaves a stray copy in the app's photos folder.
- **References are symmetric** (they always have been), so one added here also appears on the other character's screen.
- The photo's **note** is not asked for here — it's one more field in the way of adding a character. Add it from the photo's own screen.

## 2026-09-20 — "Add character" moved into a fixed bottom bar

- **Problem:** the round **+** floated over the bottom-right corner of the home list, covering the last row's ⭐ and 🔥 buttons. A floating button assumes the list can scroll past it; this one couldn't, so the last character was permanently half-covered.
- **Decision:** the button became a **full-width bar pinned below the list** — the last child of the screen's `Column`, not a `floatingActionButton`. The list gets its own `Expanded` space and scrolls independently above it, so every row reaches the top of the bar and stops.
- **Why a bar and not just bottom padding on the list:** padding would have kept the aim-for-the-corner target and the "is there more below?" ambiguity. A labelled bar says what it does and is a bigger target on a phone.
- **Details:** it's a `Material` with elevation so rows scrolling under it get a shadow edge, inside a `SafeArea(top: false)` to clear the phone's gesture bar, and the button has a 48 px minimum height.
- **The archive view keeps no bar** — you don't add characters there.
- The photo gallery still uses a floating button. That one is fine: its grid already reserves 88 px of bottom padding to scroll past it.

## 2026-09-20 — 1.4.0 round

- **Star / hard on the character screen:** **Favorite** and **Hard** buttons placed **directly under the character box**, not in the top bar. In the body of a screen a bare icon doesn't say what it does, so they're outlined buttons with icon + label, styled like the Typed/Handwritten pair at the top of the same box and filling in when on. Same icons and colors as the list rows, and the same **instant, no-confirmation** behaviour — these two have been the app's one deliberate exception to "confirm before committing an edit" since 2026-07-19, because one more tap undoes them.
  - A `Wrap` rather than a `Row`, so on a narrow phone the two buttons stack instead of overflowing.
  - They are **flags on this character**, not filters. The ⭐/🔥 buttons by the home screen's search box are a different thing: those filter the list. Both were asked for in the same breath, so the distinction is written down here.
- **Home list filters:** ⭐ and 🔥 buttons to the **right of the search box**, filtering the list rather than flagging anything.
  - **Independent, not exclusive.** Both on means starred AND hard, and either combines with the text in the search box. Exclusive toggles were considered and dropped: "my hard favourites" is a list worth having, and nothing about the icons suggests they'd cancel each other.
  - **Showing that a filter is on** is the whole point of the feature, so an active button gets three signals at once: the filled/coloured icon, a `primaryContainer` background and a primary-coloured border. A colour tint alone reads as a hover state.
  - The empty-list message now distinguishes "nothing matches your filters" from "nothing here yet", which the old unconditional "No characters match." got wrong on a genuinely empty dictionary.
  - The same filters apply in the archive view, since it's the same screen.
- **Enter in the definition field:** the definition is now a **single-line** box in both places it's typed — the Add character screen and the character screen's edit dialog.
  - Single-line is what makes Enter work at all. A multi-line `TextField` gives the keyboard a newline key by definition; there is no "multi-line box where Enter submits". The choice was really "keep line breaks" or "keep Enter", and definitions are a line of English.
  - **Notes keep their multi-line box.** That's where longer writing belongs, and it's the reason losing line breaks in the definition costs nothing.
  - The two places behave slightly differently on purpose. In the **edit dialog** Enter *saves* (it then asks for confirmation like any other edit). On the **Add character screen** Enter only closes the keyboard — it deliberately does not press Save, because the drawing above may not be finished and Save is the single explicit commit for a new character.
  - `promptForText` gained the behaviour rather than each caller: `maxLines: 1` now also sets `textInputAction: done`, wires `onSubmitted`, and **flattens any line breaks to spaces on save**, so a definition written before this change doesn't keep invisible newlines once it's edited.
- **Flashcards: text only vs text + drawing:** a **third dropdown pill**, matching the two already there, choosing what the character side of a card shows.
  - **Why:** recognising your own handwriting is a way of cheating. It gets the card right without telling you anything about the same character printed on a menu, which is the thing the app is for.
  - **It hides the drawing on both sides** — question side in Character → Definition, answer side in Definition → Character. Hiding it on only one would move the crutch rather than remove it.
  - **Remembered between sessions**, unlike the other two pills, which reset to All characters / Character → Definition on every open. This one is a standing statement about how you want to be tested, not a per-session choice. Saved in the **`app_settings`** table added for color themes (2026-09-20), so it's in backups too. **No schema change** — that table is key/value and already exists.
  - Changing it does **not** reshuffle the pool, since nothing about which cards are in play changes.
  - The stored value is the enum constant's `name`, which makes a rename a silent data change: everyone's saved choice would stop matching and fall back to the default. `test/flashcard_face_test.dart` pins both strings and the settings key so that can't happen by accident.

## 2026-09-21 — The same filters in the photo gallery

- The gallery's search row now carries the **same three toggle buttons** as the home list: ⭐, 🔥 and unlinked. One visual language for "this list is filtered", on both screens.
- **"Unlinked only" stopped being a labelled chip** and became a **grey broken-link icon** (`Icons.link_off`) in the same style as the other two. It was the odd one out — a different shape, a different way of showing its state — for no reason other than being older.
- **What starred and hard mean for a photo:** a photo has no flags of its own, so they mean **linked to at least one character that is**. Combining either with unlinked matches nothing, which is correct rather than broken: an unlinked photo has no characters to be starred.
- **The unlinked button has no color of its own.** Red, gold and green already mean hard, favorite and correct; "unlinked" isn't a fourth meaning worth minting a color for, so it shows its state with the filled background and border alone.
- **The button moved to `lib/widgets/filter_icon_button.dart`.** It was a private helper on the home list; two screens now need it, so it followed the same path `character_picker_dialog.dart` took when the Tags screen started sharing it.
- `offIcon` is optional there: a star has a filled and an outlined form, a broken link has only one shape.
- **Unlinked is exclusive with starred and hard, and the buttons enforce it** (2026-09-21). Turning on unlinked switches the other two off and clears the search box; turning on either of those switches unlinked off. The alternative — letting you select a combination that can only ever show an empty grid, then showing "No photos match." — is a puzzle, not an answer. Clearing the search box too is because "show me the loose ends" is a fresh question, not a narrowing of the previous one.
- **An ✕ in every search box** (`lib/widgets/clear_text_button.dart`, 2026-09-21): the home list, the photo gallery, the Tags screen and both pickers. It returns null while the field is empty, so the ✕ appears only when there's something to clear rather than sitting there permanently dead. It's sized down from the default 48 px tap target, which would otherwise stretch an `isDense: true` field taller than the filter buttons next to it.
