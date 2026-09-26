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

## Where colors live (restructured 2026-09-25)

**Every color value is written down exactly once**, in `lib/theme/`:
`AppRawColors` in `app_colors.dart` (every fixed color) and
`app_palettes.dart` (the 8 color themes). Nothing else in the app writes a
color — no `Colors.white`, no `Color(0x…)`. Done before dark mode so that
dark mode means adding one more list, not hunting through every screen.

Screens ask for a color by **what it's for**, in one of three ways:

| Use | For | Example |
|---|---|---|
| The theme | anything it already styles: text, icons, buttons, fields, app bars | `Theme.of(context).colorScheme.primary` |
| `AppColors` | the colors that **mean** something, same in every mode | `AppColors.danger` |
| `context.appColors` | colors that depend on light/dark: inactive grey, the "on" filter look, box borders, ink | `context.appColors.inactive` |

`context.appColors` is a `ThemeExtension` (`lib/theme/app_color_roles.dart`)
holding one set of values per mode: `light` and `dark`. A new kind of
color goes into `AppRawColors` first, then gets a name in `AppColors` or a
role in `AppColorRoles`.

`test/no_hardcoded_colors_test.dart` fails if a file outside `lib/theme/`
writes a color value or reaches into `AppRawColors`.

## Dark mode (1.6.0)

Decided 2026-09-25.

- **Light / Dark / Match phone**, in Settings → Appearance. Default Light.
- **One theme builder for both modes** (`AppTheme._build` with a
  `_ModeColors` per mode), so light and dark can't drift apart.
- **Dark mode uses each color theme's lighter accent** (`darkAccent`, the
  palette's `tertiary`) with near-black text on it; the usual primary is
  too dark on charcoal.
- **A color theme only gets dark mode if its accent is clear on the dark
  background — at least 4:1 contrast.** `AppPalette.darkReady` says so,
  and `test/app_palettes_test.dart` checks the number. Themes that aren't
  ready show Cerulean in dark mode; Settings marks the ready ones with 🌙
  and fades the others while dark.
- **Handwriting stays on light paper** (`paper` / `onPaper` roles): black
  ink on a light sheet in dark mode, so a drawing looks the same in both.
- **Pen size and smoothing are display settings** (Settings →
  Handwriting, 2026-09-26; `widgets/ink_settings.dart`). Every drawing box
  reads them through `InkSettings.of`, and they never change the points
  that are saved, so old drawings redraw with the new look and turning
  smoothing off loses nothing. Pen size is 2–10 (default 4, the old fixed
  size), capped so strokes don't merge in small boxes. Smoothing is on by
  default.
- **Red, gold and green are the same in both modes for now.** Red is dim
  on dark (2.4:1) — see the roadmap.

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

## Buttons: the tag look when active (2026-09-25)

The **tag chip** is the model: a pill filled with a soft tint of the color
theme, a thin neutral outline, and text in a contrasting shade —
near-black in light mode, off-white in dark mode. **The two modes are
mirror images:** the tint is 30% of the theme color on white in light mode
and 30% of it on charcoal in dark mode (light mode was a fainter 15% with
the theme's deep shade for text until 2026-09-25).

**Every outlined button wears that look while it's active** — hovered,
pressed, focused, or selected — and is a plain outline in the theme color
at rest. `lib/theme/app_button_styles.dart`:

- `outlined` — set once in the theme, so every `OutlinedButton` gets it
  (Archive, Unlink all, Cancel, Clear filters, …) with nothing at the call
  site.
- `selected` — the chosen one of a view switcher (Typed / Handwritten /
  Photo(s)), which stays in the active look.
- `danger` — Delete (character, photo, tag): red at rest, and a soft **red**
  fill when active (near-black text in light, off-white in dark), so it
  follows the convention without losing its meaning.

**⭐ Favorite / 🔥 Hard are the exception** and keep the fixed-grey flag look
above; their style sets its fill and icon color even when off so the
app-wide hover tint can't reach them.

## Getting around: the bottom bar (1.6.0)

Decided 2026-09-25, replacing the ☰ side menu. Code:
`features/shell/app_shell.dart`.

- **Four tabs and a round button:** Characters · Photos · (round) · Write
  · Flashcards, each an icon with a small label. **Write replaced Tags on
  2026-09-25**; Tags is a row in Settings until it gets a permanent home
  (roadmap). See `writing-practice.md`.
- **Keep it two tabs either side of the round button.** A fifth tab would
  break the symmetry, which is why Write took an existing slot instead.
- **The round button is the tab's main action.** + on Characters and
  Photos adds one; … on Write and Flashcards opens their options, and a
  second tap closes them (the panel doesn't cover the bar). It's filled with
  the color theme — like a view switcher, it has no meaning of its own. No
  screen has its own "add" button any more.
- **The bar is always visible.** Each tab has its own navigator, so inner
  screens (a character, a photo, a tag, Settings) open inside the tab.
  Tapping the current tab returns to its top screen, so **no screen has a
  Home button**. Tabs keep their place when you switch away.
- **Settings is the ⚙ at the top right of each tab's top screen.** Things
  used rarely (the Archive, Tags, backups, licences) live inside Settings,
  not in the bar. A screen opened from Settings has no ⚙ of its own, so
  Tags has its **+** in its own top bar.
- **Using the bar always leaves Settings** (switching tabs, tapping the
  current tab, the round button). Settings is a place you step into and
  out of; a tab that reopened on Settings looked like a bug. Other inner
  screens (a character, a photo, a tag) do keep their place.
- **Back button:** back inside the tab, then to Characters, then out.

## One filter icon per list (1.6.0)

A list's filters live behind **one filter icon** next to its search box,
not a growing row of toggle buttons (decided 2026-09-25). The home list,
the archive and the photo gallery share `widgets/list_filter_button.dart`,
whose bottom sheet has the "show only" toggles, the sort order and
**Clear filters**. The Tags screen doesn't have one.

- The icon wears the flag/filter "on" look above while any toggle is on.
  A non-default **sort doesn't light it up**: sorting never hides anything.
- **Toggles reset** when you leave the screen; **the sort is remembered**
  (in `app_settings`, so it's in backups).
- **Newest first** is the default everywhere.
- **Clear filters** clears the toggles only. It leaves the sort (a
  preference) and the search box (it has its own ✕) alone.

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
  has nothing to scroll past it into. (Since 1.6.0 the app-wide bottom bar
  holds the only "add" button, so screens don't need their own.)
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
