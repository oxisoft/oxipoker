# Contributing to Oxi Poker

Thanks for helping. A few rules keep the project healthy.

## Before you start

- **Bigger changes start as an issue.** Describe what you want to change and why, so we can agree on the approach before you spend time on code.
- **Small fixes** (typos, obvious bugs, translations) can go straight to a pull request.

## Contributor License Agreement

Every contributor signs the [CLA](CLA.md) once. A bot comments on your first pull request; reply with the sentence it asks for and you are done. The CLA keeps Oxi Poker open source under the AGPL for everyone, and lets OxiSoft publish official builds (for example in app stores whose terms conflict with the AGPL) and keep the licence options open for the project. You keep the copyright of your work.

## Development

- Server: Go 1.27. Run `go vet ./...` and `go test ./...` in `server/`.
- App: Flutter 3.50. Run `flutter analyze` and `flutter test` in `app/`.
- The server is the only authority on the game. Clients never receive another player's hole cards before they are shown at the table; a change that breaks this rule will not be merged.
- New behaviour comes with tests. The game engine in particular is tested hard: side pots, all-ins, split pots and disconnects.

## Pull requests

- One topic per pull request, with a clear title and a short description of what and why.
- CI must be green.
- Keep commits readable; we squash on merge when the history is noisy.

## Translations

The app speaks English, German, Spanish, French, Italian, Polish, Brazilian Portuguese, Russian, Turkish, Ukrainian, Japanese and Simplified Chinese. Everything except English was machine-translated first, so native speakers can make a real difference.

The strings live in `app/lib/l10n/app_<language>.arb`; `app_en.arb` is the source. To fix a translation, edit the line in your language's file and open a pull request. To add a language, copy `app_en.arb` to `app_<code>.arb`, set `@@locale`, translate the values (leave the `{placeholders}` as they are) and add the language to `appLanguages` in `app/lib/state/locale.dart`. The test `app/test/l10n_test.dart` checks that every file has every string.

The server sends error codes, never sentences; the app turns each code into a sentence in the player's language.

## Conduct

Everyone taking part follows the [Code of Conduct](CODE_OF_CONDUCT.md).
