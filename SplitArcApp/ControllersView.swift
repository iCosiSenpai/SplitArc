import SwiftUI

struct ControllersView: View {
    @EnvironmentObject private var bridge: DaemonBridge
    @EnvironmentObject private var store: ControllerStore
    var openInputLab: () -> Void = {}

    var body: some View {
        ArcPage {
            PairingHero(connected: bridge.connectedControllerCount, phase: bridge.agentPhase,
                        start: bridge.startDaemon, openInputLab: openInputLab)
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 4) {
                    ArcKicker(title: "01 / Bluetooth")
                    Text("Controller bays").font(.title2.weight(.semibold))
                        .accessibilityAddTraits(.isHeader)
                }
                Spacer()
                Text("Player LEDs identify left and right at startup.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 14) {
                    bay(right: false)
                    bay(right: true)
                }
                VStack(spacing: 12) {
                    bay(right: false)
                    bay(right: true)
                }
            }
            Label(bridge.virtualGamepadReady ? "Virtual gamepad online" :
                    DaemonBridge.canEnableDriver ? "Virtual gamepad offline · enable the driver in Settings." :
                    "Bluetooth preview · game input is disabled.",
                  systemImage: bridge.virtualGamepadReady ? "gamecontroller.fill" : "puzzlepiece.extension")
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func bay(right: Bool) -> some View {
        ControllerBay(right: right, controller: store.controllers.first { $0.side == (right ? "right" : "left") })
            .frame(minWidth: 256, maxWidth: .infinity)
    }
}

private struct PairingHero: View {
    let connected: Int
    let phase: DaemonBridge.AgentPhase
    let start: () -> Void
    let openInputLab: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 11) {
                Text("SPLITARC / PAIRING DECK")
                    .font(.system(.caption2, design: .monospaced, weight: .semibold))
                    .tracking(2)
                    .foregroundStyle(ArcTheme.left)
                Text(connected == 2 ? "Pair complete." : connected == 1 ? "One side in." : "Bring both sides.")
                    .font(.system(size: 39, weight: .semibold))
                    .tracking(-1.7)
                    .accessibilityAddTraits(.isHeader)
                Text(connected == 2
                     ? "Both Joy-Con 2 controllers are linked. Open Input Lab to check buttons and sticks."
                     : "Hold SYNC on a Joy-Con 2 until its LEDs chase. SplitArc will pick it up over Bluetooth.")
                    .foregroundStyle(.white.opacity(0.78))
                    .font(.callout)
                    .fixedSize(horizontal: false, vertical: true)
                HStack(spacing: 10) {
                    if connected > 0 {
                        Button("Open Input Lab", systemImage: "arrow.up.right", action: openInputLab)
                            .buttonStyle(.borderedProminent)
                            .tint(ArcTheme.left)
                            .foregroundStyle(ArcTheme.ink)
                    } else if phase == .stopped {
                        Button("Start Bluetooth", systemImage: "play.fill", action: start)
                            .buttonStyle(.borderedProminent)
                            .tint(ArcTheme.left)
                            .foregroundStyle(ArcTheme.ink)
                    }
                    ArcBadge(title: "\(connected) / 2 linked", symbol: "link")
                }
                .padding(.top, 5)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 15) {
                JoyConIllustration(right: false)
                    .rotationEffect(.degrees(-13))
                    .offset(y: -9)
                JoyConIllustration(right: true)
                    .rotationEffect(.degrees(-13))
                    .offset(y: 9)
            }
            .frame(width: 188)
            .accessibilityHidden(true)
        }
        .padding(24)
        .frame(minHeight: 218)
        .foregroundStyle(.white)
        .background {
            ZStack {
                LinearGradient(colors: [ArcTheme.ink, ArcTheme.stage], startPoint: .topLeading, endPoint: .bottomTrailing)
                ArcGrid().mask {
                    LinearGradient(colors: [.clear, .black], startPoint: .leading, endPoint: .trailing)
                }
            }
        }
        .clipShape(.rect(cornerRadius: 20))
    }
}

private struct JoyConIllustration: View {
    let right: Bool

    var body: some View {
        let tint = ArcTheme.side(right)
        RoundedRectangle(cornerRadius: 26)
            .fill(LinearGradient(colors: [tint, tint.opacity(0.63)], startPoint: .topLeading, endPoint: .bottomTrailing))
            .overlay {
                RoundedRectangle(cornerRadius: 26)
                    .strokeBorder(.white.opacity(0.5), lineWidth: 1)
            }
            .overlay(alignment: .trailing) {
                Capsule().fill(ArcTheme.ink.opacity(0.6)).frame(width: 3, height: 69)
                    .padding(.trailing, 4)
            }
            .overlay {
                VStack(spacing: 10) {
                    if right { buttons; stick } else { stick; buttons }
                }
            }
            .frame(width: 65, height: 128)
            .shadow(color: tint.opacity(0.19), radius: 18, y: 5)
    }

    private var stick: some View {
        Circle().fill(ArcTheme.ink).frame(width: 23, height: 23)
            .overlay { Circle().strokeBorder(.white.opacity(0.22)).padding(3) }
    }

    private var buttons: some View {
        Image(systemName: "dpad.fill")
            .font(.system(size: 23))
            .foregroundStyle(ArcTheme.ink)
    }
}

private struct ControllerBay: View {
    let right: Bool
    let controller: ControllerState?

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 11) {
                Text(right ? "R" : "L")
                    .font(.system(.title3, design: .monospaced, weight: .bold))
                    .foregroundStyle(ArcTheme.ink)
                    .frame(width: 39, height: 39)
                    .background(ArcTheme.side(right), in: .rect(cornerRadius: 10))
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 3) {
                    Text(right ? "Right Joy-Con 2" : "Left Joy-Con 2").font(.headline)
                    Text("BLE  ·  LED \(right ? "02" : "01")")
                        .font(.system(.caption2, design: .monospaced))
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
                ArcBadge(title: status, symbol: statusSymbol)
            }
            Divider()
            Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 10) {
                GridRow {
                    metric("Battery", value: battery)
                    metric("Samples", value: controller.map { $0.packetCount.formatted() } ?? "—")
                }
                GridRow {
                    metric("Temperature", value: temperature)
                    metric("Optical sensor", value: optical)
                }
            }
        }
        .padding(16)
        .arcPanel()
    }

    private func metric(_ title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title).font(.caption).foregroundStyle(.secondary)
            Text(value).font(.system(.headline, design: .monospaced))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    private var status: String {
        guard let controller else { return "Waiting" }
        switch controller.status {
        case "commandTimeout": return "Timeout"
        case "connectFailed", "writeFailed": return "Error"
        case "connecting", "queued": return "Linking"
        case "initializing", "servicesReady", "bleConnected": return "Starting"
        default:
            if controller.isConnected { return controller.packetCount > 0 ? "Live" : "Linked" }
            return controller.status == "scanning" ? "Scanning" : "Offline"
        }
    }

    private var statusSymbol: String {
        if status == "Live" { return "waveform" }
        if status == "Error" || status == "Timeout" { return "exclamationmark.circle" }
        return controller?.isConnected == true ? "link" : "circle"
    }

    private var battery: String {
        guard let controller, controller.isConnected else { return "—" }
        if controller.batteryPercentage.isFinite && controller.batteryPercentage >= 0 {
            return "\(Int(min(controller.batteryPercentage, 100)))%"
        }
        if controller.batteryVoltageValid { return controller.batteryVoltage.formatted(.number.precision(.fractionLength(2))) + " V" }
        return "—"
    }

    private var temperature: String {
        guard let controller, controller.isConnected, controller.controllerTemperatureValid else { return "—" }
        return controller.controllerTemperature.formatted(.number.precision(.fractionLength(1))) + " °C"
    }

    private var optical: String {
        guard let controller, controller.isConnected, controller.packetCount > 0 else { return "—" }
        return controller.mouseDistance == 0 ? "On surface" : "Lifted"
    }
}
