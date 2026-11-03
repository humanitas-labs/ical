# Changelog

All notable changes to this project will be documented in this file.

## [0.3.0] - 2026-11-02

- `today`, `tomorrow`, and `week` now print each event's `ID:` so listings lead directly to `edit`/`remove --id` (issue #3).
- Recurring events also print an `Occurrence:` token; `edit` and `remove` accept `--occurrence <datetime>` to target that instance instead of the series' first occurrence.
- `--this-only` on a recurring event now requires `--occurrence`, since it previously changed the first occurrence silently.

## [0.2.0] - 2026-07-14

- Added Reminders support via the `reminders` subcommand family: `list`, `add`, `done`, `reopen`, `remove`, `edit`.
- Reminder options: `--due`, `--clear-due`, `--list`, `--notes`, `--clear-notes`, `--priority`, `--all`.
- Timed due dates create an absolute alarm so the reminder actually notifies; date-only due dates stay day-granularity.
- `done`, `reopen`, and `remove` accept `--id` or a unique `--title` match.
- Grouped event list output by day with date headers.
- New events default to the user's default calendar instead of the first writable calendar when `--calendar` is omitted.

## [0.1.0] - 2026-02-22

- Added recurring event support for `add`, `edit`, and `remove`.
- Added recurrence controls: `--recurrence`, `--recurrence-end`, `--clear-recurrence`, `--this-only`, `--all-future`.
- Fixed absolute datetime parsing so datetime inputs preserve time and ordering.
- Added parser and datetime regression tests for recurrence and absolute datetime behavior.
- Added CLI version command support via `ical version` and `ical --version`.
