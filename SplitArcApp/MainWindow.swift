import SwiftUI

private enum AppSection: String, CaseIterable, Identifiable {
    case controllers = "Controllers"
    case gamepad = "Gamepad"
    case mouse = "Pointer"
    case gyro = "Motion"
    case nfc = "NFC"
    case settings = "Settings"

    var id: Self { self }

    var icon: String {
        switch self {
        case .controllers: "gamecontroller"
        case .gamepad: "dpad"
        case .mouse: "computermouse"
        case .gyro: "gyroscope"
        case .nfc: "wave.3.right"
        case .settings: "gearshape"
        }
    }
}

struct MainWindow: View {
    @State private var selection: AppSection? = .controllers

    var body: some View {
        NavigationSplitView {
            List(selection: $selection) {
                Section("Devices") {
                    sectionRow(.controllers)
                    sectionRow(.gamepad)
                    sectionRow(.mouse)
                    sectionRow(.gyro)
                }
                Section("Tools") {
                    sectionRow(.nfc)
                    sectionRow(.settings)
                }
            }
            .navigationSplitViewColumnWidth(min: 160, ideal: 196, max: 240)
            .safeAreaInset(edge: .bottom) {
                AgentStatus()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(14)
            }
        } detail: {
            let section = selection ?? .controllers
            Group {
                switch section {
                case .controllers: ControllersView()
                case .gamepad: GamepadView()
                case .mouse: MouseView()
                case .gyro: GyroView()
                case .nfc: NFCView()
                case .settings: SettingsView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .navigationTitle(section.rawValue)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    AgentToggle()
                }
            }
        }
    }

    private func sectionRow(_ section: AppSection) -> some View {
        Label(section.rawValue, systemImage: section.icon)
            .tag(section)
    }
}

private struct AgentToggle: View {
    @EnvironmentObject private var bridge: DaemonBridge

    var body: some View {
        Button {
            bridge.isDaemonRunning ? bridge.stopDaemon() : bridge.startDaemon()
        } label: {
            Label(bridge.isDaemonRunning ? "Stop Scanning" : "Start Scanning",
                  systemImage: bridge.isDaemonRunning ? "stop.fill" : "play.fill")
        }
        .disabled(bridge.isAgentTransitioning)
    }
}

private struct AgentStatus: View {
    @EnvironmentObject private var bridge: DaemonBridge

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Label(status, systemImage: bridge.isDaemonRunning ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(bridge.isDaemonRunning ? .green : .secondary)
            Text(bridge.connectedControllerCount == 1 ? "1 controller connected" : "\(bridge.connectedControllerCount) controllers connected")
                .foregroundStyle(.secondary)
        }
        .font(.caption)
        .accessibilityElement(children: .combine)
    }

    private var status: String {
        switch bridge.agentPhase {
        case .stopped: "Scanning stopped"
        case .starting: "Starting Bluetooth…"
        case .running: "Bluetooth agent active"
        case .stopping: "Stopping Bluetooth…"
        }
    }
}

#Preview {
    MainWindow()
        .environmentObject(DaemonBridge.shared)
        .environmentObject(DaemonBridge.shared.controllerStore)
        .frame(width: 960, height: 660)
}
