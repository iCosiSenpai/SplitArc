import AppKit
import SwiftUI

@main
struct SplitArcApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var bridge = DaemonBridge.shared

    var body: some Scene {
        Window("SplitArc", id: "dashboard") {
            MainWindow()
                .environmentObject(bridge)
                .environmentObject(bridge.controllerStore)
                .frame(minWidth: 800, minHeight: 590)
        }
        .defaultSize(width: 1120, height: 775)

        Window("SplitArc Event Console", id: "diagnostics") {
            LogsView()
                .frame(minWidth: 540, minHeight: 370)
        }
        .defaultSize(width: 740, height: 500)
        .defaultLaunchBehavior(.suppressed)

        Settings {
            SettingsView()
                .environmentObject(bridge)
        }

        MenuBarExtra("SplitArc", systemImage: "gamecontroller.fill") {
            SplitArcMenu()
                .environmentObject(bridge)
        }
    }
}

private struct SplitArcMenu: View {
    @EnvironmentObject private var bridge: DaemonBridge
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        Button("Show SplitArc") {
            openWindow(id: "dashboard")
            NSApp.activate()
        }
        Button("Cycle Pointer Speed", action: bridge.toggleMouseMode)
            .disabled(!bridge.isDaemonRunning)
        SettingsLink()
        Divider()
        Button("Quit SplitArc") { NSApp.terminate(nil) }
            .keyboardShortcut("q")
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        DaemonBridge.shared.startDaemon()
    }

    func applicationWillTerminate(_ notification: Notification) {
        DaemonBridge.shared.stopDaemon()
    }
}
