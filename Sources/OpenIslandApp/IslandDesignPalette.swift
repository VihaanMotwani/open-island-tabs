import SwiftUI
import OpenIslandCore

enum IslandDesignPalette {
    enum Status {
        static let waitingAggregate = Color(red: 180.0 / 255.0, green: 139.0 / 255.0, blue: 91.0 / 255.0)
        static let waitingForApproval = Color(red: 188.0 / 255.0, green: 112.0 / 255.0, blue: 113.0 / 255.0)
        static let waitingForAnswer = Color(red: 193.0 / 255.0, green: 157.0 / 255.0, blue: 93.0 / 255.0)
        static let running = Color(red: 92.0 / 255.0, green: 132.0 / 255.0, blue: 185.0 / 255.0)
        static let completed = Color(red: 90.0 / 255.0, green: 145.0 / 255.0, blue: 105.0 / 255.0)
        static let inactive = V6Palette.paper.opacity(0.38)
        static let idle = V6Palette.paper.opacity(0.35)

        static func tint(for phase: SessionPhase) -> Color {
            switch phase {
            case .waitingForApproval:
                waitingForApproval
            case .waitingForAnswer:
                waitingForAnswer
            case .running:
                running
            case .completed:
                completed
            }
        }

        static func tint(for phase: SessionPhase, presence: IslandSessionPresence) -> Color {
            if phase == .waitingForApproval || phase == .waitingForAnswer {
                return tint(for: phase)
            }

            switch presence {
            case .running:
                return running
            case .active:
                return completed
            case .inactive:
                return inactive
            }
        }
    }
}
