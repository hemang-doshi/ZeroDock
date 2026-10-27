#!/bin/bash
# Only a caller-specified, existing iPhone Simulator is accepted. Never a device.
set -euo pipefail
cd "$(dirname "$0")/.."
source Scripts/xcode-env.sh
if [[ $# -ne 1 ]]; then
    echo 'Usage: Scripts/verify-simulator.sh <iPhone-Simulator-UDID>' >&2
    echo 'Get simulator IDs with: xcrun simctl list devices available' >&2
    exit 2
fi
simulator_id="$1"
mkdir -p .build/verification docs/evidence
xcrun simctl list devices available --json > .build/verification/simulators.json
python3 - "$simulator_id" <<'PY'
import json, sys
with open('.build/verification/simulators.json') as stream:
    inventory = json.load(stream)
match = [(runtime, device) for runtime, devices in inventory['devices'].items() for device in devices
         if device['udid'] == sys.argv[1] and device.get('isAvailable')]
if len(match) != 1 or '.iOS-' not in match[0][0] or 'iPhone' not in match[0][1]['name']:
    sys.exit('Refusing: supply an available iPhone Simulator UUID from simctl. Physical-device identifiers are never accepted.')
print('Verifying simulator:', match[0][1]['name'])
PY
xcrun simctl bootstatus "$simulator_id" -b
result_path="$PWD/.build/verification/SimulatorTests-$(date +%Y%m%d-%H%M%S).xcresult"
xcodebuild -project ZeroDock.xcodeproj -scheme ZeroDock \
    -destination "platform=iOS Simulator,id=$simulator_id" \
    -derivedDataPath "$PWD/DerivedData" \
    -resultBundlePath "$result_path" \
    -parallel-testing-enabled NO ARCHS=arm64 ONLY_ACTIVE_ARCH=YES test CODE_SIGNING_ALLOWED=NO
xcrun simctl install "$simulator_id" "$PWD/DerivedData/Build/Products/Debug-iphonesimulator/ZeroDock.app"
xcrun simctl launch "$simulator_id" dev.zerodock.app
xcrun simctl io "$simulator_id" screenshot "$PWD/docs/evidence/simulator-launch.png"
echo "Results and landscape screenshot attachments: $result_path"
echo 'Check game selection, timer persistence, motion settings, inactive idle reset and call/banner behavior manually before physical acceptance. Mac telemetry is not connected in this build.'
