# Cantonese Dictionary App — Future Ideas / Parked Features

Concepts that came up while planning the app but were deliberately left out of v1. Keeping them here in full so they aren't lost and can be picked back up later.

## Handwriting recognition — self-learning template matching

**Status:** parked on 2026-07-19. Judged too complex for what it would add in v1 — typing the character directly (via a Chinese/Cantonese keyboard input method) or pasting it in from elsewhere covers the same need for now, with far less engineering risk.

**The idea:** since there's no internet and no bundled ML model, recognition would work entirely by comparing a new hand-drawn character against the handwritten samples already stored for other characters in your own dictionary — no external corpus, nothing sent anywhere. This fit the app's "self building" framing well: a brand-new dictionary with only a handful of characters in it would recognize almost nothing (there's nothing to compare against yet); by the time a few hundred are entered, matching would get meaningfully more useful, entirely from your own handwriting data.

**How it would work mechanically:** each stroke resampled to a fixed number of evenly-spaced points, and the whole character normalized to a fixed bounding box, so drawings are comparable regardless of size, speed, or exact pixel position. Comparison would use a point-cloud matching approach (in the spirit of the well-established "$P" recognizer algorithm), which tolerates strokes drawn in a different order or count than the stored sample — a real concern for handwritten Chinese characters, where stroke order varies person to person. The stored templates with the lowest distance score to the new drawing would become the top-3 suggestions shown to you.

**Why it was parked:** this is a genuine algorithm to design, implement, and tune — resampling, normalization, distance scoring, and deciding a sensible threshold for "no good match found." It also only becomes useful once a fair number of characters already have saved handwriting samples to compare against, so it offers the least value exactly when it would also be hardest to get right (a brand new, mostly-empty dictionary).

**If revisited, note the data-model implication:** the main plan now keeps handwriting storage as simple as possible — one drawing per character, overwritten whenever it's redrawn, no version history. Recognition would need its own separate store of one-or-more reference templates per character to match against, distinct from the single "current drawing" shown in the character window.

**Possible future refinement, if revisited:** let the app save additional handwriting templates per character over time — e.g., each time a character is redrawn correctly during recognition — so matching accuracy for frequently-practiced characters keeps improving rather than staying pinned to a single original sample.

## Managed / reusable tag list

**Status:** parked on 2026-07-19. v1 ships with simple free-text tags (a plain label typed directly onto a character, no master list) since that matches how you described using tags — short, casual, informal labels rather than a controlled taxonomy.

**The idea:** instead of free text, the app would keep a master table of tags. Tagging a character means picking from existing tags (with an inline "create new" option if the one you want doesn't exist yet) rather than typing a fresh string every time.

**What it would add over free-text:**
- Consistent spelling/casing — no more "food" on one row and "Food" (or a typo) on another being silently treated as two different tags.
- Rename once, updates everywhere — renaming a tag in the master list updates every character using it, instead of having to hunt down and retype it on each row.
- A place to browse every tag in use, and later, filter/search the dictionary by tag.
- Deleting a tag that's currently in use would go through the app's confirm-before-edit dialog, same as any other destructive action.

**Why it was parked:** it's a real, if modest, chunk of extra build — a tags table, a many-to-many join to characters, and a picker UI with inline creation — for a benefit (consistency, central rename, filtering) that's only worth it once the dictionary and its tag vocabulary have grown large enough for messy free-text tags to actually become a problem. Free-text can always be migrated into this structure later (the existing comma-separated tags on each character would just become the initial rows in the new tags table).
