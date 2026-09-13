import Foundation

/// Synthetic harness data. It never reads EventKit or asks for permissions.
struct CalendarPreviewProvider: CalendarEventsProviding {
    let access: CalendarAccess
    let items: [CalendarAgendaEvent]
    var viewMode: CalendarViewMode = .day

    func authorizationStatus() async -> CalendarAccess { access }
    func requestAccess() async throws -> Bool { access == .authorized }
    func events(in interval: DateInterval) async throws -> [CalendarAgendaEvent] { items }

    static func demoEvents(on day: Date) -> [CalendarAgendaEvent] {
        let calendar = Calendar.current
        let nextDay = calendar.date(byAdding: .day, value: 1, to: day)!
        func time(_ hour: Int, _ minute: Int = 0) -> Date {
            calendar.date(bySettingHour: hour, minute: minute, second: 0, of: day)!
        }
        return [
            CalendarAgendaEvent(id: "demo-all-day", title: "Design sprint", start: day, end: nextDay,
                                isAllDay: true, calendarTitle: "Team", color: .init(red: 0.65, green: 0.48, blue: 0.95)),
            CalendarAgendaEvent(id: "demo-review", title: "Product review", start: time(10), end: time(10, 30),
                                isAllDay: false, calendarTitle: "Work", color: .init(red: 0.35, green: 0.65, blue: 1)),
            CalendarAgendaEvent(id: "demo-coffee", title: "Coffee with the team", start: time(13), end: time(13, 45),
                                isAllDay: false, calendarTitle: "Personal", color: .init(red: 0.95, green: 0.6, blue: 0.3)),
            CalendarAgendaEvent(id: "demo-focus", title: "Focus time — finish the calendar", start: time(15), end: time(16),
                                isAllDay: false, calendarTitle: "Work", color: .init(red: 0.35, green: 0.65, blue: 1)),
        ]
    }
}
