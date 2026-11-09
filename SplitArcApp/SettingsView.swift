import SwiftUI

import ServiceManagement

struct SettingsView: View {
    @EnvironmentObject private var daemonBridge: DaemonBridge
    @Environment(\.openWindow) private var openWindow
    @AppStorage("sdlOnlyMode") private var sdlOnlyMode = false
    @State private var launchAtLogin = SMAppService.mainApp.status == .enabled
    @State private var loginError: String?

    var body: some View {
        Form {
            Section("General") {
                Toggle("Open SplitArc at login", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { _, enabled in
                        setLaunchAtLogin(enabled)
                    }
            }

            Section("Virtual Input") {
                Toggle("SDL compatibility mode", isOn: $sdlOnlyMode)
                    .onChange(of: sdlOnlyMode) { _, enabled in
                        daemonBridge.setSDLOnlyMode(enabled)
                    }
                Text("Show a single DualSense-compatible gamepad to SDL and cloud gaming clients.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if DaemonBridge.canEnableDriver {
                    SettingsActionRow(
                        icon: "puzzlepiece.extension",
                        title: "System gamepad and pointer",
                        subtitle: "Enable the virtual input driver to send controller and pointer input to other apps.",
                        buttonTitle: "Enable Driver",
                        role: nil,
                        action: daemonBridge.installAndLoadDriver
                    )
                } else {
                    Label("Virtual input requires a DriverKit-provisioned build.", systemImage: "puzzlepiece.extension")
                        .foregroundStyle(.secondary)
                }

                if !daemonBridge.driverInstallStatus.isEmpty {
                    Text(daemonBridge.driverInstallStatus)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .textSelection(.enabled)
                }
            }

            Section("Diagnostics") {
                Button("Open Diagnostics", systemImage: "waveform.path") {
                    openWindow(id: "diagnostics")
                }
                Button("Restart Bluetooth Agent", systemImage: "arrow.clockwise",
                       action: daemonBridge.restartDaemon)
                    .disabled(daemonBridge.isAgentTransitioning)
            }

            Section("About SplitArc") {
                LabeledContent("Version", value: Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "—")
                Link("Source code", destination: URL(string: "https://github.com/iCosiSenpai/SplitArc")!)
            }
        }
        .formStyle(.grouped)
        .frame(minWidth: 460, idealHeight: 510)
        .alert("Could not change login setting", isPresented: Binding(
            get: { loginError != nil },
            set: { if !$0 { loginError = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(loginError ?? "")
        }
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

struct SettingsActionRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let buttonTitle: String
    let role: ButtonRole?
    let action: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 17, weight: .medium))
                .foregroundColor(role == .destructive ? .red : .accentColor)
                .frame(width: 28, height: 28)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill((role == .destructive ? Color.red : Color.accentColor).opacity(0.12))
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body)
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer(minLength: 16)

            Button(role: role, action: action) {
                Text(buttonTitle)
                    .frame(minWidth: 72)
            }
        }
        .padding(.vertical, 4)
    }
}

struct LogsView: View {
    @ObservedObject private var telemetry = TelemetryStore.shared

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("SplitArc Telemetry")
                        .font(.headline)
                    Text("Live, memory-only event history")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Button("Copy") {
                    telemetry.copyToClipboard()
                }
                Button("Clear") {
                    telemetry.clear()
                }
            }
            .padding(12)

            Divider()

            ScrollView {
                ScrollViewReader { proxy in
                    VStack(alignment: .leading, spacing: 0) {
                        Text(telemetry.displayedOutput)
                            .font(.system(.caption, design: .monospaced))
                            .textSelection(.enabled)
                            .padding()
                            .id("bottom")
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .onChange(of: telemetry.telemetryLineCount) {
                        proxy.scrollTo("bottom", anchor: .bottom)
                    }
                }
            }
            .background(Color(NSColor.textBackgroundColor))
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(DaemonBridge.shared)
}
