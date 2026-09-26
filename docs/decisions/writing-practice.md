# Writing practice (the Write tab)

**Decided 2026-09-25; X-ray added 2026-09-26. Shipped in 1.7.0.** Code:
`features/write/write_practice_screen.dart`, `data/stroke_reference.dart`,
`widgets/reference_glyph_painter.dart`.

---

## TL;DR

- **What:** a card shows a definition, always visible right above a
  square box with a faint 米字格 guide and the character's **X-ray**. You
  write over it, then **Next**. The stroke to write next is highlighted.
  An 👁 button hides the X-ray to try from memory, and shows it again to
  check.
- **The X-ray:** each stroke's outline in pale grey, its centre line with
  an arrowhead for the direction, and a numbered badge on the line for
  the stroke order.
- **No scoring, nothing saved.** The first version is for seeing how it
  feels. Flashcard stats aren't touched.
- **The reference is open stroke data bundled in the app**, not your own
  drawings.
- **Where:** a **Write** tab in the bar, in the slot Tags had. Tags moved
  into Settings as a stopgap.

---

## Decisions

| # | Topic | Decision | Why |
|---|-------|----------|-----|
| 1 | What to check against | **Make Me a Hanzi's `graphics.txt`**, bundled. | Your own drawing is one sample, only as good as the day you drew it. Checking against it measures consistency with yourself, not correctness (the same reason Flashcards has **Text only**). The dataset covers any character you've typed, drawn or not. |
| 2 | Checking | **Overlay only: your ink on top of the X-ray.** No score. | Try it and iterate first. A score (and a per-character statistic to track it) is a later option, see the roadmap. |
| 2a | One mode, not two (2026-09-26) | **Write over the X-ray, with an eye button to hide it.** A separate Memory mode (write from a blank box, then Check) was built and removed the same night; its code is in `archive/write-memory-mode.md`. | Hiding the X-ray, writing, then showing it does what Memory mode did, without a mode to pick. |
| 2b | Stroke order and direction (2026-09-26) | **From the dataset's centre lines ("medians")**, which run from where the pen goes down to where it lifts, in stroke order. Drawn as a line with an arrowhead at the end and a number badge **on the line itself**, a short way in from the start. | Checked on real glyphs (一 left to right; 人's 丿 then ㇏) and pinned in `test/stroke_reference_test.dart`. The first version put the badge just *before* the start, off the line, and it was hard to tell which number went with which line where strokes share a start (目's top-left corner) or cross (中). On the line, a badge plainly belongs to it; if two would still touch, the later one slides further along its own stroke. |
| 2c | Next-stroke highlight (2026-09-26) | **Only the next stroke to write is in blue**; the others' lines, arrows and badges are grey. It advances each time you lift the pen, undo steps it back, and when every stroke is done all turn blue again. | Removes the need to match numbers to lines while writing. It counts pen-lifts, so a stroke drawn in two pieces moves it on twice; undo fixes that. |
| 2d | Hide / Show X-ray (2026-09-26) | **An eye button next to Next** turns the X-ray off and on. Keeps what's written; carries over between cards; not saved. | Try a character from memory, then show the X-ray to check. Not saved: it's a moment-to-moment choice. |
| 3 | Where it lives | **Its own tab, in Tags' slot.** Tags becomes a row in Settings for now. | A fifth tab would break the bar's two-and-two symmetry around the round button. Tags is used far less than the other tabs. Its permanent home is on the roadmap. |
| 4 | Round button on Write | **…**, opening a panel: All / Hard / Favorites. | Same as Flashcards. The choice isn't saved: each app start begins with All characters. |
| 5 | Several characters in one entry (时间) | **Written one at a time in the same box**, "character 1 of 2", with **Next character** between them. | One reference at a time keeps the box readable. |
| 6 | Characters the data doesn't have | **Skipped**, and listed in the options panel. Also skipped: entries with no typed text, and entries with no definition (the definition is the prompt). | Many Cantonese-only characters aren't in the data (see below). Listing them doubles as the coverage check on your real dictionary. |
| 7 | Storage format | **One packed binary file, `assets/stroke_reference.bin` (~15 MB with the centre lines, ~10.7 MB inside the APK), held in memory once the Write tab opens.** Format version 2 since the centre lines went in; the reader only accepts the version it was built for, since the file ships with the app. Not SQLite, not in the dictionary database. | The data is read-only and looked up one character at a time, so a sorted index plus packed glyphs is all it needs. It's the same approach as `StrokeCodec`. Keeping it out of `AppDatabase` means no schema change, and **backups don't carry 15 MB of fixed data**. |
| 8 | Build tool | **`tool/build_stroke_reference.py`** (Python 3, dev-only). | It was written in a workspace without the Dart SDK, and it's the script that actually produced the committed file. `test/stroke_reference_test.dart` checks the Dart reader agrees with it on real glyphs. |
| 9 | Licence | **Only `graphics.txt`** (Arphic Public License). The licence text is bundled and shown under **Settings → Licences**. `dictionary.txt` (LGPL) isn't used. | The licence requires the text to travel with the data. |

---

## Coverage, measured 2026-09-25

- **9,574 characters**, common simplified and traditional.
- **Everything in the laptop dictionary is covered**, including 时间 and 森林.
- **14 of 35 everyday Cantonese-only characters are missing:** 咗 冇 佢 啲
  噉 咁 攰 餸 嚟 喺 嗰 啱 揾 搵. They're skipped.
- **Shapes and stroke order follow mainland conventions**, in a Kai (brush)
  style. That doesn't matter while the app only compares shapes, but it
  would matter for stroke-order playback or scoring. Hong Kong's standard
  differs for some characters.

## Traps

- **The dataset's y axis points up.** The grid is 1024 × 1024 with its top
  edge at y = 900 and its bottom at y = −124. `StrokeReference.toBox` does
  the conversion; don't flip it anywhere else.
- **The X-ray colors sit on the paper, not the page**, so they're fixed
  roles (`strokeOrder`, `referenceInk`) that are the same in light and
  dark mode, like the ink.
- **The box must be square, and the same size while you write and when you
  check.** Your strokes are stored in box pixels and never rescaled.
- **No scroll view around the box.** A scroll view would fight the pen for
  vertical drags, so the Write screen sizes the box to fit instead.
- **The canvas keeps its own copy of the strokes**, taken when it's
  created. The Write screen gives it a new `Key` whenever it should start
  over or switch to showing the checked result.

## Rebuilding the data

Only needed if the source data or the file layout changes. Download
`graphics.txt` from https://github.com/skishore/makemeahanzi, then from the
project folder:

    python tool/build_stroke_reference.py path/to/graphics.txt

If the layout changes, bump the version byte in both the script and
`StrokeReference.formatVersion`.
