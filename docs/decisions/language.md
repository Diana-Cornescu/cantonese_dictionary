# Language — Cantonese / Mandarin

**Decided and built 2026-09-26.**

Some entries are Mandarin words, and some words are shared by both. Each character now has an optional **Language**: Cantonese, Mandarin, both, or not set.

## Decisions

| # | Topic | Decision | Why |
|---|-------|----------|-----|
| 1 | Storage | Two flags on `characters`: `is_cantonese`, `is_mandarin` (schema version 4). Both on = both; both off = not set. | "Show Cantonese" is simply `is_cantonese`, which naturally includes the shared words. A single text column would need `'both'` special-cased in every filter. |
| 2 | Required? | **No.** Both off is a normal state, shown as "Not set". | Asked for as optional. |
| 3 | Existing characters | Upgrade leaves them **not set**. | Nothing is assumed; label them as you go (use the Not set filter to find them). |
| 4 | Editing | Two toggles, **Cantonese** and **Mandarin**, as the **first line of the Tags section** (tags on the line below) on the Add character screen and the character screen. Both always visible, grey when off. On the character screen each tap asks for **confirmation**; on Add character, Save is the confirmation. The tags ✎ doesn't touch them. | Revised the same night (was its own Language section, instant): it behaves like a special tag that's always offered, and edits among the tags are confirmed. Same grey / black outline look as Favorite / Hard, with no color of its own. |
| 4a | Icons | Cantonese: a five-petal bauhinia; Mandarin: one large star and four small. Drawn in code (`lib/widgets/language_icon.dart`), one color taken from the button like any icon: black / white by mode when on, grey when off. | Added 2026-09-26 at Diana's request, from the Hong Kong and PRC flag emblems, simplified to read at 18 px. |
| 5 | Display | Character screen only (in the Tags section). The list rows are unchanged. | Chosen 2026-09-26. |
| 6 | Filter meaning | **Cantonese includes words marked both**; so does Mandarin. | A shared word is still a Cantonese word. |
| 7 | Filters: lists | Home list, Archive and Photos get a **Language** group in the filter sheet: Cantonese, Mandarin, Not set. Toggles combine with AND like the rest of the sheet, so Cantonese + Mandarin = words marked both. Not set switches the other two off and vice versa. | Consistent with Show only. Not set + a language could only ever show nothing. |
| 8 | Filters: Photos | A photo matches if **one** linked character matches every language toggle on its own. Unlinked clears the language toggles (and they clear Unlinked), as with Favorites / Hard. | Same "linked to a character that is…" rule as ⭐ / 🔥. |
| 9 | Filters: Flashcards, Write | Three **Language** checkboxes in the … panel: Cantonese, Mandarin, Language not set, **all checked by default**. A card is included if it matches **any** checked box (OR), so a word marked both stays in while either language is checked. Combines with All / Hard / Favorites. Not remembered between sessions, like which cards. | Changed the same night from a single radio choice (Any / Cantonese / Mandarin / Not set) at Diana's request: ticking boxes off is quicker than picking one. |

## Where the code is

- `lib/data/app_database.dart` — columns, `v3 -> v4` migration.
- `lib/data/character_entry.dart` — `isCantonese`, `isMandarin`, `hasLanguage`, and `LanguageFilter` (used by Flashcards and Write).
- `lib/data/dictionary_store.dart` — `toggleCantonese`, `toggleMandarin`.
- `lib/widgets/language_toggles.dart` — the two buttons.
- `lib/widgets/language_filter_options.dart` — the filter sheet's Language group and its rules.
- `test/language_test.dart`.
