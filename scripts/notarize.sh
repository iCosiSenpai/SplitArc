#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."

preview=false
if [[ ${1:-} == --preview ]]; then
    preview=true
    shift
fi
if [[ $# != 1 ]]; then
    echo "Usage: CODE_SIGN_IDENTITY='Developer ID Application: …' NOTARY_PROFILE=… $0 [--preview] OUTPUT.zip" >&2
    exit 2
fi
output="$1"
: "${CODE_SIGN_IDENTITY:?Set the Developer ID Application signing identity}"
: "${NOTARY_PROFILE:?Set the notarytool Keychain profile name}"
if [[ -e "$output" ]]; then
    echo "Output already exists: $output" >&2
    exit 1
fi

if ! $preview; then
    : "${APP_PROVISIONING_PROFILE:?Set the Developer ID system-extension host profile path}"
    : "${DEXT_PROVISIONING_PROFILE:?Set the Developer ID DriverKit profile path}"
    : "${AGENT_PROVISIONING_PROFILE:?Set the Developer ID driver user-client profile path}"
fi

mkdir -p build
staging="$(mktemp -d "$PWD/build/notary.XXXXXX")"
trap 'rm -rf "$staging"' EXIT
xcodebuild -project SplitArc.xcodeproj -scheme SplitArc -configuration Release \
    -destination 'generic/platform=macOS' -derivedDataPath build/xcode \
    -archivePath "$staging/SplitArc.xcarchive" CODE_SIGNING_ALLOWED=NO archive

app="$staging/SplitArc.xcarchive/Products/Applications/SplitArc.app"
agent="$app/Contents/Helpers/SplitArcAgent.app"
driver="$app/Contents/Library/SystemExtensions/dev.icosisenpai.splitarc.driver.dext"
test -d "$agent" && test -d "$driver"
for binary in "$app/Contents/MacOS/SplitArc" "$agent/Contents/MacOS/SplitArcAgent" \
              "$driver/Contents/MacOS/dev.icosisenpai.splitarc.driver"; do
    [[ "$(xcrun lipo -archs "$binary")" == arm64 ]]
done

sign() {
    local bundle="$1"
    shift
    codesign --force --sign "$CODE_SIGN_IDENTITY" --options runtime --timestamp "$@" "$bundle"
}

if $preview; then
    # The preview has no managed host/agent entitlements. macOS refuses to
    # launch binaries that claim them without a matching provisioning profile.
    sign "$driver" --generate-entitlement-der --entitlements VirtualJoyConDriver/VirtualJoyConDriver.entitlements
    sign "$agent"
    sign "$app"
else
    cp "$DEXT_PROVISIONING_PROFILE" "$driver/Contents/embedded.provisionprofile"
    cp "$AGENT_PROVISIONING_PROFILE" "$agent/Contents/embedded.provisionprofile"
    cp "$APP_PROVISIONING_PROFILE" "$app/Contents/embedded.provisionprofile"
    sign "$driver" --generate-entitlement-der --entitlements VirtualJoyConDriver/VirtualJoyConDriver.entitlements
    sign "$agent" --generate-entitlement-der --entitlements SplitArcAgent/SplitArcAgent.entitlements
    sign "$app" --generate-entitlement-der --entitlements SplitArcApp/SplitArc.entitlements
fi
codesign --verify --strict "$driver"
codesign --verify --deep --strict --verbose=2 "$app"
ditto -c -k --keepParent "$app" "$staging/submit.zip"
receipt="$staging/receipt.json"
xcrun notarytool submit "$staging/submit.zip" --keychain-profile "$NOTARY_PROFILE" \
    --wait --timeout 10m --output-format json | tee "$receipt"
submission="$(plutil -extract id raw "$receipt")"
if [[ "$(plutil -extract status raw "$receipt")" != Accepted ]]; then
    xcrun notarytool log "$submission" --keychain-profile "$NOTARY_PROFILE"
    exit 1
fi
xcrun stapler staple "$app"
xcrun stapler validate "$app"
spctl --assess --type execute --verbose=2 "$app"
ditto -c -k --keepParent "$app" "$output"
printf 'Notarized archive: %s\n' "$output"
if ! xcrun notarytool log "$submission" --keychain-profile "$NOTARY_PROFILE" "build/notary-$submission.json"; then
    printf 'The notarization log could not be downloaded for submission %s.\n' "$submission" >&2
fi
