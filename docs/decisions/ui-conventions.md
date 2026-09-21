# UI conventions

**The rules that apply across every screen**, rescued from the old
chronological `decisions_log.md` when it was retired (2026-09-21). Feature
decisions live in their own file in this folder; this is the stuff that
would otherwise be re-decided screen by screen.

---

## Confirm before committing an edit

Editing a definition, notes or tags, and archiving or deleting anything,
all go through a confirmation dialog.

**Two deliberate exceptions: ⭐ favorite and 🔥 hard.** They're instant and
unconfirmed wherever they appear. The test is whether *one more tap undoes
it* — for these two it does, so a dialog would be friction with nothing on
the other side of it. Nothing else in the app passes that test.

## Three colors mean something

| Color | Meaning |
|---|---|
| **Red** (`AppColors.danger`) | hard, incorrect, destructive |
| **Gold** (`AppColors.star`) | favorite, mid-range accuracy |
| **Green** (`AppColors.success`) | correct, high accuracy |

They're applied **explicitly at the call site**, never through the general
theme, so they can't be swallowed by a palette change.

**Every color theme must sit at least 45° away on the color wheel from all
three.** `test/app_palettes_test.dart` enforces this, so a future theme
can't quietly break it. It's why there are no red, pink, orange, brown,
yellow or green themes, and why Teal was nudged toward blue.

## Two "selected" looks, on purpose

- **A view switcher** — Typed / Handwritten / Photos — fills with the
  **current color theme** when selected. It picks a view, has no meaning of
  its own, and is the one splash of color on the screen.
- **A flag or a filter** — ⭐ and 🔥, and the gallery's unlinked — uses
  **fixed greys**: light grey outline and icon when off; black 1.5px
  outline, pale grey fill, and the icon in *its* color when on. Nothing
  theme-colored, so the only color in the button is the one that means
  something.

A flag looks the same wherever it appears — list row, filter bar, character
screen. That's the point of the split.

## Destructive actions go to the bottom

**Delete** belongs at the bottom of a screen, labelled, away from
navigation. It used to sit next to **Home** in the photo screen's app bar,
a few millimetres from a button you press constantly (fixed 2026-09-20).
Distance from the thing you tap by reflex matters more than discoverability
for an action you take rarely and can't undo.

## Tooltips name the thing, not its state

A filter's tooltip says "Favorites only" whether or not it's filtering. It
used to append " (filtering)" while on, which meant two buttons side by
side described themselves differently depending on which was active.

## Empty states offer the action that fills them

No handwriting → **Draw now**. No photos → **Add photo**. No tags → the
picker. An empty box that only says it's empty wastes the one moment the
user is definitely looking at it.

## Layout details that keep biting

- **`Wrap`, not `Row`**, for any row of buttons that could grow — they drop
  to a second line on a narrow phone instead of overflowing.
- **A fixed bottom bar, not a floating button**, when the list underneath
  has nothing to scroll past it into.
- **`SafeArea(top: false)`** on anything pinned to the bottom, so it clears
  the phone's gesture bar without hard-coding a number.

## Text input

- **Definitions are single-line** and Enter saves. A multi-line field gives
  the keyboard a newline key by definition — you can have line breaks or
  Enter-to-save, not both, and a definition is a line of English.
- **Notes stay multi-line.** That's where longer writing goes, which is why
  losing line breaks in the definition costs nothing.
- **Every `TextEditingController` belongs to a `State`.** Building one in a
  method and disposing it after `await showDialog` looks right and is a
  bug — the route is still animating out, and the live `TextField` touches
  a disposed controller. See "Bugs found while testing" in `tags.md`.
