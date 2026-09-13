import Foundation
import Testing
@testable import OpenIslandApp

@MainActor
struct CalendarAgendaModelTests {
    @Test
    func reopeningAfterMidnightAdvancesToday() async {
        let provider = CalendarProviderStub()
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let model = CalendarAgendaModel(provider: provider, calendar: calendar, now: date("2026-09-13T23:59:00Z"))

        await model.refresh(now: date("2026-09-14T00:01:00Z"))

        #expect(model.selectedDate == date("2026-09-14T00:00:00Z"))
        #expect(model.today == date("2026-09-14T00:00:00Z"))
        #expect(model.visibleDates.contains(date("2026-09-14T00:00:00Z")))
    }

    @Test
    func connectingFromARawExecutableExplainsTheMissingAppBundleAndCanRetry() async {
        let provider = CalendarProviderStub()
        provider.requestError = CalendarProviderError.appBundleRequired
        let model = CalendarAgendaModel(provider: provider)

        await model.connect()

        #expect(model.requiresAppBundle)
        #expect(!model.isConnecting)
        #expect(model.access == .notDetermined)

        provider.requestError = nil
        await model.connect()

        #expect(!model.requiresAppBundle)
        #expect(!model.hasError)
        #expect(model.access == .authorized)
    }

    @Test(arguments: [CalendarAccess.denied, .restricted, .writeOnly])
    func losingReadAccessDuringAQueryClearsTheAgenda(_ status: CalendarAccess) async {
        let provider = CalendarProviderStub()
        provider.status = .authorized
        provider.holdReads = true
        let model = CalendarAgendaModel(provider: provider)
        let pending = Task { await model.refresh() }
        while provider.pendingReads.isEmpty { await Task.yield() }

        provider.status = status
        provider.pendingReads[0].resume(returning: [
            CalendarAgendaEvent(id: "private", title: "Private event", start: .now,
                                end: Date.now.addingTimeInterval(60), isAllDay: false, calendarTitle: "Work")
        ])
        await pending.value

        #expect(model.access == status)
        #expect(model.events.isEmpty)
        #expect(!model.isLoading)
        #expect(provider.accessRequestCount == 0)
    }

    @Test
    func aSlowEarlierDayCannotReplaceTheLatestSelectedDay() async {
        let provider = CalendarProviderStub()
        provider.status = .authorized
        provider.holdReads = true
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let model = CalendarAgendaModel(provider: provider, calendar: calendar)
        let first = Task { await model.selectDate(date("2026-09-13T12:00:00Z")) }
        while provider.pendingReads.count < 1 { await Task.yield() }
        let second = Task { await model.selectDate(date("2026-09-14T12:00:00Z")) }
        while provider.pendingReads.count < 2 { await Task.yield() }
        let newest = event("newest", start: "2026-09-14T10:00:00Z", end: "2026-09-14T11:00:00Z")

        provider.pendingReads[1].resume(returning: [newest])
        await second.value
        provider.pendingReads[0].resume(returning: [event("older", start: "2026-09-13T10:00:00Z", end: "2026-09-13T11:00:00Z")])
        await first.value

        #expect(model.events.map(\.id) == ["newest"])
        #expect(model.selectedDate == date("2026-09-14T00:00:00Z"))
        #expect(!model.isLoading)
    }

    @Test
    func selectingADayShowsOnlyOverlappingEventsAcrossDaylightSaving() async {
        let provider = CalendarProviderStub()
        provider.status = .authorized
        provider.items = [
            event("tomorrow", start: "2026-03-09T07:00:00Z", end: "2026-03-09T08:00:00Z"),
            event("meeting", start: "2026-03-08T18:00:00Z", end: "2026-03-08T19:00:00Z"),
            event("yesterday", start: "2026-03-08T07:00:00Z", end: "2026-03-08T08:00:00Z"),
            event("overnight", start: "2026-03-08T07:00:00Z", end: "2026-03-08T09:00:00Z"),
            event("all-day", start: "2026-03-08T08:00:00Z", end: "2026-03-09T07:00:00Z", allDay: true),
        ]
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/Los_Angeles")!
        let model = CalendarAgendaModel(provider: provider, calendar: calendar)

        await model.selectDate(date("2026-03-08T20:00:00Z"))

        #expect(model.selectedDate == date("2026-03-08T08:00:00Z"))
        #expect(provider.lastInterval?.end == date("2026-03-09T07:00:00Z"))
        #expect(model.events.map(\.id) == ["all-day", "overnight", "meeting"])
    }

    @Test
    func openingCalendarWaitsForConnectBeforeRequestingAccess() async {
        let provider = CalendarProviderStub()
        let model = CalendarAgendaModel(provider: provider)

        await model.refresh()

        #expect(model.access == .notDetermined)
        #expect(model.events.isEmpty)
        #expect(provider.accessRequestCount == 0)

        await model.connect()

        #expect(model.access == .authorized)
        #expect(provider.accessRequestCount == 1)
    }

    private func date(_ value: String) -> Date { ISO8601DateFormatter().date(from: value)! }

    private func event(_ id: String, start: String, end: String, allDay: Bool = false) -> CalendarAgendaEvent {
        CalendarAgendaEvent(id: id, title: id, start: date(start), end: date(end),
                            isAllDay: allDay, calendarTitle: "Work")
    }
}

@MainActor
private final class CalendarProviderStub: CalendarEventsProviding {
    var status: CalendarAccess = .notDetermined
    var accessRequestCount = 0
    var items: [CalendarAgendaEvent] = []
    var lastInterval: DateInterval?
    var holdReads = false
    var pendingReads: [CheckedContinuation<[CalendarAgendaEvent], Error>] = []
    var requestError: (any Error)?

    func authorizationStatus() async -> CalendarAccess { status }

    func requestAccess() async throws -> Bool {
        accessRequestCount += 1
        if let requestError { throw requestError }
        status = .authorized
        return true
    }

    func events(in interval: DateInterval) async throws -> [CalendarAgendaEvent] {
        lastInterval = interval
        if holdReads {
            return try await withCheckedThrowingContinuation { pendingReads.append($0) }
        }
        return items
    }
}
