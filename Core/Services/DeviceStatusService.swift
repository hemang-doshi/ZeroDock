import UIKit
import Observation

@MainActor @Observable
final class DeviceStatusService {
    private(set) var snapshot = DeviceSnapshot(system: "iOS \(UIDevice.current.systemVersion)", model: UIDevice.current.model)

    func refresh(active: Bool) {
        UIDevice.current.isBatteryMonitoringEnabled = active
        guard active else { return }
        let device = UIDevice.current
        snapshot.percentage = device.batteryLevel < 0 ? nil : Int((device.batteryLevel * 100).rounded())
        switch device.batteryState {
        case .charging: snapshot.power = "Charging"
        case .full: snapshot.power = "Fully charged"
        case .unplugged: snapshot.power = "On battery"
        default: snapshot.power = "Power unavailable"
        }
        snapshot.lowPower = ProcessInfo.processInfo.isLowPowerModeEnabled
    }
}
