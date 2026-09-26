# Changelog

What changed in each release installed on the phone. Newest first.
How to release: `docs/setup_manual.md`, Phase 6.
Version format: `MAJOR.MINOR.PATCH` (see `pubspec.yaml`).

## Unreleased

- **Language: Cantonese, Mandarin or both.** An optional field for each character. Set it with the **Cantonese** and **Mandarin** buttons on the Add character screen, or on the character screen under the definition (turn both on for a word the two share; leave both off and it shows "Not set"). Instant, like Favorite and Hard. Characters you already have start as Not set.
  - **Filter by it everywhere.** The filter sheet on the home list, the Archive and Photos has a new **Language** group: **Cantonese**, **Mandarin** and **Not set**. Cantonese includes words marked both, and so does Mandarin; tick both to see only the shared words. Not set finds the ones you haven't labelled yet. In Photos it means "shows a character that is…", like ⭐ and 🔥.
  - The **…** panel on **Flashcards** and **Write** has **Language** checkboxes too: **Cantonese**, **Mandarin** and **Language not set**, all ticked to start with. Untick one to leave those cards out; a word marked both stays in while either language is ticked. It works together with All / Hard / Favorites.
  - Database version 4. Older backups still restore; they're upgraded the same way.

## 1.7.0 — 2026-09-26

- **A Write tab for practising writing characters.** It shows a definition, always visible right above a square box with faint guide lines. The **X-ray** in the box shows how the character is written: each stroke in pale grey, with a blue line and arrow for the direction and a number on it for the order. Write over it, then tap **Next**.
  - The stroke to write next is in blue and the others are grey; it moves on each time you lift your pen, and undo steps it back.
  - **Hide X-ray** (👁) next to **Next** turns the X-ray off so you can try from memory, without clearing what you've written; **Show X-ray** brings it back to check. It stays hidden from card to card until you show it again or close the app.
  - Words with more than one character (时间) are written one character at a time.
  - Nothing is scored or saved yet, and flashcard stats aren't affected.
  - **…** (the round button) also picks All, Hard or Favorites, like Flashcards.
  - The correct forms come from a free set of about 9,500 common characters built into the app, so it works offline. **Many Cantonese-only characters (咗 冇 佢 啲 嚟 喺…) aren't in it**; those entries are skipped, and the **…** panel lists which.
- **Tags moved into Settings**, to make room for Write in the bar. **Settings → Tags** opens the same screen as before, with a **+** at the top to create a tag.
- **Settings → Handwriting: pen size and smooth strokes.** A slider sets how thick your ink is, from 2 to 10 (4 is the size it's always been), with a preview. **Smooth strokes** rounds off corners and wobbles, and is **on** unless you turn it off. Both change how every drawing looks, old ones included, but not what's saved, so you can change them back any time. Remembered, and included in backups.
- **Settings → Licences** lists the licences for the built-in stroke data and the packages the app uses.
- The app is about 11 MB bigger because of the stroke data.

## 1.6.0 — 2026-09-25

- **Each character shows the date it was added.** A small grey "Added YYYY-MM-DD" line under the definition on the character screen. It's set automatically when you tap Save on the Add character screen and can't be changed afterwards. Characters you already have show their real date too, because it was always being saved and just never displayed.
- **One filter icon instead of a row of buttons.** On the home list (and the Archive) and in the photo gallery, the ⭐ 🔥 (and 🔗 in Photos) buttons next to the search box are replaced by a single filter icon. Tap it for a sheet with:
  - **Show only** Favorites, Hard, and in Photos Unlinked. They combine the same way as before, and in Photos turning on Unlinked still clears the others and the search box.
  - **Sort** Newest first or Oldest first, by the date the character or photo was added. **Newest first is the new default on both screens** (the home list used to show oldest first). Your choice is remembered after closing the app, and included in backups.
  - **Clear filters**, which turns off every Show only toggle. It leaves the sort and the search box alone.
  - The icon fills in, like the old buttons did, whenever something is being filtered.
- **A bar along the bottom to get around, like Instagram.** **Characters · Photos · Tags · Flashcards**, with a slightly bigger round button in the middle. It replaces the ☰ side menu.
  - **The round button does the obvious thing for the tab you're on:** **+** adds a character, a photo or a tag; on Flashcards it's **…** and opens or closes the flashcard options. The Add character bar at the bottom of the home list and the round + buttons on Photos and Tags are gone.
  - **The bar stays put** when you open a character, photo or tag. Tap the tab you're on to jump back to its top screen, which is why the Home buttons are gone. Switching tabs and back returns you to where you were, including a flashcard round in progress. New or changed characters are picked up when you come back to Flashcards.
  - **Settings is the ⚙ at the top right** of each tab, where Home used to be. **Archive moved into Settings**, with a count of archived characters. **Using the bar closes Settings**: switching tabs, tapping the current tab or the round button all take you out of it, so coming back to a tab shows the tab, not Settings.
  - **Flashcard options moved into the … panel**: which cards, which direction, and text or text + drawing. **Text only is now the default** and listed first (it was Text + drawing); if you'd already picked one, your choice is kept. "All characters" no longer has an icon, so only the ⭐ and 🔥 filters do. Tap … again to close it. Nothing about them shows at the top of the Flashcard screen any more, so the card has the space.
  - **Android back button** goes back inside the tab first, then to Characters, then leaves the app.
- **Dark mode.** Settings → **Appearance**: **Light**, **Dark** or **Match phone** (follows your phone's or Windows' own setting, switching at night if yours does). Light is the default, so nothing changes until you pick. Remembered, and included in backups.
  - Charcoal background, off-white text, and lighter grey icons so they stand out.
  - **Your handwriting stays on a light "sheet of paper"** with black ink, so drawings look the same in both modes.
  - **Five color themes have a dark version so far: Cerulean, Teal, Iris, Violet and Plum.** They're marked with a small 🌙 in Settings. In dark mode each one uses its lighter shade, since the usual one is too dark to see on a dark background. **Slate, Cobalt and Navy are light-only for now**: while the app is dark they're faded in Settings, and choosing one uses Cerulean in dark mode (Settings says so).
- **Buttons light up like tags.** Hover over, press, or select a button and it takes on the tag look: a tint of your color theme, a thin outline, and white text in dark mode or near-black text in light mode (the two modes mirror each other). This covers **Typed / Handwritten / Photo** (while selected), **Archive**, **Unlink all** and every other outlined button. **Delete** does the same in red. ⭐ Favorite and 🔥 Hard keep their own grey look.
- **Behind the scenes: colors are organised in one place.** Nothing looks different. Every color is now defined once in the theme files, and screens refer to colors by what they're for, which is the groundwork for dark mode. A new test stops a color being written directly into a screen again.

## 1.5.0 — 2026-09-21

- **Adding a character works like the character screen now.** One box with **Typed / Handwritten / Photo** buttons above it — pick whichever you have, switch between them freely.
  - **The drawing is no longer compulsory.** A new character needs a definition plus **at least one** of the three. A character spotted on a menu can start as a photo and be drawn later. A tick marks each one you've filled in.
  - One photo here; link more (and more characters) from the photo's own screen afterwards.
  - A character with no typed text now shows a small grey **?** icon in the lists instead of a literal "?", so you can see it's still to be typed in.
- **Notes moved up**, to sit under the definition instead of under the flashcard stats.
- **"Characters list" at the top of the ☰ menu**, so the menu names every part of the app including the screen you're on.
- **A Photos button on the character screen.** A third button next to **Typed** and **Handwritten**. It turns the same box into a carousel of the photos linked to this character — swipe between them, or use the round arrows either side. Tap one to open its full screen, where the note, its other characters and delete live.
  - The old strip of small thumbnails further down the screen is gone; this replaces it. **Add photo** is now under the carousel, and the empty state offers it too.

## 1.4.0 — 2026-09-20

- **Flashcards: show the character as text only, or text + your drawing.** A third dropdown next to the other two. Recognising your own handwriting is a way of cheating — it doesn't help when the same character turns up on a menu — so **Text only** takes that away. Unlike the other two dropdowns this one is **remembered between sessions**, and it's included in backups.
- **Enter saves the definition and closes the keyboard.** The definition box is now one line, on both the Add character screen and the character screen's edit dialog, so Enter finishes it instead of adding a line break you can't see. Notes keep their multi-line box for longer writing.
- **Every search box has an ✕ to clear it.** Home list, photo gallery, tags, and the two pickers. It only appears once there's something to clear.
- **The photo gallery gets the same filters.** ⭐ and 🔥 buttons to the right of the gallery's search box, matching the home screen. For a photo they mean "linked to a character that's starred / hard". The **Unlinked only** box became a grey broken-link 🔗 button in the same row, so all three look and behave alike. Unlinked clears the other two and the search box when you turn it on — an unlinked photo has no characters, so those combinations could only ever show nothing.
- **Filter the home list by favorite or hard.** ⭐ and 🔥 buttons sit to the right of the search box. Tap one and it fills in — coloured icon, tinted background, highlighted border — so it's obvious the list is being filtered. They work independently (both on = starred *and* hard) and combine with whatever you've typed in the search box.
- **Star and hard from a character's own screen.** **Favorite** and **Hard** buttons sit right under the character box, styled like the Typed/Handwritten pair above them — they fill in when on. Same instant, no-confirmation toggles as the list rows, so you no longer have to go back to the list to flag something you're looking at.

## 1.3.1 — 2026-09-20
- **"Add character" is now a bar at the bottom of the home screen.** It used to be a round button floating in the corner, covering the last character's star and fire buttons. The list now scrolls in its own space above the bar, so every row is reachable.
- **Add a photo and references while adding a character.** The Add character screen now has **Photo** and **References** sections next to Tags, so a new character can arrive complete instead of needing a second pass to edit it. Cancelling writes nothing at all.

## 1.3.0 — 2026-09-20
- **Tags have their own screen.** **Tags** in the ☰ side menu lists every tag with how many characters carry it. Tags nobody uses any more are shown greyed at "0 characters" rather than hidden, so a typo'd tag is findable instead of stuck in the database.
  - Tap a tag for its own screen: the characters that have it (tap one to open it), **Add or remove characters** in a single checklist like the one the photo screen uses, **rename**, and **delete**.
  - **Renaming onto a tag that already exists merges the two** (it asks first). That's the fix for ending up with both "food" and "Food".
  - Deleting a tag removes it from every character; the characters themselves are kept.
  - **+** makes an empty tag and opens it, so you can create one and fill it afterwards.
- **Tags are now picked, not typed.** On the Add character screen and on a character's screen, the comma-separated text box is replaced by a picker: tick the tags that already exist, or type a new one to create it. A tag can no longer contain a comma, which would have silently split it in two.
- **Tag chips open their tag.** Tapping a tag on a character's screen opens that tag's list, the same way a photo's linked characters open theirs.
- **Photos**: move delete button and add a unlink all button.
  - **Delete photo** left the top bar, where it sat right next to **Home** and was easy to hit by mistake. It's now a labelled button at the bottom of the photo screen, below the linked characters.
  - **Unlink all** sits next to it: it drops every character link but keeps the photo, which then turns up under the gallery's "Unlinked only" filter.

## 1.2.0 — 2026-09-20

- **Photos:** add photos of characters seen out and about, by camera or from your phone's gallery. One photo can be linked to several characters and have a note. They show in a new **Photos** row on each character's screen and in a new **gallery** (🖼 on the home screen). Photos are included in backups.
  - In the gallery: names are comma-separated, and you can filter by **Unlinked only** or search by character, definition, tag or note.
  - On a photo: tap a linked character to open it (Back returns to the photo). The **+** button changes which characters are linked.
- **Flashcards:** the character side now always shows your drawing under the typed character, in both directions.
- **Flashcards:** the Back button became **Go to character screen**, shown after you reveal the card. It opens the current card's character, and Back returns to the same card.
- **Photos gallery:** a Home button at the top right.
- **Color themes:** Settings → Color theme lets you pick from 8 colors: Cerulean (default), Cobalt, Teal, Navy, Iris, Violet, Plum, Slate. None of them can be mistaken for the red (hard), gold (favorite) or green (correct) that already mean something. The choice is included in backups. (Database schema version 3.)
- **Hard icon:** the "hard" flag is now a red 🔥 fire icon (was "!").
- **Flashcard options redesigned:** two matching dropdowns: which cards (**All characters**, **Hard only**, **Favorites only**) and which way (**Character → Definition**, **Definition → Character**, **Bidirectional**, a random direction per card).
- **Side menu:** a ☰ menu on the home screen replaces the row of top-bar icons, with Flashcards, Photos, Archive and Settings.

## 1.1.0 — 2026-09-20

- **Flashcards both ways:** new toggle boxes on the flashcard screen: *Hard only*, *Character → Definition*, *Definition → Character*. With both directions on, each card is asked a random way. Definition → Character shows the typed character and your drawing as the answer.
- **Definition is now required** when adding a character (and can't be emptied when editing).
- **Undo / clear while drawing:** the drawing box has an Undo button (removes the last stroke) and a Clear button (removes everything), so a mistake no longer means saving and redrawing.
- **Shorter "back" history:** tapping a referenced character now replaces the current character screen instead of stacking a new one. Back always returns to the list.

## 1.0.0 — 2026-09-19 (first release)

- **Storage moved to SQLite + Drift.** Faster saves, proper tables for tags, references and (future) photos. See `docs/decisions_log_sqlite_drift.md`.
- **New Settings screen** (gear icon on the home screen) with:
  - **Back up**: saves everything to one `.zip` file wherever you choose (Downloads, Google Drive, …).
  - **Restore**: replaces all data with a backup, after saving an automatic safety copy.
  - **Undo last restore**.
- **Removed** the readable JSON export (replaced by backups).
- First build signed with your own release key.

## 0.1.0 — 2026-07-23 (development only, never released)

- First version: dictionary list, character detail, add character with handwriting, star/hard/archive, references, flashcards, JSON export. Installed as a debug build only.
