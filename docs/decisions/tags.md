# Tags

**Decided 2026-09-20. Shipped in 1.3.0.**



---

## TL;DR

- **Why:** tags were write-only. You typed them as free text on each
  character and nothing ever showed you the list, so "food" and "Food"
  could both exist and neither was findable.
- **Where:** a **Tags** entry in the ☰ side menu opens a searchable list of
  every tag with how many characters carry it. Tap one for its own screen.
- **On a tag's screen:** the characters that have it (tap to open one),
  **Add or remove characters** in one checklist, **rename** (which merges
  if the new name already exists) and **delete**.
- **Choosing tags is now a picker**, on both the Add character screen and
  the character screen: tick existing tags, or type a new one to create it.
  No more retyping a comma-separated string.
- **Tag chips are tappable** on a character's screen and open that tag.
- **No database changes.** The tables were already there (decision 2 in
  `storage.md`); they just had no UI. **No `build_runner` run needed.**

---

## Decisions

| # | Topic | Decision | Why |
|---|-------|----------|-----|
| 1 | Where the screen lives | **Tags** in the ☰ side menu, between Photos and Archive | It's a browse-everything screen like Photos and Archive, not something you need from every screen. |
| 2 | Tags with no characters ("orphans") | **Shown, greyed, with "0 characters"** | `replaceTags` already kept them on purpose. Hiding them would mean a typo'd tag lingers in the database forever with no way to see or delete it. |
| 3 | Bulk-assigning characters | The **same checklist dialog the photo screen uses** for its linked characters | One idea to learn, one widget to maintain. It moved from `features/photos/` to `widgets/character_picker_dialog.dart` now that two features share it. |
| 4 | Renaming onto an existing tag | **Merges the two**, after a confirmation that says so | The alternative (refusing) leaves you stuck with both "food" and "Food" and no way to fix it. Merging is the reason you'd rename in the first place. |
| 5 | Deleting a tag | Removes it from every character; **the characters are kept** | A tag is a label, not a container. Confirmation names how many characters are affected. |
| 6 | Creating an empty tag | A **+** button on the Tags screen, which opens the new tag's screen so you can fill it | Matches the "make the tag, then add characters" flow the bulk picker is built for. |
| 7 | Free-text tag entry | **Replaced by the picker** on both the Add and character screens | This was the actual cause of near-duplicate tags. The picker still creates new tags — you just see the existing ones first. |
| 8 | Commas in a tag name | **Rejected**, with an inline message | A character's tags are stored as ONE comma-separated string, so a comma inside a name would silently split it in two. `isValidTagName` in `data/character_entry.dart` is the single check. |
| 9 | Case | **Exact match**, but sorted case-insensitively | "Food" and "food" stay two tags (the `name` column is UNIQUE and case-sensitive); sorting puts them next to each other so you notice and merge them with rename. |
| 10 | Who writes tag links | **Editing a character's tags** goes through `DictionaryStore.updateCharacter`. **Editing the tag** (rename, merge, delete) does not — it works on the tag rows and then refreshes the in-memory strings | A character's `tags` string is a display copy rebuilt from the tag tables on load, **not a column**. So a tag-level edit has nothing to write per character; routing it through `updateCharacter` would write nothing but a new `updatedAt`. |
| 11 | Does renaming a tag "edit" its characters? | **No.** `renameTag` and `deleteTag` leave `updatedAt` alone; `setTagCharacters` still bumps it | Relabelling or removing a tag doesn't change what a character *is*. Adding or removing a tag from specific characters does, so that one stays an edit to them. |

---

## What was built

- `lib/data/character_entry.dart`: **`isValidTagName`** — blank and
  comma-containing names are rejected.
- `lib/data/app_database.dart`: **`allTagNames`**, **`ensureTag`**,
  **`renameTagRow`**, **`deleteTagByName`**. Queries only — **no table
  changed**, so the generated `app_database.g.dart` is untouched.
- `lib/data/dictionary_store.dart`: **`allTags`**, **`tagCount`**,
  **`charactersWithTag`**, **`createTag`**, **`setTagCharacters`**,
  **`renameTag`**, **`deleteTag`**, and an in-memory `_tagNames` list
  loaded alongside everything else.
- `lib/features/tags/tags_screen.dart` and `tag_detail_screen.dart` (new).
- `lib/widgets/tag_picker_dialog.dart` (new): pick from existing tags or
  type a new one.
- `lib/widgets/character_picker_dialog.dart`: **moved** here from
  `lib/features/photos/`. Two importers updated, no behaviour change.
- `lib/widgets/tag_chip.dart`: optional `onTagTap`.
- `lib/features/dictionary_list/dictionary_list_screen.dart`: the menu entry.
- `lib/features/character_detail/character_detail_screen.dart` and
  `lib/features/add_character/add_character_screen.dart`: the picker
  replaces the free-text tags field; chips open the tag.
- `test/tag_store_test.dart` (new): the tag list including orphans,
  bulk add/remove, rename (with a reload from disk), merge, delete, and
  the name validation.

---

## Bugs found while testing (2026-09-20)

**A disposed `TextEditingController`.** Creating a tag threw
`A TextEditingController was used after being disposed`, followed by ten
more exceptions — duplicate GlobalKeys, "dirty widget in the wrong build
scope", detached render boxes, an overlay assertion, and a RenderFlex
overflowing by 99,668 px. Only the first one mattered; the rest were the
frame collapsing afterwards.

The cause was a pattern copied from the existing dialogs: build a
`TextEditingController` in the calling method, `await showDialog(...)`,
then `controller.dispose()`. That dispose is too early. `showDialog`'s
future completes when the route is *popped*, but the route is still
animating out and its `TextField` is still alive — and because `main.dart`
rebuilds the whole app on every store change, the notification from
`createTag` rebuilt that dying dialog and it touched the disposed
controller.

Fixed by giving every dialog that owns a text field its own
`StatefulWidget`, so the controller's life matches the widget that uses it:

- `widgets/tag_name_dialog.dart` (new) — `promptForTagName`, shared by
  **New tag** and **Rename tag**, with inline validation and Enter-to-save.
- `widgets/text_prompt_dialog.dart` (new) — `promptForText`, shared by the
  character screen's edit dialogs and the photo note. The character screen's
  version had never disposed its controller at all.
- `widgets/tag_picker_dialog.dart` and `widgets/character_picker_dialog.dart`
  — both rewritten as `StatefulWidget`s owning their search controller.

No `TextEditingController` in `lib/` is now created outside a `State`.

**Two things fixed alongside it, both found while hunting the wrong
suspect.** They weren't the cause, but they were real:

- `setTagCharacters` called `updateCharacter` in a loop, so ticking eight
  characters fired eight notifications and — see `main.dart` — eight full
  app rebuilds. It now does the same writes and notifies once.
- Creating a tag used to push its screen in the same frame the dialog
  popped. It no longer does; the tag appears in the list and you tap it.

The underlying fragility — `MaterialApp` rebuilding on every store change —
is in the backlog rather than fixed here.

---

## The trap, and why half of it went away

Tags exist twice: as `tags` / `character_tags` rows linked **by id**, and as
`CharacterEntry.tags`, one comma-separated string keyed **by name**. The
string is not stored — `load` rebuilds it — but `AppDatabase.replaceTags`
turns those names back into ids, and *creates a row for any name it doesn't
recognise*. That one line is the whole trap.

**First version (rewritten 2026-09-20).** `renameTag` rewrote every affected
character through `updateCharacter`, which meant ordering mattered:

- Not merging: the tag ROW had to be renamed first, or the character writes
  would create a *second* row with the new name and the rename would then
  break `UNIQUE(name)`.
- Merging: the characters had to be rewritten first, then the emptied row
  deleted.

**Now.** The non-merge case doesn't touch characters at all — nothing moves,
so it's one statement:

```sql
UPDATE tags SET name = 'eating' WHERE id = 3;
```

The row keeps its id and every link to it. Afterwards
`_rewriteTagsInMemory` refreshes the display strings. No ordering question,
no `updatedAt` churn, N database writes became 1.

`deleteTag` went the same way: `deleteTagByName` already drops the tag's
links along with its row, so the per-character loop was pure overhead.

**Merging still has real work to do** — two rows have to become one, so each
affected character is re-linked to the surviving row (deduplicated, so a
character carrying both doesn't end up with it twice) before the emptied row
can go. That ordering is inherent, not an artefact.

`test/tag_store_test.dart` covers both branches, a close-and-reopen from
disk, and that neither one moves any character's `updatedAt`.
