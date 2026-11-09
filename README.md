# SplitArc

SplitArc connects Nintendo Switch 2 Joy-Con controllers to an Apple silicon Mac. The app shows battery, controls and motion over Bluetooth. Its DriverKit extension provides a virtual gamepad, pointer and gesture keyboard for macOS apps and games.

Requires an Apple silicon Mac running macOS Tahoe 26.0 or later. The app, Bluetooth agent and driver are all arm64. NFC is experimental.

## Build in Xcode

Open `SplitArc.xcodeproj` in Xcode 26 or later and select the **SplitArc** scheme. The project builds and embeds the Bluetooth agent and DriverKit extension. For an unsigned build from the terminal, run `./build_all.sh`. The resulting app is under `build/xcode/Build/Products/Release/`.

The Xcode project is checked in. If you change the target layout, regenerate it with `xcodegen generate`.

## Enable virtual input

1. Use a Developer ID build provisioned for the driver and its Bluetooth agent.
2. Move SplitArc to Applications and open it. Allow Bluetooth access when macOS prompts.
3. Open **Settings → Virtual Input → Enable Driver** and approve the extension in macOS when prompted.
4. Hold **SYNC** on each Joy-Con until the LEDs flash. Confirm both controllers in **Controllers** and test input in **Gamepad**.

Use **SDL compatibility mode** if a game sees duplicate gamepads. The virtual pointer and gesture keyboard remain available. A signed and notarized preview can still lack the Apple authorization required for virtual input. Apple handles notarization and DriverKit provisioning separately. [Apple DriverKit entitlement documentation](https://developer.apple.com/documentation/driverkit/requesting-entitlements-for-driverkit-development)

## Distribution

Request DriverKit authorization for `dev.icosisenpai.splitarc.driver` and user-client access for `dev.icosisenpai.splitarc.agent`. Configure Developer ID provisioning profiles for the driver, agent and host app (`dev.icosisenpai.splitarc`) in the Apple Developer account. [Apple System Extensions and DriverKit](https://developer.apple.com/system-extensions/)

Set `CODE_SIGN_IDENTITY` to a Developer ID Application identity, `NOTARY_PROFILE` to an existing notarytool Keychain profile, and `APP_PROVISIONING_PROFILE`, `DEXT_PROVISIONING_PROFILE` and `AGENT_PROVISIONING_PROFILE` to the downloaded profiles. Run `scripts/notarize.sh /absolute/path/SplitArc.zip`. The script archives with Xcode, signs each component from the inside out, submits the ZIP, staples Apple's ticket and checks Gatekeeper. The `--preview` option is a Bluetooth diagnostics build while waiting for the profiles. The preview disables driver activation.

## Tests

Run `scripts/test.sh` for the C++ decoder tests with AddressSanitizer and UndefinedBehaviorSanitizer and the Python motion tests. The [backend audit](docs/audit-0.3.0.md) records the verification scope and remaining hardware checks.

SplitArc is maintained by Alessio Cosi. It is an MIT-licensed fork of [JoyCon2Mac](https://github.com/OZORDI/JoyCon2Mac). See [LICENSE](LICENSE) for upstream copyright and credits.
