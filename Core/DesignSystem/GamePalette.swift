import SwiftUI

extension DockMode {
    var symbol: String {
        switch self {
        case .focus: "timer"
        case .ambient: "moon.stars"
        case .gaming: "gamecontroller"
        }
    }
}
