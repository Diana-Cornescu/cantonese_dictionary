# Cantonese Dictionary App

A fully local, offline-first dictionary app for Cantonese characters — you add characters yourself, along with your own definitions, and the app grows into your own personal, self-built reference over time. Includes star/hard shortlists, cross-references between related characters, flashcard practice with tracked stats, and a JSON export. No servers, no accounts, and no internet connection required at any point — everything runs and stays on your device.

## Status

v1 implemented — all screens, local storage, and tests are written, and this is the first version ready for you to build and run. It was hand-written and hand-reviewed without a compiler available (the build environment couldn't reach the Flutter/Dart tooling — see `docs/decisions_log.md`'s 2026-07-20 entry), so your first `flutter pub get` / `flutter analyze` / `flutter test` on your own machine, per `docs/setup_manual.md`, is this code's real first verification pass. See `docs/design_plan.md` for the full architecture (tech stack, data model, screens, export format) and `docs/decisions_log.md` for a dated record of how we got here.

**2026-09-19:** storage moved from a single JSON file to a local **SQLite database via Drift**, still fully offline and on-device. The screens are unchanged. The code was again written without a compiler, so run the steps in `docs/setup_manual.md` (including the new "Database code generation" section) before anything else. Full reasoning is in `docs/decisions_log_sqlite_drift.md`.

## Documentation

- `docs/design_plan.md` — the living architecture/design plan for the app.
- `docs/future_ideas.md` — features considered and deliberately parked for a later version (e.g., handwriting recognition, a managed tag list), kept in full so they aren't lost.
- `docs/decisions_log_sqlite_drift.md` — the dated decisions, reasoning and TL;DR for the move from a JSON file to SQLite + Drift (kept separate so it's easy to find).
- `docs/decisions_log.md` — a running, dated record of notable decisions, pivots, and challenges as the app moves from plan to build.
- `docs/limitations_and_roadmap.md` — current limitations, storage trade-offs, and the future roadmap.
- `docs/setup_manual.md` — a running checklist of everything needed to develop and run the app, and the steps to set each piece up.

## Development conventions

- **No servers, no external services.** Everything the app does — storage, character lookups, exports — runs entirely on-device. No network permissions are requested.
- **Docs travel with every change.** Any change to functionality, scope, or architecture gets a matching update to this README and to whichever file(s) under `docs/` it affects (the design plan, the setup manual, the decisions log, and/or the future-ideas doc), in the same pass — not as a separate follow-up step. If you're a future session picking this project back up: read `docs/decisions_log.md` first, it's the fastest way to get current.
- **Confirm before destructive/content edits.** Editing a definition, notes, or tags, archiving, or deleting always goes through a confirmation dialog. Star/hard shortlist toggles are the deliberate exception and stay instant.
