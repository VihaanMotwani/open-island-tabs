import Foundation
import Observation

enum CalendarAccess: Equatable, Sendable {
    case notDetermined
    case authorized
    case denied
    case restricted
    case writeOnly
}

struct CalendarAgendaEvent: Identifiable, Equatable, Sendable {
    let id: String
    let title: String
    let start: Date
    let end: Date
    let isAllDay: Bool
    let calendarTitle: String
    var color: CalendarEventColor = .init(red: 0.5, green: 0.65, blue: 1)
}

struct CalendarEventColor: Equatable, Sendable {
    let red: Double
    let green: Double
    let blue: Double
}

/// The system boundary is EventKit. Tests supply events and authorization here,
/// so they never prompt for or read a developer's personal calendar.
protocol CalendarEventsProviding: Sendable {
    func authorizationStatus() async -> CalendarAccess
    func requestAccess() async throws -> Bool
    func events(in interval: DateInterval) async throws -> [CalendarAgendaEvent]
}

@MainActor
@Observable
final class CalendarAgendaModel {
    private(set) var access: CalendarAccess = .notDetermined
    private(set) var events: [CalendarAgendaEvent] = []
    private(set) var selectedDate: Date
    private(set) var today: Date
    private(set) var isLoading = false
    private(set) var isConnecting = false
    private(set) var hasError = false
    private(set) var requiresAppBundle = false

    @ObservationIgnored private let provider: any CalendarEventsProviding
    @ObservationIgnored private let calendar: Calendar
    @ObservationIgnored private var refreshGeneration = 0

    init(provider: any CalendarEventsProviding, calendar: Calendar = .autoupdatingCurrent, now: Date = .now) {
        self.provider = provider
        self.calendar = calendar
        selectedDate = calendar.startOfDay(for: now)
        today = calendar.startOfDay(for: now)
    }

    var visibleDates: [Date] {
        let distance = calendar.dateComponents([.day], from: today, to: selectedDate).day ?? 0
        let anchor = (-7...14).contains(distance) ? today : selectedDate
        return (-7...14).compactMap { calendar.date(byAdding: .day, value: $0, to: anchor) }
    }

    func refresh(now: Date = .now) async {
        let currentDay = calendar.startOfDay(for: now)
        if currentDay != today {
            if selectedDate == today { selectedDate = currentDay }
            today = currentDay
        }
        refreshGeneration += 1
        let generation = refreshGeneration
        let status = await provider.authorizationStatus()
        guard generation == refreshGeneration else { return }
        access = status
        hasError = false
        guard access == .authorized else {
            events = []
            isLoading = false
            return
        }
        guard let interval = calendar.dateInterval(of: .day, for: selectedDate) else { return }
        isLoading = true
        hasError = false
        defer { if generation == refreshGeneration { isLoading = false } }
        do {
            let loadedEvents = try await provider.events(in: interval)
            let currentAccess = await provider.authorizationStatus()
            guard generation == refreshGeneration else { return }
            access = currentAccess
            guard access == .authorized else {
                events = []
                return
            }
            events = loadedEvents
                .filter { event in
                    event.start < interval.end && event.end > interval.start
                }
                .sorted { lhs, rhs in
                    if lhs.isAllDay != rhs.isAllDay { return lhs.isAllDay }
                    if lhs.start != rhs.start { return lhs.start < rhs.start }
                    return lhs.id < rhs.id
                }
        } catch {
            guard generation == refreshGeneration else { return }
            events = []
            hasError = true
        }
    }

    func selectDate(_ date: Date) async {
        selectedDate = calendar.startOfDay(for: date)
        events = []
        await refresh()
    }

    func connect() async {
        guard !isConnecting else { return }
        isConnecting = true
        hasError = false
        requiresAppBundle = false
        defer { isConnecting = false }
        do {
            _ = try await provider.requestAccess()
            await refresh()
        } catch {
            requiresAppBundle = error is CalendarProviderError
            hasError = true
        }
    }
}
