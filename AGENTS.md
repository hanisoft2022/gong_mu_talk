# Repository Guidelines

## Project Structure & Module Organization
Flutter source lives in `lib/`: `app/` root widgets, `bootstrap/` init, `core/` shared services (Firebase, ads, theming), `common/` UI utilities, `di/` injection, and `features/<domain>/` per domain (e.g. `community/`, `year_end_tax/`). Route definitions sit in `routing/`, localization in `l10n/`, and Firebase config in `firebase_options.dart`. Assets live in `assets/` (logos, animations, salary tables). Cloud Functions live in `functions/` (TypeScript) with their own npm scripts. Mirror feature layouts under `test/` so widget, bloc, and model tests sit next to their code.

## Build, Test, and Development Commands
Fetch dependencies with `flutter pub get` and keep generated files in sync via `dart run build_runner build --delete-conflicting-outputs` (use `watch` while iterating). Launch the app with `flutter run` on a simulator or device, and build releases with `flutter build apk` / `flutter build ipa`. Guard quality using `flutter analyze` and `flutter format lib test`. Run the suite with `flutter test`; add `--coverage` when coverage is needed. For backend changes, operate from `functions/` using `npm install`, `npm run lint`, `npm run build`, and `firebase emulators:start --only functions,firestore,auth,storage`.

## Coding Style & Naming Conventions
Follow `flutter_lints` plus `prefer_const_constructors` and `prefer_const_literals_to_create_immutables`. Keep indentation at two spaces and use trailing commas to help the formatter. Name files `snake_case.dart`, classes `UpperCamelCase`, members `lowerCamelCase`. Define immutable models with `freezed` + `json_serializable`, commit generated files, and rerun `build_runner` when annotations change.

## Testing Guidelines
Write widget and bloc tests with `flutter_test`, `bloc_test`, and `mocktail`, placing each test in a mirrored directory such as `test/features/profile/presentation/`. Name files with `_test.dart` and describe behaviors in plain language (`loads salary table for grade`). Use Firebase emulators for integration flows and seed Firestore data in `setUp`. Before review, ensure `flutter test --coverage` succeeds.

## Commit & Pull Request Guidelines
Adopt short, imperative commit messages prefixed with a change type (`feat: add pension rate comparer`, `fix: correct lounge filter`). Keep scope focused; separate formatting-only passes from feature work. PRs should summarize the why and what, reference issues, and attach before/after screenshots or recordings for UI work. Confirm `flutter analyze`, `flutter test`, and relevant `functions` scripts have passed, and call out follow-up tasks or known gaps for reviewers.
