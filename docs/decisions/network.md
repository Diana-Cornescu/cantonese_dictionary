# No network, enforced by the OS

**Decided 2026-07-19, still true.** The app is offline. What makes that
worth its own file is that it isn't a promise the code keeps — it's a thing
the app is structurally incapable of breaking.

---

## The decision

**`android/app/src/main/AndroidManifest.xml` declares no
`<uses-permission>` lines at all** — not `INTERNET`, not anything.

On Android, network access is permission-gated. An app without
`android.permission.INTERNET` doesn't get a polite refusal; every socket it
opens fails at the OS level. So the guarantee isn't "we don't call out",
it's "we can't".

## Why that's different from "doesn't need the internet"

"Doesn't need it" is a property of today's code, and today's code changes.
"Can't have it" holds regardless of:

- **A dependency that phones home.** Analytics bundled into some future
  package would simply fail. You don't have to audit every transitive
  dependency for outbound calls.
- **A bug.** No amount of wrong code can upload your dictionary or your
  photos, because there is no socket to upload them through.
- **Someone reading the repo.** It's public. Anyone can verify the claim by
  looking at one file, rather than taking the README's word for it.

The app's data is your handwriting, your photos of things you saw, and what
you're bad at remembering. Making exfiltration impossible rather than
merely absent is proportionate to that.

## What it costs

This is the reason for two things that would otherwise look like odd
choices:

- **Backups go through the system file picker.** With no storage
  permissions either, the picker is the only way to write outside the app's
  own sandbox — and the app's own storage is deleted on uninstall, which is
  exactly when you'd want a backup. See `backup-and-release.md`.
- **No handwriting recognition via a model.** Recognition has to work by
  matching against your own stored drawings, since there's no bundled model
  and no way to fetch one. See the parked design in `roadmap.md`.

It also means the app requests **zero permissions**, which is visible to
anyone installing it.

---

## The way this gets broken

**Manifest merging.** Add a package that needs the internet and its
manifest is merged into yours at build time — silently adding
`INTERNET` without you writing a line of it. Nothing warns you.

**After adding any dependency, check the merged manifest:**

```
build/app/outputs/logs/manifest-merger-release-report.txt
```

It shows every permission in the final manifest and which library asked for
it. If `INTERNET` appears, that's a decision to take deliberately — not one
to discover later.
