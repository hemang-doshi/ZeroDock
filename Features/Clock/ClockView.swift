import SwiftUI

struct ClockView: View {
    var showSeconds: Bool
    var ambient = false
    var body: some View {
        Group {
            if showSeconds {
                TimelineView(.periodic(from: .now, by: 1)) { context in face(at: context.date) }
            } else {
                TimelineView(.everyMinute) { context in face(at: context.date) }
            }
        }
    }

    /// Ambient mode nudges the face a few points each minute so static pixels never sit still on OLED.
    private func drift(at date: Date) -> CGSize {
        guard ambient else { return .zero }
        let minute = Double(Calendar.current.component(.minute, from: date))
        return CGSize(width: sin(minute * 0.9) * 12, height: cos(minute * 0.7) * 8)
    }

    private func face(at date: Date) -> some View {
        let offset = drift(at: date)
        return VStack(alignment: ambient ? .center : .leading, spacing: ambient ? DockLayout.tight : DockLayout.tight) {
            Text(date, format: .dateTime.weekday(.wide).month(.wide).day())
                .font(DockType.heading)
                .foregroundStyle(ambient ? Color(red: 1.0, green: 0.78, blue: 0.6).opacity(0.55) : DockTheme.accent)
            Text(date, format: showSeconds ? .dateTime.hour().minute().second() : .dateTime.hour().minute())
                .font(DockType.display(ambient ? 128 : 84, weight: .light))
                .foregroundStyle(ambient ? Color(red: 1.0, green: 0.86, blue: 0.7).opacity(0.85) : .white)
                .monospacedDigit()
                .minimumScaleFactor(0.4)
                .lineLimit(1)
                .contentTransition(.numericText())
                .accessibilityIdentifier("liveClock")
        }
        .frame(maxWidth: .infinity, alignment: ambient ? .center : .leading)
        .offset(offset)
        .animation(.easeInOut(duration: 3), value: offset.width)
    }
}
