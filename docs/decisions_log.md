# Cantonese Dictionary App — Decisions Log

A running, dated record of notable pivots, challenges hit, and how they were resolved, from initial planning through active development.

## 2026-07-19 — Initial planning round

- **Character detail view:** tapping a row opens a dedicated detail screen rather than expanding in place — simpler to implement inside a scrolling list.
- **Character window:** typed and handwritten views are shown via a toggle switch, not a resizable split.
- **Confirmation dialogs:** required before committing definition/notes/tag edits, archiving, or deleting. Star/hard shortlist toggles are the one exception and stay instant, since they're low-stakes and reversible with one more tap.
- **Handwriting storage:** only a single current drawing is kept per character — redrawing it overwrites the previous one, with no version history.
- **Handwriting recognition:** parked out of v1 as too complex for the value it would add this early; see `future_ideas.md`. Adding a character instead takes a typed/pasted character directly, alongside its handwritten drawing, with no auto-suggestion step.
- **Dynamic resizing:** left intentionally general until an early prototype clarifies which panes are actually worth making resizable.
- **Export format:** JSON only, no CSV option, since it represents tags and references cleanly without a second, lossier export path to maintain.
- **Documentation:** all project docs (this log, the plan, the setup manual, the limitations/roadmap doc, and parked ideas) live together under `docs/`.

## 2026-07-19 — Follow-up: framework, tags, and process conventions

- **Framework:** Flutter confirmed. No strong prior opinion on alternatives, comfortable proceeding on the recommendation.
- **Tags:** confirmed free-text for v1. A managed/reusable tag list was considered and parked — see `future_ideas.md`.
- **Documentation convention established:** every future change (feature, scope, or architecture) must be accompanied by corresponding updates to `README.md` and any other affected file under `docs/`. This is now written into the project `README.md` itself so it's discoverable in any future session, not just remembered in conversation.
- **Setup manual started:** `docs/setup_manual.md` created as a running checklist of everything needed to develop/run the app, to be kept current as new tools or steps are introduced (e.g., release signing, once we reach that point) rather than written only at the end.

No open questions remain from the initial planning round. Ready to move into implementation.

## 2026-07-20 — Implementation: sandbox constraint and architecture pivot

- **Sandbox constraint discovered:** the cloud environment used to write this app's code has no path to github.com, pub.dev, storage.googleapis.com, or any OS package mirror (all blocked at the network level). That meant the Flutter/Dart SDK could not be installed there, and `flutter pub get`/`analyze`/`test` could not be run there either — the code had to be hand-written and hand-reviewed, with no compiler available at any point during the build. This is a limitation of the cloud build environment only — your own Windows machine has normal internet access and none of this applies once the project is in your hands.
- **Architecture simplified as a direct result:** the original plan (section 1/2 of `design_plan.md`) called for Drift (SQL + code generation) and Riverpod (a state-management package). Both were dropped. Reasoning: Drift's codegen produces a generated file that's normally machine-checked by `build_runner`; hand-writing a stand-in for that generated code with no compiler to check it against was judged too risky to ship. Rather than hand-fake the generated output, the plan was simplified to remove the need for it entirely: persistence is now a single hand-written JSON file (atomic temp-file-then-rename writes, via `dart:io`/`dart:convert`), and state management is a plain `ChangeNotifier` (built into Flutter, not a package). `path_provider` remains the only third-party dependency. Net effect: fewer dependencies than originally planned (a bonus given the original minimalism request), same data actually stored, same app behavior — see the updated section 1/2 of `design_plan.md` for the corrected description.
- **Verification approach given no compiler:** every file was manually cross-checked after writing — imports resolve to real files, cross-file method/class references match actual declarations, and brace/paren/bracket balance was verified with a small purpose-built script (a naive first attempt at that script produced false positives from apostrophes inside string literals like "you're" — worth remembering if this comes up again). This is a careful hand-review, not a substitute for a real compile — your first `flutter pub get` / `flutter analyze` / `flutter test` run, per the updated `docs/setup_manual.md`, is this code's actual first verification pass. If it surfaces anything, that's expected to be genuinely possible, not a sign of a process failure.
- **`docs/setup_manual.md` updated:** added a step to run `flutter create --platforms=android,windows --org com.cantonesedictionary --project-name cantonese_dictionary .` inside the project as a one-time first action, since the `android/`/`windows/` platform folders (Gradle files, icons, Windows runner/CMake files) also couldn't be generated without the real Flutter tool.
- **`docs/limitations_and_roadmap.md` written:** this doc was planned from the start of the project but never actually produced until now — prompted by a question about the JSON-vs-database trade-off, which turned out to be exactly what this doc is for. It covers all current v1 limitations, a detailed breakdown of the storage architecture's trade-offs and concrete triggers for revisiting it, and the future-improvement roadmap (rolling up the two fully-designed parked ideas in `future_ideas.md` plus lighter-weight ideas not yet designed in detail).
