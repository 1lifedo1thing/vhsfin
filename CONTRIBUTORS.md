# Contributing to VHSFin

Thanks for helping make a tiny Jellyfin living-room client better.

## Getting started

```bash
flutter pub get
flutter analyze
flutter test
flutter run -d chrome   # or macos
```

## Architecture expectations

Feature code lives under `lib/features/<feature>/` with this split:

| Layer | Role |
| --- | --- |
| `*_page.dart` | Coordinator: watch Riverpod, call notifiers, pass **props + callbacks** into views |
| `state/` | Notifiers / providers / prefs (Riverpod OK) |
| `views/` | Screen UI — **no Riverpod imports** |
| `widgets/` | Reusable UI — **no Riverpod imports** |

Do not put `ref.watch` / `ConsumerWidget` inside views or widgets. Keep widgets testable with plain constructor args.

Prefer:

- Package imports (`package:vhsfin/...`), not relative imports
- Private `StatelessWidget`s instead of `_buildFoo()` helpers that return widgets
- Small, focused files over catch-all “utils”

## Commit style

- Focused commits; one logical chunk each
- Imperative subject line (“Add CRT rewind overlay”, not “Added…”)
- Explain **why** in the body when the diff is non-obvious

## Demo / QA helpers

- **Replay art grab:** Deck Settings → **REPLAY ART GRAB**, or `make demo-onboarding`
- Prefer not to wipe SharedPreferences wholesale when testing a single flow

## Pull requests

- Keep PRs reviewable; split unrelated refactors
- Note any intentional WIP / follow-ups in the PR description
- Run `flutter analyze` and `flutter test` before asking for review

## Code of conduct

Be kind. This is a kids-facing media player — keep contributions family-friendly.
