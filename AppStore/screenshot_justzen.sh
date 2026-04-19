#!/bin/bash
# ═══════════════════════════════════════════════════════
# JustZenGo App Store Screenshot Capture Script
# Targets:
#   iPhone 6.9"  → 1320×2868 (portrait) / 2868×1320 (landscape)
#   iPad 12.9"   → 2064×2752 (portrait) / 2752×2064 (landscape)
# ═══════════════════════════════════════════════════════

set -e

UDID_IPHONE="59030A31-1FAA-43F2-96AC-B36521085127"  # iPhone 16 Pro Max
UDID_IPAD="AF3BF078-6BDD-442C-B859-DB1986BF6D1A"     # iPad Pro 13-inch M5
SSDIR="/tmp/JustZenGoScreenshots"

echo "=============================================="
echo "JustZenGo App Store Screenshot Capture"
echo "=============================================="

# ── iPhone 6.9" portrait ──────────────────────────────
echo ""
echo ">>> [1/4] iPhone 6.9\" portrait (1320×2868)"
xcodebuild test \
  -project JustZenGo.xcodeproj \
  -scheme JustZenGo \
  -destination "platform=iOS Simulator,id=$UDID_IPHONE" \
  -only-testing:JustZenGoUITests/JustZenGoUITests/testScreenshot_iPhone_69_portrait \
  2>&1 | tail -8

# ── iPhone 6.9" landscape ─────────────────────────────
echo ""
echo ">>> [2/4] iPhone 6.9\" landscape (2868×1320)"
xcodebuild test \
  -project JustZenGo.xcodeproj \
  -scheme JustZenGo \
  -destination "platform=iOS Simulator,id=$UDID_IPHONE" \
  -only-testing:JustZenGoUITests/JustZenGoUITests/testScreenshot_iPhone_69_landscape \
  2>&1 | tail -8

# ── iPad 12.9" portrait ────────────────────────────────
echo ""
echo ">>> [3/4] iPad 12.9\" portrait (2064×2752)"
xcodebuild test \
  -project JustZenGo.xcodeproj \
  -scheme JustZenGo \
  -destination "platform=iOS Simulator,id=$UDID_IPAD" \
  -only-testing:JustZenGoUITests/JustZenGoUITests/testScreenshot_iPad_129_portrait \
  2>&1 | tail -8

# ── iPad 12.9" landscape ──────────────────────────────
echo ""
echo ">>> [4/4] iPad 12.9\" landscape (2752×2064)"
xcodebuild test \
  -project JustZenGo.xcodeproj \
  -scheme JustZenGo \
  -destination "platform=iOS Simulator,id=$UDID_IPAD" \
  -only-testing:JustZenGoUITests/JustZenGoUITests/testScreenshot_iPad_129_landscape \
  2>&1 | tail -8

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
with open('$f','rb') as fh:
    d=fh.read()
w=struct.unpack('>I',d[16:20])[0]; h=struct.unpack('>I',d[20:24])[0]
print(f'  {w}×{h}  $f')
" 2>/dev/null || echo "  (could not read $f)"
  fi
done
echo "=============================================="
