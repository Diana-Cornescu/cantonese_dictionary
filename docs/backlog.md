# Backlog

**Last updated:** 2026-09-19

What's still to do, in priority order. This is the single place to check "what's next". Detailed reasoning lives in the decision logs; this file only tracks what's left and how important it is.

**Priority:** 1 = do next · 2 = after that · 3 = nice to have. Work top to bottom.

---

## Priority 1: next up

| Item | Notes | Source |
|------|-------|--------|
| **Export, backup & restore** | 🧪 **Code written 2026-09-19, testing on the laptop.** Settings → Back up / Restore / Undo last restore. The readable JSON export was removed. | `decisions_log_backup_and_release.md` |
| **Choose where exports are saved** | 🧪 **Code written 2026-09-19.** System Save/Open window every time. | `decisions_log_backup_and_release.md` |
| **First release to the phone (1.0.0)** | Moved up from Priority 2. Create the signing key, switch the phone from debug to release, install. Steps in `setup_manual.md` Phase 6. | Personal_notes |

## Priority 2

| Item | Notes | Source |
|------|-------|--------|
| **Long "back" history** | Jumping between referenced characters stacks up screens, so "back" takes many presses. Keep the history shorter. Not critical. | Personal_notes ("2nd prio") |

## Priority 3

| Item | Notes | Source |
|------|-------|--------|
| **Restyle flashcard stats as boxes** | Move below the definition. A centered "last reviewed" line, then a row of boxes (Seen, Accuracy), then a row of boxes (Correct, Incorrect). | Personal_notes |
| **Clean up "info" lint hints** | `use_build_context_synchronously` (character detail screen), deprecated `withOpacity` (theme), `prefer_const`. Harmless style hints. | `flutter analyze`, 2026-09-19 |

## Not prioritized yet

| Item | Notes | Source |
|------|-------|--------|
| **Photo gallery screens** | Photos of characters seen out and about, for font identification. The database table already exists. | Personal_notes; `decisions_log_sqlite_drift.md` decision 5 |
| **Tag picker / managed tags UI** | Pick existing tags, rename once, filter by tag. The storage already exists. | `future_ideas.md`; decision 2 |
| **Handwriting recognition** | Designed and parked. | `future_ideas.md` |

---

## Removed

- **Remove the debug banner** (2026-09-19): not needed. The "DEBUG" corner banner only appears in debug builds, and release builds never show it. If it ever showed up in a release build, it would come back here as Priority 2.

## Done

- **Move storage to SQLite + Drift** (2026-09-19). See `decisions_log_sqlite_drift.md`.
- **Two rounds of UI edits** from Personal_notes (tags in the character screen, yellow star, colored accuracy, home button, hard-mode toggle, archive/delete moved, handwriting-only required, drawing clipped, SafeArea buttons). Done by 2026-07-23.
