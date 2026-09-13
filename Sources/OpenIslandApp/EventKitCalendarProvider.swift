// EventKit access and event mapping adapted from TheBoredTeam/boring.notch,
// Providers/CalendarServiceProviding.swift (GPL-3.0).
// Original Calendr source by Paker (2020); Boring Notch adaptation by Alexander (2025).
// Modified for Open Island on 2026-09-13: read-only events, actor isolation,
// Sendable values, occurrence identities, and explicit permission handling.
// See docs/calendar.md for the pinned source and attribution.

import CoreGraphics
import Foundation
@preconcurrency import EventKit

enum CalendarProviderError: Error {
    case appBundleRequired
}

/// EventKit queries run on this actor, keeping calendar reads off the UI actor.
/// No EventKit object crosses the boundary and no event-writing API is exposed.
actor EventKitCalendarProvider: CalendarEventsProviding {
    private lazy var store = EKEventStore()

    func authorizationStatus() -> CalendarAccess {
        switch EKEventStore.authorizationStatus(for: .event) {
        case .notDetermined: .notDetermined
        case .fullAccess: .authorized
        case .denied: .denied
        case .restricted: .restricted
        case .writeOnly: .writeOnly
        @unknown default: .restricted
        }
    }

    func requestAccess() async throws -> Bool {
        guard Bundle.main.object(forInfoDictionaryKey: "NSCalendarsFullAccessUsageDescription") != nil else {
            // A raw `swift run` binary has no privacy usage description. Avoid
            // an OS privacy termination; the UI explains how to launch the app.
            throw CalendarProviderError.appBundleRequired
        }
        return try await withCheckedThrowingContinuation { continuation in
            store.requestFullAccessToEvents { granted, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: granted)
                }
            }
        }
    }

    func events(in interval: DateInterval) -> [CalendarAgendaEvent] {
        guard authorizationStatus() == .authorized else { return [] }
        let predicate = store.predicateForEvents(withStart: interval.start, end: interval.end, calendars: nil)
        return store.events(matching: predicate).compactMap { event -> CalendarAgendaEvent? in
            guard let source = event.calendar, event.status != .canceled,
                  let start = event.startDate, let end = event.endDate else { return nil }
            let components = source.cgColor?
                .converted(to: CGColorSpace(name: CGColorSpace.sRGB)!, intent: .defaultIntent, options: nil)?
                .components
            let color = CalendarEventColor(
                red: Double(components?[0] ?? 0.5),
                green: Double(components?[1] ?? 0.65),
                blue: Double(components?[2] ?? 1)
            )
            return CalendarAgendaEvent(
                id: "\(source.calendarIdentifier):\(event.calendarItemIdentifier):\(start.timeIntervalSinceReferenceDate)",
                title: event.title ?? "",
                start: start,
                end: end,
                isAllDay: event.isAllDay,
                calendarTitle: source.title,
                color: color
            )
        }
    }
}
