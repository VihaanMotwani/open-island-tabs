// Date strip and agenda layout adapted from TheBoredTeam/boring.notch,
// components/Calendar/BoringCalendar.swift, by Harsh Vardhan Goswami (2024)
// and contributors, licensed under GPL-3.0.
// Modified for Open Island on 2026-09-13: standalone tab, explicit connection,
// accessible date buttons, Reduce Motion support, and read-only event rows.
// See docs/calendar.md for source attribution and third-party notices.

import AppKit
import EventKit
import SwiftUI

struct CalendarAgendaView: View {
    let model: CalendarAgendaModel
    let lang: LanguageManager
    var isActive = true

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Namespace private var dateSelection

    private var calendar: Calendar { .autoupdatingCurrent }

    var body: some View {
        VStack(spacing: 10) {
            dateHeader
            dateStrip
            Rectangle().fill(.white.opacity(0.08)).frame(height: 1)
            agenda
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .padding(.horizontal, ExpandedNotchLayoutMetrics.safeContentHorizontalInset)
        .padding(.top, 8)
        .padding(.bottom, 10)
        .frame(height: ExpandedNotchLayoutMetrics.calendarContentHeight)
        .task(id: isActive) {
            if isActive { await model.refresh() }
        }
        .onReceive(NotificationCenter.default.publisher(for: .EKEventStoreChanged)) { _ in
            refreshIfActive()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            refreshIfActive()
        }
        .onReceive(NotificationCenter.default.publisher(for: .NSCalendarDayChanged)) { _ in
            refreshIfActive()
        }
    }

    private var dateHeader: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(model.selectedDate.formatted(.dateTime.month(.wide)))
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.white.opacity(0.92))
            Text(model.selectedDate.formatted(.dateTime.year()))
                .font(.system(size: 13))
                .foregroundStyle(.white.opacity(0.45))
            Spacer()
            Button(lang.t("calendar.today")) {
                select(.now)
            }
            .font(.system(size: 11, weight: .medium))
            .foregroundStyle(.white.opacity(0.75))
            .buttonStyle(.plain)
            .padding(.horizontal, 9)
            .padding(.vertical, 4)
            .background(.white.opacity(0.08), in: Capsule())
        }
    }

    private var dateStrip: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal) {
                HStack(spacing: 5) {
                    ForEach(model.visibleDates, id: \.self) { date in
                        dateButton(date)
                            .id(date)
                    }
                }
                .padding(.horizontal, 4)
                .padding(.vertical, 2)
            }
            .scrollIndicators(.hidden)
            .mask {
                HStack(spacing: 0) {
                    LinearGradient(colors: [.clear, .black], startPoint: .leading, endPoint: .trailing).frame(width: 8)
                    Rectangle()
                    LinearGradient(colors: [.black, .clear], startPoint: .leading, endPoint: .trailing).frame(width: 8)
                }
            }
            .onAppear { proxy.scrollTo(model.selectedDate, anchor: .center) }
            .onChange(of: model.selectedDate) {
                withAnimation(reduceMotion ? nil : .smooth(duration: 0.25)) {
                    proxy.scrollTo(model.selectedDate, anchor: .center)
                }
            }
        }
        .frame(height: 52)
        .animation(reduceMotion ? nil : .spring(response: 0.28, dampingFraction: 0.85), value: model.selectedDate)
    }

    private func dateButton(_ date: Date) -> some View {
        let selected = calendar.isDate(date, inSameDayAs: model.selectedDate)
        let today = calendar.isDate(date, inSameDayAs: model.today)
        return Button { select(date) } label: {
            VStack(spacing: 5) {
                Text(date.formatted(.dateTime.weekday(.abbreviated)))
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(.white.opacity(selected ? 0.9 : 0.48))
                Text(date.formatted(.dateTime.day()))
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(today && !selected ? Color(red: 1, green: 0.48, blue: 0.4) : .white.opacity(0.92))
            }
            .frame(width: 38, height: 47)
            .background {
                if selected {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(today ? Color(red: 0.85, green: 0.28, blue: 0.25) : .white.opacity(0.14))
                        .matchedGeometryEffect(id: "selected-day", in: dateSelection)
                }
            }
            .contentShape(RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(date.formatted(date: .complete, time: .omitted))
        .accessibilityAddTraits(selected ? .isSelected : [])
    }

    @ViewBuilder
    private var agenda: some View {
        if model.access != .authorized {
            connectionState
        } else if model.isLoading && model.events.isEmpty {
            ProgressView().controlSize(.small).frame(maxHeight: .infinity)
                .accessibilityLabel(lang.t("calendar.loading"))
        } else if model.hasError {
            VStack(spacing: 9) {
                Text(lang.t("calendar.loadError")).foregroundStyle(.white.opacity(0.6))
                Button(lang.t("calendar.retry")) { refreshIfActive() }
            }
            .font(.system(size: 12))
            .frame(maxHeight: .infinity)
        } else if model.events.isEmpty {
            VStack(spacing: 8) {
                Image(systemName: "calendar.badge.checkmark")
                    .font(.system(size: 23, weight: .light))
                    .foregroundStyle(.white.opacity(0.4))
                Text(lang.t("calendar.empty"))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.white.opacity(0.65))
            }
            .frame(maxHeight: .infinity)
        } else {
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(model.events) { event in
                        CalendarAgendaRow(event: event, lang: lang)
                    }
                }
            }
            .scrollIndicators(.hidden)
            .id(model.selectedDate)
        }
    }

    private var connectionState: some View {
        VStack(spacing: 8) {
            Text(lang.t("calendar.connectionTitle"))
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.white.opacity(0.88))
            Text(lang.t(connectionMessageKey))
                .font(.system(size: 11))
                .foregroundStyle(.white.opacity(0.55))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            if model.access != .restricted && !model.requiresAppBundle {
                Button {
                    if model.access == .notDetermined {
                        Task { await model.connect() }
                    } else if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Calendars") {
                        NSWorkspace.shared.open(url)
                    }
                } label: {
                    Text(lang.t(model.isConnecting ? "calendar.connecting" : model.access == .notDetermined ? "calendar.connect" : "calendar.settings"))
                        .font(.system(size: 11, weight: .semibold))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 7)
                        .foregroundStyle(.black.opacity(0.9))
                        .background(.white.opacity(0.9), in: Capsule())
                }
                .buttonStyle(.plain)
                .disabled(model.isConnecting)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var connectionMessageKey: String {
        if model.requiresAppBundle { return "calendar.appBundleRequired" }
        if model.hasError { return "calendar.connectError" }
        switch model.access {
        case .notDetermined, .authorized: return "calendar.connectionNote"
        case .denied, .writeOnly: return "calendar.denied"
        case .restricted: return "calendar.restricted"
        }
    }

    private func select(_ date: Date) {
        Task { await model.selectDate(date) }
    }

    private func refreshIfActive() {
        guard isActive else { return }
        Task { await model.refresh() }
    }
}

private struct CalendarAgendaRow: View {
    let event: CalendarAgendaEvent
    let lang: LanguageManager

    var body: some View {
        HStack(spacing: 10) {
            RoundedRectangle(cornerRadius: 2)
                .fill(Color(red: event.color.red, green: event.color.green, blue: event.color.blue))
                .frame(width: 3, height: 30)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 3) {
                Text(event.title.isEmpty ? lang.t("calendar.untitled") : event.title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.white.opacity(0.9))
                    .lineLimit(2)
                Text(event.calendarTitle)
                    .font(.system(size: 10))
                    .foregroundStyle(.white.opacity(0.45))
                    .lineLimit(1)
            }
            Spacer(minLength: 8)
            VStack(alignment: .trailing, spacing: 3) {
                if event.isAllDay {
                    Text(lang.t("calendar.allDay"))
                } else {
                    Text(event.start, style: .time)
                    Text(event.end, style: .time).foregroundStyle(.white.opacity(0.45))
                }
            }
            .font(.system(size: 10, weight: .medium).monospacedDigit())
            .foregroundStyle(.white.opacity(0.75))
            .fixedSize()
        }
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .overlay(alignment: .bottom) { Rectangle().fill(.white.opacity(0.05)).frame(height: 1) }
        .accessibilityElement(children: .combine)
    }
}
