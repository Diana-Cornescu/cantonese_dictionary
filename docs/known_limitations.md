# Known limitations

**What's true of the app today.** What's *next* is in `roadmap.md`; why
things are the way they are is in `decisions/`.

Update this whenever a limitation is fixed or a new one turns up, per the
"docs travel with every change" convention in the root `README.md`.

---

- **No handwriting recognition.** Adding a character means typing or pasting
  it; the app doesn't guess it from your drawing. Fully designed and parked
  — the write-up is in `roadmap.md` under Someday.

- **No internet, at all.** Not a limitation so much as a deliberate
  guarantee — the Android manifest requests no permissions, so network
  access is impossible rather than merely unused. See
  `decisions/network.md`; it's the reason backups go through the system
  file picker.

- **No cloud backup or automatic sync.** Data lives on the device. You can
  back everything up (database + photos) to one `.zip` through Settings and
  restore it on any device, including after reinstalling, and you choose
  where the file goes. It's manual only: nothing backs up on its own.

- **Single-device, single-user.** No accounts, no syncing between your phone
  and laptop — they're two independent dictionaries. Backup & restore can
  copy one to the other, but **restore replaces everything**; there's no
  merge.

- **No filtering by tag.** The filter icon on the home list and the
  gallery (1.6.0) offers ⭐, 🔥 and (in the gallery) unlinked, plus
  newest/oldest sorting; tag filtering isn't in it yet, because it needs a
  picker rather than one more toggle. The Tags screen lists a tag's characters, which is
  the workaround.

- **Every change repaints the whole app.** `main.dart` wraps `MaterialApp`
  in a `ListenableBuilder` on the store, so any save rebuilds the
  `Navigator` and its overlay too. It works, but it's the one known source
  of fragility — a rebuild landing while a dialog animates out turned one
  disposed controller into a ten-exception cascade. See Chores in
  `roadmap.md`.

- **Everything is held in memory.** `DictionaryStore` loads every character
  at startup and filters in Dart, rather than querying the database live.
  Fine at personal-dictionary scale. Worth changing if handwriting
  recognition gets built (it needs to compare against many stored drawings),
  if startup or search gets slow, or if multi-device sync is ever wanted.

- **The split view is breakpoint-based.** The character and translation
  windows switch between side-by-side and stacked on screen width; there's
  no draggable divider. Deferred until real usage showed what was worth
  making resizable — it still hasn't.

- **No Jyutping field, no audio, no stroke-order playback.** The handwriting
  model already records a timestamp per point specifically so playback could
  be added later without changing what's stored. It just isn't built.

- **No batch import.** Characters are added one at a time.

- **A character can have no typed text.** Since 1.5.0 a drawing or a photo
  is enough on its own, so `typedCharacter` may be empty and shows as a grey
  "missing" icon. Anything rendering it must go through
  `widgets/typed_character.dart`.

- **The date added can't be changed or backdated.** It's the day you tapped
  Save (the `created_at` column), shown under the definition on the character screen.
  There's no date picker on purpose (decided 2026-09-25), and
  `DictionaryStore.updateCharacter` ignores any attempt to change it.

- **Dark mode covers five of the eight color themes.** Cerulean, Teal,
  Iris, Violet and Plum have a dark version; Slate, Cobalt and Navy show
  Cerulean while the app is dark. And 🔥 red is dim on the dark background.
  Both are on the roadmap.

- **The first version was written without a compiler.** The environment the
  app was built in couldn't install the Flutter/Dart tooling, so v1 and the
  SQLite migration were hand-reviewed before reaching you and compiled for
  the first time on your laptop. This is also why the app uses a plain
  `ChangeNotifier` rather than a state-management package: nothing that
  needed code generation could be verified before you ran it.
