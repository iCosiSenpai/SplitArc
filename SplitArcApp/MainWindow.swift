import SwiftUI

private enum AppSection: String, CaseIterable, Identifiable {
    case controllers = "Pairing Deck"
    case gamepad = "Input Lab"
    case mouse = "Pointer Studio"
    case gyro = "Motion Lab"
    case nfc = "Tag Bench"
    case settings = "Settings"

    var id: Self { self }

    var icon: String {
        switch self {
        case .controllers: "rectangle.connected.to.line.below"
        case .gamepad: "gamecontroller"
        case .mouse: "cursorarrow.motionlines"
        case .gyro: "gyroscope"
        case .nfc: "wave.3.right"
        case .settings: "slider.horizontal.3"
        }
    }

    var key: KeyEquivalent {
        switch self {
        case .controllers: "1"
        case .gamepad: "2"
        case .mouse: "3"
        case .gyro: "4"
        case .nfc: "5"
        case .settings: "6"
        }
    }
}

struct MainWindow: View {
    @State private var selection: AppSection? = .controllers

    var body: some View {
        NavigationSplitView {
            List(selection: $selection) {
                Section {
                    brand
                        .listRowSeparator(.hidden)
                }
                Section("Workspace") {
                    ForEach(AppSection.allCases.prefix(4)) { section in
                        sectionRow(section)
                    }
                }
                Section("Utility") {
                    ForEach(AppSection.allCases.suffix(2)) { section in
                        sectionRow(section)
                    }
                }
            }
            .navigationSplitViewColumnWidth(min: 178, ideal: 202, max: 245)
            .safeAreaInset(edge: .bottom) {
                WorkspaceStatus()
                    .padding(12)
                    .frame(maxWidth: .infinity)
            }
        } detail: {
            let section = selection ?? .controllers
            Group {
                switch section {
                case .controllers:
                    ControllersView { selection = .gamepad }
                case .gamepad: GamepadView()
                case .mouse: MouseView()
                case .gyro: GyroView()
                case .nfc: NFCView()
                case .settings: SettingsView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(.background.secondary)
            .navigationTitle(section.rawValue)
            .toolbar {
                ToolbarItem(placement: .primaryAction) { AgentToggle() }
            }
        }
    }

    private var brand: some View {
        HStack(spacing: 9) {
            HStack(spacing: 3) {
                Capsule().fill(ArcTheme.left).frame(width: 7, height: 16).offset(y: -2)
                Capsule().fill(ArcTheme.right).frame(width: 7, height: 16).offset(y: 2)
            }
            .padding(7)
            .background(ArcTheme.ink, in: .rect(cornerRadius: 8))
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text("SplitArc").font(.headline)
                ArcKicker(title: "Joy-Con 2")
            }
        }
        .padding(.vertical, 7)
        .accessibilityElement(children: .combine)
    }

    private func sectionRow(_ section: AppSection) -> some View {
        Button {
            selection = section
        } label: {
            Label(section.rawValue, systemImage: section.icon)
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .keyboardShortcut(section.key, modifiers: .command)
        .tag(section)
    }
}

private struct AgentToggle: View {
    @EnvironmentObject private var bridge: DaemonBridge

    var body: some View {
        Button {
            bridge.isDaemonRunning ? bridge.stopDaemon() : bridge.startDaemon()
        } label: {
            Label(bridge.isDaemonRunning ? "Stop Bluetooth" : "Start Bluetooth",
                  systemImage: bridge.isDaemonRunning ? "stop.fill" : "antenna.radiowaves.left.and.right")
        }
        .disabled(bridge.isAgentTransitioning)
    }
}

private struct WorkspaceStatus: View {
    @EnvironmentObject private var bridge: DaemonBridge

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Label(bridge.agentPhase.workspaceLabel, systemImage: "antenna.radiowaves.left.and.right")
                .font(.caption.weight(.semibold))
            Text("\(bridge.connectedControllerCount) of 2 connected")
                .font(.caption2.monospacedDigit())
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .arcPanel(radius: 10)
        .accessibilityElement(children: .combine)
    }
}

extension DaemonBridge.AgentPhase {
    var workspaceLabel: String {
        switch self {
        case .stopped: "Bluetooth stopped"
        case .starting: "Starting Bluetooth"
        case .running: "Bluetooth running"
        case .stopping: "Stopping Bluetooth"
        }
    }
}
