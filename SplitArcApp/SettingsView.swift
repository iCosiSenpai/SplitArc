import ServiceManagement
import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var bridge: DaemonBridge
    @Environment(\.openWindow) private var openWindow
    @AppStorage("sdlOnlyMode") private var sdlOnlyMode = false
    @State private var launchAtLogin = SMAppService.mainApp.status == .enabled
    @State private var loginError: String?

    var body: some View {
        ArcPage {
            ArcHeading(index: "06 / System", title: "Settings",
                       summary: "Control startup, virtual input and diagnostics for this Mac.")
            section("Startup", icon: "power") {
                Toggle("Open SplitArc at login", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { _, enabled in setLaunchAtLogin(enabled) }
            }
            section("Virtual input", icon: "puzzlepiece.extension") {
                if DaemonBridge.canEnableDriver {
                    Toggle("SDL compatibility mode", isOn: $sdlOnlyMode)
                        .onChange(of: sdlOnlyMode) { _, enabled in bridge.setSDLOnlyMode(enabled) }
                    Text("Use a single DualSense-compatible gamepad with SDL and cloud gaming clients.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Button("Enable Driver", systemImage: "arrow.down.circle", action: bridge.installAndLoadDriver)
                    if !bridge.driverInstallStatus.isEmpty {
                        Text(bridge.driverInstallStatus)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .textSelection(.enabled)
                    }
                } else {
                    ArcBadge(title: "Bluetooth preview", symbol: "info.circle")
                    Text("Gamepad and pointer output in other apps requires an Apple-provisioned DriverKit build.")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
            }
            section("Diagnostics", icon: "waveform.path.ecg") {
                HStack {
                    Button("Open Event Console", systemImage: "terminal") { openWindow(id: "diagnostics") }
                    Button("Restart Bluetooth", systemImage: "arrow.clockwise", action: bridge.restartDaemon)
                        .disabled(bridge.isAgentTransitioning)
                }
            }
            section("About SplitArc", icon: "info.circle") {
                LabeledContent("Version", value: Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "—")
                Link("Source code", destination: URL(string: "https://github.com/iCosiSenpai/SplitArc")!)
            }
        }
        .frame(minWidth: 460, idealHeight: 570)
        .alert("Could not change login setting", isPresented: Binding(
            get: { loginError != nil },
            set: { if !$0 { loginError = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(loginError ?? "")
        }
    }

    private func section<Content: View>(_ title: String, icon: String,
                                       @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(title, systemImage: icon)
                .font(.headline)
                .accessibilityAddTraits(.isHeader)
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .arcPanel()
    }

    private func setLaunchAtLogin(_ enabled: Bool) {
        let service = SMAppService.mainApp
        if enabled == (service.status == .enabled) { return }
        do {
            if enabled {
                try service.register()
            } else {
                try service.unregister()
            }
        } catch {
            loginError = error.localizedDescription
            launchAtLogin = service.status == .enabled
        }
    }
}

struct LogsView: View {
    @ObservedObject private var telemetry = TelemetryStore.shared
    @State private var query = ""

    private var visibleEntries: [TelemetryStore.Entry] {
        guard !query.isEmpty else { return telemetry.entries }
        return telemetry.entries.filter { $0.message.localizedCaseInsensitiveContains(query) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ArcHeading(index: "UTILITY / SESSION", title: "Event Console",
                       summary: "Recent Bluetooth, agent and driver events are kept in memory.")
                .padding(20)
            HStack {
                TextField("Filter events", text: $query)
                    .textFieldStyle(.roundedBorder)
                Button("Copy Events", systemImage: "doc.on.doc", action: telemetry.copyToClipboard)
                    .disabled(telemetry.entries.isEmpty)
                Button("Clear", systemImage: "trash", action: telemetry.clear)
                    .disabled(telemetry.entries.isEmpty)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 14)
            if visibleEntries.isEmpty {
                ContentUnavailableView(query.isEmpty ? "No events yet" : "No matching events",
                                       systemImage: query.isEmpty ? "waveform" : "magnifyingglass")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(visibleEntries.reversed()) { entry in
                        HStack(alignment: .firstTextBaseline, spacing: 13) {
                            Text(entry.time.formatted(date: .omitted, time: .standard))
                                .foregroundStyle(.secondary)
                                .frame(width: 90, alignment: .leading)
                            Text(entry.message)
                                .textSelection(.enabled)
                        }
                        .font(.system(.caption, design: .monospaced))
                        .padding(.vertical, 3)
                    }
                }
                .listStyle(.inset)
            }
        }
    }
}
