# Writing practice (the Write tab)

**Decided 2026-09-25. Built for 1.7.0.** Code:
`features/write/write_practice_screen.dart`, `data/stroke_reference.dart`,
`widgets/reference_glyph_painter.dart`.

---

## TL;DR

- **What:** a card shows a definition. You write the character in a square
  box with a faint 米字格 guide, then tap **Check**. The correct form
  appears in pale grey under your ink. **Try again** or **Next**.
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
| 2 | Checking | **Overlay only: your ink on top of the correct form.** No score. | Try it and iterate first. A score (and a per-character statistic to track it) is a later option, see the roadmap. |
| 3 | Where it lives | **Its own tab, in Tags' slot.** Tags becomes a row in Settings for now. | A fifth tab would break the bar's two-and-two symmetry around the round button. Tags is used far less than the other tabs. Its permanent home is on the roadmap. |
| 4 | Round button on Write | **…**, opening a panel: All / Hard / Favorites. | Same as Flashcards. The choice isn't saved: each app start begins with All characters. |
| 5 | Several characters in one entry (时间) | **Written one at a time in the same box**, "Character 1 of 2", each with its own Check. | Checking each as you go is simpler than holding several drawings and revealing them together. |
| 6 | Characters the data doesn't have | **Skipped**, and listed in the options panel. Also skipped: entries with no typed text, and entries with no definition (the definition is the prompt). | Many Cantonese-only characters aren't in the data (see below). Listing them doubles as the coverage check on your real dictionary. |
| 7 | Storage format | **One packed binary file, `assets/stroke_reference.bin` (~12 MB, ~8.5 MB inside the APK), held in memory once the Write tab opens.** Not SQLite, not in the dictionary database. | The data is read-only and looked up one character at a time, so a sorted index plus packed glyphs is all it needs. It's the same approach as `StrokeCodec`. Keeping it out of `AppDatabase` means no schema change, and **backups don't carry 12 MB of fixed data**. |
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
