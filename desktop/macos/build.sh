#!/bin/bash
set -euo pipefail

TASK_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
TASK_OUTPUT="${DAYWEAVE_OUTPUT_DIR:-$TASK_ROOT/releases/macos}"
TASK_CACHE="${DAYWEAVE_MODULE_CACHE_DIR:-$TASK_OUTPUT/.build-cache}"
TASK_BUILD="$(mktemp -d "${TMPDIR:-/tmp}/dayweave-mac.XXXXXX")"
trap 'rm -rf "$TASK_BUILD"' EXIT
TASK_APP="$TASK_BUILD/日序.app"
TASK_SDK="$(xcrun --show-sdk-path)"
TASK_VERSION="$(/usr/libexec/PlistBuddy -c 'Print CFBundleShortVersionString' "$TASK_ROOT/desktop/macos/Info.plist")"
mkdir -p "$TASK_APP/Contents/MacOS" "$TASK_APP/Contents/Resources" "$TASK_OUTPUT"

# Some upgraded Command Line Tools installations retain both the old and new
# SwiftBridging module maps. Hide only the stale map through a compiler-local
# overlay, without changing any system files.
TASK_SWIFT_FLAGS=()
TASK_SWIFT_INCLUDE="$(dirname "$(dirname "$(xcrun --find swiftc)")")/include/swift"
if [[ -f "$TASK_SWIFT_INCLUDE/bridging.modulemap" && -f "$TASK_SWIFT_INCLUDE/module.modulemap" ]] &&
   grep -q 'module SwiftBridging' "$TASK_SWIFT_INCLUDE/module.modulemap" &&
   grep -q 'module SwiftBridging' "$TASK_SWIFT_INCLUDE/bridging.modulemap"; then
  touch "$TASK_BUILD/empty.modulemap"
  python3 - "$TASK_SWIFT_INCLUDE/module.modulemap" "$TASK_BUILD" <<'PY'
import json, pathlib, sys
build = pathlib.Path(sys.argv[2])
(build / 'overlay.json').write_text(json.dumps({'version': 0, 'roots': [
    {'type': 'file', 'name': sys.argv[1], 'external-contents': str(build / 'empty.modulemap')}
]}))
PY
  TASK_SWIFT_FLAGS=(-vfsoverlay "$TASK_BUILD/overlay.json")
fi

for TASK_ARCH in arm64 x86_64; do
  xcrun swiftc -O -whole-module-optimization -parse-as-library \
    "${TASK_SWIFT_FLAGS[@]}" \
    -target "$TASK_ARCH-apple-macos14.0" -sdk "$TASK_SDK" \
    -module-cache-path "$TASK_CACHE" \
    -framework AppKit -framework WebKit \
    "$TASK_ROOT/desktop/macos/Dayweave.swift" -o "$TASK_BUILD/Dayweave-$TASK_ARCH"
done
lipo -create "$TASK_BUILD/Dayweave-arm64" "$TASK_BUILD/Dayweave-x86_64" -output "$TASK_APP/Contents/MacOS/Dayweave"
cp "$TASK_ROOT/desktop/macos/Info.plist" "$TASK_APP/Contents/Info.plist"
cp "$TASK_ROOT/LICENSE" "$TASK_APP/Contents/Resources/LICENSE.txt"
xcrun swiftc -O "${TASK_SWIFT_FLAGS[@]}" -module-cache-path "$TASK_CACHE" -framework AppKit "$TASK_ROOT/desktop/macos/MakeIcon.swift" -o "$TASK_BUILD/make-icon"
"$TASK_BUILD/make-icon" "$TASK_BUILD/AppIcon.iconset"
iconutil -c icns "$TASK_BUILD/AppIcon.iconset" -o "$TASK_APP/Contents/Resources/AppIcon.icns"

if [[ -n "${DAYWEAVE_SIGNING_IDENTITY:-}" ]]; then
  codesign --force --options runtime --timestamp --sign "$DAYWEAVE_SIGNING_IDENTITY" "$TASK_APP"
else
  codesign --force --sign - "$TASK_APP"
fi
codesign --verify --deep --strict "$TASK_APP"
plutil -lint "$TASK_APP/Contents/Info.plist"

mkdir "$TASK_BUILD/dmg"
ditto "$TASK_APP" "$TASK_BUILD/dmg/日序.app"
ln -s /Applications "$TASK_BUILD/dmg/Applications"
cp "$TASK_ROOT/desktop/macos/安装说明.txt" "$TASK_BUILD/dmg/安装说明.txt"
hdiutil create -volname "日序 Dayweave" -srcfolder "$TASK_BUILD/dmg" -ov -format UDZO "$TASK_OUTPUT/Dayweave-$TASK_VERSION-universal.dmg"
ditto -c -k --sequesterRsrc --keepParent "$TASK_APP" "$TASK_OUTPUT/Dayweave-$TASK_VERSION-universal.zip"
ditto "$TASK_APP" "$TASK_OUTPUT/日序.app"
(cd "$TASK_OUTPUT" && LC_ALL=C shasum -a 256 "Dayweave-$TASK_VERSION-universal.dmg" "Dayweave-$TASK_VERSION-universal.zip" > SHA256SUMS.txt)
printf 'Built: %s\n' "$TASK_OUTPUT/Dayweave-$TASK_VERSION-universal.dmg"
