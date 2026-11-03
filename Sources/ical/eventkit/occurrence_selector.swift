import Foundation

/// Formats and matches recurring-event occurrence tokens.
///
/// EventKit gives every occurrence of a recurring series the same `eventIdentifier`, and
/// `event(withIdentifier:)` returns the first occurrence. Listings therefore print an
/// `Occurrence:` token (the instance's original start) that `edit`/`remove` accept via
/// `--occurrence` to target the listed instance.
enum OccurrenceSelector {
    /// Formats an occurrence date as ISO 8601 with the local UTC offset, e.g. `2026-11-03T14:00:00-08:00`.
    static func token(for date: Date, timeZone: TimeZone = .current) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        formatter.timeZone = timeZone
        return formatter.string(from: date)
    }

    /// Returns the index of the candidate whose identifier equals `id` and whose occurrence
    /// date is within one second of `occurrence`, or `nil` if none matches.
    static func matchIndex(id: String, occurrence: Date, candidates: [(id: String?, occurrenceDate: Date?)]) -> Int? {
        candidates.firstIndex { candidate in
            guard candidate.id == id, let date = candidate.occurrenceDate else {
                return false
            }
            return abs(date.timeIntervalSince(occurrence)) < 1
        }
    }
}
