# Parked designs

**Long write-ups for work that was designed properly and then deliberately
not built.** One entry per idea, kept in full so picking it back up doesn't
mean re-deciding everything.

This is not the list of what's next — that's **`roadmap.md`**, which names
each of these in one line and links here. An idea only earns a place in this
file once it has a real design behind it; a one-line "wouldn't it be nice"
belongs in the roadmap's Inbox.

## Handwriting recognition — self-learning template matching

**Status:** parked on 2026-07-19. Judged too complex for what it would add in v1 — typing the character directly (via a Chinese/Cantonese keyboard input method) or pasting it in from elsewhere covers the same need for now, with far less engineering risk.

**The idea:** since there's no internet and no bundled ML model, recognition would work entirely by comparing a new hand-drawn character against the handwritten samples already stored for other characters in your own dictionary — no external corpus, nothing sent anywhere. This fit the app's "self building" framing well: a brand-new dictionary with only a handful of characters in it would recognize almost nothing (there's nothing to compare against yet); by the time a few hundred are entered, matching would get meaningfully more useful, entirely from your own handwriting data.

**How it would work mechanically:** each stroke resampled to a fixed number of evenly-spaced points, and the whole character normalized to a fixed bounding box, so drawings are comparable regardless of size, speed, or exact pixel position. Comparison would use a point-cloud matching approach (in the spirit of the well-established "$P" recognizer algorithm), which tolerates strokes drawn in a different order or count than the stored sample — a real concern for handwritten Chinese characters, where stroke order varies person to person. The stored templates with the lowest distance score to the new drawing would become the top-3 suggestions shown to you.

**Why it was parked:** this is a genuine algorithm to design, implement, and tune — resampling, normalization, distance scoring, and deciding a sensible threshold for "no good match found." It also only becomes useful once a fair number of characters already have saved handwriting samples to compare against, so it offers the least value exactly when it would also be hardest to get right (a brand new, mostly-empty dictionary).

**If revisited, note the data-model implication:** the main plan now keeps handwriting storage as simple as possible — one drawing per character, overwritten whenever it's redrawn, no version history. Recognition would need its own separate store of one-or-more reference templates per character to match against, distinct from the single "current drawing" shown in the character window.

**Possible future refinement, if revisited:** let the app save additional handwriting templates per character over time — e.g., each time a character is redrawn correctly during recognition — so matching accuracy for frequently-practiced characters keeps improving rather than staying pinned to a single original sample.

## Managed / reusable tag list — BUILT

**Shipped in 1.3.0** (2026-09-21). Parked on 2026-07-19, built two months
later: a Tags screen in the side menu, a picker replacing free-text entry,
rename-with-merge, delete, and per-tag character lists.

The design write-up that used to live here has been superseded by what was
actually built — see **`decisions_log_tags.md`**, which records the eleven
decisions taken, the ordering trap in `renameTag`, and the disposed-controller
bug found while testing.

Left here as a marker so the 2026-07-19 "parked" decision doesn't look like it
was quietly dropped.
