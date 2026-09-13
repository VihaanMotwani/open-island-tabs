import Foundation
import Observation

enum CalendarViewMode: String, CaseIterable, Identifiable, Sendable {
    case day
    case month
    case year

    var id: Self { self }
}

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
    private(set) var viewMode: CalendarViewMode = .day
    private(set) var isLoading = false
    private(set) var isConnecting = false
    private(set) var hasError = false
    private(set) var requiresAppBundle = false

    @ObservationIgnored private let provider: any CalendarEventsProviding
    @ObservationIgnored private let calendar: Calendar
    @ObservationIgnored private var refreshGeneration = 0

    init(provider: any CalendarEventsProviding, calendar: Calendar = .autoupdatingCurrent, now: Date = .now, viewMode: CalendarViewMode = .day) {
        self.provider = provider
        self.calendar = calendar
        self.viewMode = viewMode
        selectedDate = calendar.startOfDay(for: now)
        today = calendar.startOfDay(for: now)
    }

    var visibleDates: [Date] {
        let distance = calendar.dateComponents([.day], from: today, to: selectedDate).day ?? 0
        let anchor = (-7...14).contains(distance) ? today : selectedDate
        return (-7...14).compactMap { calendar.date(byAdding: .day, value: $0, to: anchor) }
    }

    /// A fixed six-week grid avoids resizing the notch between months.
    var monthDates: [Date] {
        guard let month = calendar.dateInterval(of: .month, for: selectedDate) else { return [] }
        let leadingDays = (calendar.component(.weekday, from: month.start) - calendar.firstWeekday + 7) % 7
        guard let first = calendar.date(byAdding: .day, value: -leadingDays, to: month.start) else { return [] }
        return (0..<42).compactMap { calendar.date(byAdding: .day, value: $0, to: first) }
    }

    private var queryInterval: DateInterval? {
        switch viewMode {
        case .year:
            nil
        case .day:
            calendar.dateInterval(of: .day, for: selectedDate)
        case .month:
            if let first = monthDates.first, let last = monthDates.last,
               let end = calendar.date(byAdding: .day, value: 1, to: last) {
                DateInterval(start: first, end: end)
            } else {
                nil
            }
        }
    }

    var yearMonths: [Date] {
        guard let year = calendar.dateInterval(of: .year, for: selectedDate),
              let range = calendar.range(of: .month, in: .year, for: selectedDate) else { return [] }
        return (0..<range.count).compactMap { calendar.date(byAdding: .month, value: $0, to: year.start) }
    }

    func selectMonth(_ date: Date) async {
        guard let month = calendar.dateInterval(of: .month, for: date) else { return }
        selectedDate = month.start
        await setViewMode(.month)
    }

    func navigate(by offset: Int) async {
        let component: Calendar.Component = switch viewMode {
        case .day: .day
        case .month: .month
        case .year: .year
        }
        guard let period = calendar.dateInterval(of: component, for: selectedDate),
              let date = calendar.date(byAdding: component, value: offset, to: period.start) else { return }
        selectedDate = date
        events = []
        await refresh()
    }

    func goToToday(now: Date = .now) async {
        selectedDate = calendar.startOfDay(for: now)
        events = []
        await refresh(now: now)
    }

    func setViewMode(_ mode: CalendarViewMode) async {
        viewMode = mode
        events = []
        await refresh()
    }

    func events(on date: Date) -> [CalendarAgendaEvent] {
        guard let interval = calendar.dateInterval(of: .day, for: date) else { return [] }
        return events.filter { $0.start < interval.end && $0.end > interval.start }
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
        guard let interval = queryInterval else {
            events = []
            isLoading = false
            return
        }
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
        viewMode = .day
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
