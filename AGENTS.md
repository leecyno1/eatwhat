# Repository Guidelines

## Project Structure & Module Organization
- Flutter app. Source in `lib/`; tests in `test/`; assets in `assets/` (images/icons/data/dbs); platforms: `android`, `ios`, `macos`, `web`, `windows`, `linux`.
- App code: `lib/core/` (theme/routing/localization), `lib/features/` (feature modules), `lib/shared/` (constants/themes), `lib/screens/` (pages), `lib/demo/` (samples).
- Entry point: `lib/main.dart`. Docs live in `docs/`. Config: copy `.env.example` to `.env` (loaded via `flutter_dotenv`).

## Build, Test, and Development Commands
- `flutter pub get` — install dependencies.
- `dart run build_runner build --delete-conflicting-outputs` — generate code after model/DI changes.
- `flutter analyze` and `dart format .` — lint and auto‑format.
- `flutter test [--coverage]` — run unit/widget tests.
- `flutter run -d ios|android|chrome` — run locally on simulator/device/browser.
- `flutter build apk|ios|web` — production builds.

## Coding Style & Naming Conventions
- Follow `flutter_lints` from `analysis_options.yaml`.
- 2‑space indent; prefer single quotes; add trailing commas to aid formatter.
- Files: `snake_case.dart`; classes/types: `PascalCase`; variables/methods: `lowerCamelCase`.

## Testing Guidelines
- Use `flutter_test` (+ `mockito` for doubles).
- Tests mirror sources and end with `_test.dart` (e.g., `lib/features/recommendation/...` → `test/recommendation/..._test.dart`).
- Keep tests fast and deterministic; avoid time‑dependent or flaky async.
- Run `flutter test` before pushing.

## Commit & Pull Request Guidelines
- Conventional Commits: `feat:`, `fix:`, `chore:`, `docs:`, `refactor:`, `test:`.
  - e.g., `feat: improve recommendation engine scoring`
  - e.g., `fix: resolve ml_linalg version conflict`
- PRs: clear description, scope/impact, linked issues, screenshots/GIFs for UI, and test notes.
- Require green `flutter analyze` and passing tests.

## Security & Configuration Tips
- Do not commit secrets; use `.env`.
- Versioned DBs in `assets/data/` are intentional; update only via provided builders when schema/content changes.
