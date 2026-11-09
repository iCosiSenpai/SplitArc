import Foundation
import GameController

GCController.shouldMonitorBackgroundEvents = true
let discoveryDeadline = ProcessInfo.processInfo.systemUptime + 3
var controllers: [GCController] = []
while ProcessInfo.processInfo.systemUptime < discoveryDeadline {
    RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))
    controllers = GCController.controllers().filter { $0.extendedGamepad != nil }
}

guard controllers.count == 1, let controller = controllers.first,
      let gamepad = controller.extendedGamepad else {
    print("Expected exactly one extended gamepad, found \(controllers.count).")
    for controller in controllers { print("  \(controller.vendorName ?? "Unnamed controller")") }
    exit(1)
}

controller.handlerQueue = .main
print("Testing \(controller.vendorName ?? "the detected controller"). Press A and move the left stick within 20 seconds.")
var sawButton = false
var sawStick = false
gamepad.valueChangedHandler = { pad, element in
    if let button = element as? GCControllerButtonInput, button.isPressed { sawButton = true }
    if abs(pad.leftThumbstick.xAxis.value) > 0.2 || abs(pad.leftThumbstick.yAxis.value) > 0.2 {
        sawStick = true
    }
}
let inputDeadline = ProcessInfo.processInfo.systemUptime + 20
while ProcessInfo.processInfo.systemUptime < inputDeadline && (!sawButton || !sawStick) {
    RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))
}

print("Button: \(sawButton ? "received" : "missing") · left stick: \(sawStick ? "received" : "missing")")
exit(sawButton && sawStick ? 0 : 1)
