#!/bin/bash
# ═══════════════════════════════════════════════════════
# JustZenGo App Store Screenshot Capture Script
# Targets:
#   iPhone 6.9"  → 1320×2868 (portrait) / 2868×1320 (landscape)
#   iPad 12.9"   → 2064×2752 (portrait) / 2752×2064 (landscape)
#
# Usage:
#   ./screenshot_justzen.sh          # all 4 sets
#   ./screenshot_justzen.sh phone    # iPhone only
#   ./screenshot_justzen.sh ipad    # iPad only
# ═══════════════════════════════════════════════════════

set -e

UDID_IPHONE="59030A31-1FAA-43F2-96AC-B36521085127"  # iPhone 16 Pro Max
UDID_IPAD="AF3BF078-6BDD-442C-B859-DB1986BF6D1A"     # iPad Pro 13-inch M5
SSDIR="/tmp/JustZenGoScreenshots"

SIGN_OPTS="CODE_SIGN_IDENTITY='-' CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO"

# Helper: rotate simulator via xcrun simctl
rotate_sim() {
    local udid="$1"
    local angle="$2"  # 0=portrait, 90=landscape-right
    echo "  Rotating device $udid to angle $angle..."
    xcrun simctl ui "$udid" rotate --angle "$angle" 2>/dev/null || \
    xcrun simctl rotateui "$udid" --angle "$angle" 2>/dev/null || \
    echo "  (rotation not available, continuing anyway)"
    sleep 2
}

# Helper: run a specific screenshot test
run_test() {
    local name="$1"
    local udid="$2"
    echo ">>> $name"
    xcodebuild test \
        -project JustZenGo.xcodeproj \
        -scheme JustZenGo \
        -destination "platform=iOS Simulator,id=$udid" \
        -only-testing:"JustZenGoUITests/JustZenGoUITests/$name" \
        $SIGN_OPTS \
        2>&1 | tail -5
}

echo "=============================================="
echo "JustZenGo App Store Screenshot Capture"
echo "=============================================="
mkdir -p "$SSDIR"

MODE="${1:-all}"   # all | phone | ipad

# ── iPhone 6.9" portrait ──────────────────────────────
if [[ "$MODE" == "all" || "$MODE" == "phone" ]]; then
    echo ""
    echo ">>> [1/4] iPhone 6.9\" portrait (1320×2868)"
    run_test "testScreenshot_iPhone_69_portrait" "$UDID_IPHONE"
fi

# ── iPhone 6.9" landscape ─────────────────────────────
if [[ "$MODE" == "all" || "$MODE" == "phone" ]]; then
    echo ""
    echo ">>> [2/4] iPhone 6.9\" landscape (2868×1320)"
    # Rotate simulator to landscape BEFORE test
    rotate_sim "$UDID_IPHONE" 90
    run_test "testScreenshot_iPhone_69_landscape" "$UDID_IPHONE"
    # Rotate back to portrait
    rotate_sim "$UDID_IPHONE" 0
fi

# ── iPad 12.9" portrait ────────────────────────────────
if [[ "$MODE" == "all" || "$MODE" == "ipad" ]]; then
    echo ""
    echo ">>> [3/4] iPad 12.9\" portrait (2064×2752)"
    run_test "testScreenshot_iPad_129_portrait" "$UDID_IPAD"
fi

# ── iPad 12.9" landscape ──────────────────────────────
if [[ "$MODE" == "all" || "$MODE" == "ipad" ]]; then
    echo ""
    echo ">>> [4/4] iPad 12.9\" landscape (2752×2064)"
    rotate_sim "$UDID_IPAD" 90
    run_test "testScreenshot_iPad_129_landscape" "$UDID_IPAD"
    rotate_sim "$UDID_IPAD" 0
fi

# ── Report ─────────────────────────────────────────────
echo ""
echo "=============================================="
echo "Screenshot capture complete!"
echo "Output directory: $SSDIR"
echo ""
echo "Files captured:"
ls -la "$SSDIR"/*.png 2>/dev/null || echo "(no files found)"
echo ""
echo "Dimensions check:"
for f in "$SSDIR"/*.png; do
    if [ -f "$f" ]; then
        python3 -c "
import struct, sys
with open('$f','rb') as fh: d=fh.read()
w=struct.unpack('>I',d[16:20])[0]; h=struct.unpack('>I',d[20:24])[0]
print(f'  {w}x{h}  ' + '$f'.split('/')[-1])
" 2>/dev/null || echo "  (could not read $f)"
    fi
done
echo "=============================================="
