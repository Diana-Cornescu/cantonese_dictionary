# Cantonese Dictionary App

A fully local, offline-first dictionary app for Cantonese characters — you add characters yourself, along with your own definitions, and the app grows into your own personal, self-built reference over time. Includes star/hard shortlists, cross-references between related characters, flashcard practice with tracked stats, photos of characters seen out and about, and backup & restore to a single file. No servers, no accounts, and no internet connection required at any point — everything runs and stays on your device.

## Status

Released and in daily use on an Android phone, and runnable on Windows for development. See `CHANGELOG.md` for what shipped when, `docs/roadmap.md` for what's next, and `docs/known_limitations.md` for what it still can't do.

**Storage** is a local **SQLite database via Drift**, fully offline and on-device. After changing any table, rerun code generation (see "Database code generation" in `docs/setup_manual.md`). Full reasoning is in `docs/decisions/storage.md`.

## Documentation

- `docs/roadmap.md` — **what's next**: everything ahead, in release-sized buckets. Nothing that already shipped.
- `docs/known_limitations.md` — what's true of the app *today*: what it can't do, and why.
- `docs/setup_manual.md` — a running checklist of everything needed to develop, run and release the app. Phase 6 is the release process.
- `docs/decisions/` — **one file per area, recording what was decided and why.** Read the code for *how*; these explain what the code can't tell you.
  - `ui-conventions.md` — the rules that apply across every screen (confirmations, what the three colors mean, the two "selected" looks, where destructive actions go).
  - `tags.md`, `photos.md`, `storage.md`, `backup-and-release.md` — one per feature area.
- `CHANGELOG.md` (repo root) — what changed in each release, in plain language. This is the project's history; the docs above only describe the present and the future.

**Writing a decision log:** one file per area under `docs/decisions/`, named for the area rather than dated. Record **what was decided and why it mattered**, not how it was implemented — the code covers how. The exception is a *how* the code can't explain on its own: an ordering that isn't obvious, a trap that cost real time, a constant whose value matters. Those belong in the log.

## Development conventions

- **No servers, no external services.** Everything the app does — storage, character lookups, backups — runs entirely on-device. No network permissions are requested.
- **Docs travel with every change.** Any change to functionality, scope or architecture gets a matching update to this README and to whichever file(s) under `docs/` it affects, in the same pass — not as a follow-up step. If you're a future session picking this project up: read `CHANGELOG.md`'s newest entry, then `docs/roadmap.md`. That's the fastest way to get current.
- **Confirm before destructive/content edits.** Editing a definition, notes, or tags, archiving, or deleting always goes through a confirmation dialog. Star/hard shortlist toggles are the deliberate exception and stay instant.
