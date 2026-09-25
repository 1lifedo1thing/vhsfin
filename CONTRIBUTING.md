# Contributing to VHSFin

Help keep movie night simple. Small fixes, thoughtful accessibility improvements, and clear bug reports are welcome.

## Start here

```sh
flutter pub get
flutter analyze
flutter test
flutter build web --release
```

See the [README](README.md) for device setup and self-hosting. Use your own Jellyfin test account and avoid including credentials, private server addresses, tokens, or copyrighted media in fixtures and screenshots.

## How the code fits together

| Location | Responsibility |
| --- | --- |
| `lib/features/*/*_page.dart` | Coordinate state and navigation; pass properties and callbacks into views |
| `lib/features/*/state/` | Riverpod providers, notifiers, and preferences |
| `lib/features/*/views/` | Screen layouts with plain constructor inputs |
| `lib/features/*/widgets/` | Reusable UI with plain constructor inputs |
| `lib/data/repositories/` | Jellyfin network requests |
| `lib/constants/theme.dart` | Shared colors, typography, and brand widget |
| `test/` | Behavioral and widget regression tests |
| `tool/` | Local development and asset helpers |

Keep Riverpod imports out of views and widgets. Prefer package imports and small widget classes over large helper methods. Preserve the single-screen playback experience and keep setup understandable for the adult configuring a child’s device.

## Before opening a pull request

- Explain the problem and the resulting behavior, with a screenshot for visual changes.
- Add a focused regression test for a bug when practical. Test behavior, not private implementation details.
- Run analysis and tests. For platform resources, compile that platform when available and say what you verified.
- Check narrow screens, large text, and keyboard controls when changing forms or navigation.
- Keep commits focused and use an imperative subject, such as “Fix shelf setup navigation”.

## Useful local checks

To replay the sleeve-art introduction, clear the single preferences key `vhsfin.art_onboarding_done.v1`, then reload with titles on the shelves. `make demo-onboarding` prints the steps. Avoid clearing all preferences just to replay one flow.

The artwork and exact generation prompts are documented in [assets/branding/README.md](assets/branding/README.md). Platform exports are checked in. On macOS, regenerate them with `python3 tool/generate_brand_assets.py`.

For playback changes, try a movie and a series, pause/resume, seek, eject during insertion, enter/exit fullscreen, and try an unreachable stream. Test your target device; browser playback is not proof of native playback compatibility.

## Reporting problems

Include the platform, Flutter/app version, Jellyfin version, steps to reproduce, expected result, and actual result. For video problems, include the container/codec and whether Jellyfin is transcoding. Remove passwords, tokens, authorization headers, and full stream URLs before sharing logs.

## Community

Be kind and keep contributions family-friendly. Discuss larger changes before investing in them. VHSFin should remain a small, welcoming place to pick a movie.

## License

By contributing, you agree your contributions are licensed under the same [PolyForm Noncommercial 1.0.0](LICENSE) terms as the rest of the project.
