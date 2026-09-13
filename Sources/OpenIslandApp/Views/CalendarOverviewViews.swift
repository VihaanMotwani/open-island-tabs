import SwiftUI

struct CalendarMonthView: View {
    let model: CalendarAgendaModel
    let lang: LanguageManager
    private var calendar: Calendar { .autoupdatingCurrent }
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)

    var body: some View {
        VStack(spacing: 5) {
            HStack(spacing: 4) {
                ForEach(0..<7, id: \.self) { offset in
                    let weekday = (calendar.firstWeekday - 1 + offset) % 7
                    Text(calendar.shortStandaloneWeekdaySymbols[weekday])
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(.white.opacity(0.35))
                        .frame(maxWidth: .infinity)
                }
            }
            .accessibilityHidden(true)
            LazyVGrid(columns: columns, spacing: 3) {
                ForEach(model.monthDates, id: \.self) { date in
                    dayButton(date)
                }
            }
        }
        .frame(maxHeight: .infinity, alignment: .top)
    }

    private func dayButton(_ date: Date) -> some View {
        let selected = calendar.isDate(date, inSameDayAs: model.selectedDate)
        let today = calendar.isDate(date, inSameDayAs: model.today)
        let inMonth = calendar.isDate(date, equalTo: model.selectedDate, toGranularity: .month)
        let events = model.events(on: date)
        return Button {
            Task { await model.selectDate(date) }
        } label: {
            VStack(spacing: 2) {
                Text(date.formatted(.dateTime.day()))
                    .font(.system(size: 11, weight: today || selected ? .semibold : .medium, design: .rounded))
                    .foregroundStyle(today ? Color(red: 1, green: 0.48, blue: 0.4) : .white.opacity(inMonth ? 0.85 : 0.28))
                HStack(spacing: 2) {
                    ForEach(events.prefix(3)) { event in
                        Circle()
                            .fill(Color(red: event.color.red, green: event.color.green, blue: event.color.blue))
                            .frame(width: 3, height: 3)
                    }
                }
                .frame(height: 3)
                .accessibilityHidden(true)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 26)
            .background(selected ? .white.opacity(0.1) : .clear, in: RoundedRectangle(cornerRadius: 7))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(date.formatted(date: .complete, time: .omitted))
        .accessibilityValue(model.access == .authorized && !model.hasError && !model.isLoading ? "\(events.count) \(lang.t("calendar.events"))" : "")
        .accessibilityAddTraits(selected ? .isSelected : [])
    }
}

struct CalendarYearView: View {
    let model: CalendarAgendaModel
    private var calendar: Calendar { .autoupdatingCurrent }
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 6), count: 3)

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 6) {
                ForEach(model.yearMonths, id: \.self) { month in
                    monthButton(month)
                }
            }
        }
        .scrollIndicators(.hidden)
        .frame(maxHeight: .infinity, alignment: .top)
    }

    private func monthButton(_ month: Date) -> some View {
        let selected = calendar.isDate(month, equalTo: model.selectedDate, toGranularity: .month)
        let current = calendar.isDate(month, equalTo: model.today, toGranularity: .month)
        return Button {
            Task { await model.selectMonth(month) }
        } label: {
            HStack(spacing: 5) {
                Text(month.formatted(.dateTime.month(.wide)))
                    .font(.system(size: 11, weight: selected ? .semibold : .medium))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                if current {
                    Circle().fill(Color(red: 1, green: 0.48, blue: 0.4)).frame(width: 4, height: 4)
                }
            }
            .foregroundStyle(.white.opacity(selected ? 0.95 : 0.65))
            .frame(maxWidth: .infinity)
            .frame(height: 40)
            .background(.white.opacity(selected ? 0.12 : 0.04), in: RoundedRectangle(cornerRadius: 9))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(month.formatted(.dateTime.month(.wide).year()))
        .accessibilityAddTraits(selected ? .isSelected : [])
    }
}
