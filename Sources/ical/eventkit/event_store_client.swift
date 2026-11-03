import EventKit
import Foundation

extension ICalApp {
    /// Synchronously requests full calendar access from EventKit.
    /// Uses `requestFullAccessToEvents` on macOS 14+ and falls back to `requestAccess(to:)` on older versions.
    /// - Returns: `true` if access was granted, `false` otherwise.
    func requestAccess() -> Bool {
        let semaphore = DispatchSemaphore(value: 0)
        var accessGranted = false

        if #available(macOS 14.0, *) {
            store.requestFullAccessToEvents { granted, error in
                accessGranted = granted && error == nil
                semaphore.signal()
            }
        } else {
            store.requestAccess(to: .event) { granted, error in
                accessGranted = granted && error == nil
                semaphore.signal()
            }
        }

        semaphore.wait()
        return accessGranted
    }

    /// Fetches all events within the given date interval, sorted by all-day status, start time, end time, then title.
    /// - Parameter dateInterval: The time range to query.
    /// - Returns: A sorted array of matching events.
    func fetchEvents(in dateInterval: DateInterval) -> [EKEvent] {
        let predicate = store.predicateForEvents(
            withStart: dateInterval.start,
            end: dateInterval.end,
            calendars: nil
        )

        return store.events(matching: predicate).sorted { lhs, rhs in
            if lhs.isAllDay != rhs.isAllDay {
                return lhs.isAllDay && !rhs.isAllDay
            }

            if lhs.startDate != rhs.startDate {
                return lhs.startDate < rhs.startDate
            }

            if lhs.endDate != rhs.endDate {
                return lhs.endDate < rhs.endDate
            }

            return eventTitle(lhs).localizedCaseInsensitiveCompare(eventTitle(rhs)) == .orderedAscending
        }
    }

    /// Resolves a writable calendar by name, falling back to the user's default calendar
    /// (or the first writable calendar) if no name is given.
    /// - Parameter name: Optional calendar name (case-insensitive match).
    /// - Returns: The matched `EKCalendar`, or a `CLIError` if none found.
    func writableCalendar(named name: String?) -> Result<EKCalendar, CLIError> {
        let writableCalendars = store.calendars(for: .event).filter { $0.allowsContentModifications }

        guard !writableCalendars.isEmpty else {
            return .failure(.message("No writable calendars found."))
        }

        guard let name = nonEmpty(name) else {
            if let defaultCalendar = store.defaultCalendarForNewEvents,
                defaultCalendar.allowsContentModifications {
                return .success(defaultCalendar)
            }
            return .success(writableCalendars[0])
        }

        if let selectedCalendar = writableCalendars.first(where: {
            $0.title.localizedCaseInsensitiveCompare(name) == .orderedSame
        }) {
            return .success(selectedCalendar)
        }

        let available = writableCalendars.map(\.title).joined(separator: ", ")
        return .failure(.message("Calendar not found: \(name). Writable calendars: \(available)"))
    }

    /// Returns the full-day interval (midnight to midnight) containing the given date.
    func dayInterval(containing date: Date) -> DateInterval? {
        let start = calendar.startOfDay(for: date)
        guard let end = calendar.date(byAdding: .day, value: 1, to: start) else {
            return nil
        }
        return DateInterval(start: start, end: end)
    }

    /// Resolves an event by identifier, optionally pinned to one occurrence of a recurring series.
    ///
    /// Without `occurrenceInput`, a recurring series resolves to its first occurrence (EventKit's behavior),
    /// so `--this-only` on a recurring event requires `--occurrence` to avoid editing the wrong instance.
    func resolveEvent(id: String, occurrenceInput: String?, selection: RecurrenceSpanSelection) -> Result<EKEvent, CLIError> {
        guard let seriesEvent = store.event(withIdentifier: id) else {
            return .failure(.message("Event not found for id: \(id)"))
        }

        guard let occurrenceInput else {
            if seriesEvent.hasRecurrenceRules, selection == .thisOnly {
                return .failure(.message(
                    "Event is recurring. Add --occurrence <start> (the Occurrence: value from today/tomorrow/week) to target one instance."
                ))
            }
            return .success(seriesEvent)
        }

        guard let occurrence = dateParser.parse(occurrenceInput) else {
            return .failure(.message("Could not parse --occurrence value: \(occurrenceInput)"))
        }

        guard
            let windowStart = calendar.date(byAdding: .day, value: -1, to: occurrence),
            let windowEnd = calendar.date(byAdding: .day, value: 1, to: occurrence)
        else {
            return .failure(.message("Could not determine search range for --occurrence."))
        }

        let predicate = store.predicateForEvents(withStart: windowStart, end: windowEnd, calendars: nil)
        let candidates = store.events(matching: predicate)
        let keys = candidates.map { (id: $0.eventIdentifier as String?, occurrenceDate: ($0.occurrenceDate ?? $0.startDate) as Date?) }

        guard let index = OccurrenceSelector.matchIndex(id: id, occurrence: occurrence, candidates: keys) else {
            return .failure(.message("No occurrence of \(id) starts at \(occurrenceInput)."))
        }
        return .success(candidates[index])
    }
}
