import SwiftUI

struct AmbientView: View {
    var showSeconds: Bool
    var body: some View {
        ClockView(showSeconds: showSeconds, ambient: true)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("ambientDashboard")
    }
}
