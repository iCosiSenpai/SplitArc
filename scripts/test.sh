#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p build/tests
xcrun clang++ -arch arm64 -mmacosx-version-min=26.0 -std=c++17 -Wall -Wextra -Werror \
    -g -fsanitize=address,undefined -I SplitArcAgent \
    tests/JoyConDecoderTests.cpp SplitArcAgent/JoyConDecoder.cpp -o build/tests/decoder
build/tests/decoder
python3 -m unittest discover -s tests
