#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"
xcodebuild -project SplitArc.xcodeproj -scheme SplitArc -configuration Release \
    -destination 'generic/platform=macOS' -derivedDataPath build/xcode \
    CODE_SIGNING_ALLOWED=NO build
