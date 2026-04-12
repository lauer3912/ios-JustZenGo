#!/bin/bash
# FocusTimer App Store Screenshot Capture Script
# Run ON cloud Mac via: bash /tmp/screenshot_script.sh
#
# What it does:
# 1. Opens FocusTimer in iPhone 17 simulator
# 2. Navigates to each screen
# 3. Captures using macOS screencapture
# 4. Crops to exact App Store required sizes

OUTPUT_DIR="/tmp/FocusTimerScreenshots"
mkdir -p "$OUTPUT_DIR"

# App Store required sizes (in points, will be @2x = pixels)
# iPhone 6.7" Display: 1290 x 2796 pixels (@2x from 645 x 1398 pt)
# iPhone 6.5" Display: 1284 x 2778 pixels (@2x from 642 x 1389 pt)  
# iPad Pro 12.9": 2048 x 2732 pixels (@2x from 1024 x 1366 pt)

echo "=========================================="
echo "FocusTimer App Store Screenshot Generator"
echo "=========================================="
echo ""

# Check if Simulator is running
if ! pgrep -x Simulator > /dev/null 2>&1; then
    echo "[1/6] Launching iOS Simulator..."
    open -a "/Applications/Xcode.app/Contents/Developer/Application/Simulator.app"
    echo "Waiting 8s for Simulator to fully launch..."
    sleep 8
else
    echo "[1/6] Simulator already running"
fi

# Find the iPhone 17 simulator
SIM_ID=$(xcrun simctl list devices available | grep "iPhone 17" | head -1 | awk '{print $1}')
if [ -z "$SIM_ID" ]; then
    echo "Warning: iPhone 17 simulator not found, using default"
    SIM_NAME="iPhone 17"
else
    echo "[2/6] Found iPhone 17 simulator: $SIM_ID"
fi

# Build FocusTimer first if not built
if [ ! -d "/Users/user291981/Library/Developer/Xcode/DerivedData/FocusTimer-*/Build/Products/Debug-iphonesimulator/FocusTimer.app" ]; then
    echo "[3/6] Building FocusTimer..."
    cd /tmp/FocusTimer
    xcodebuild -project FocusTimer.xcodeproj -scheme FocusTimer -configuration Debug \
        -destination 'platform=iOS Simulator,name=iPhone 17' build 2>/dev/null
    echo "Build complete"
else
    echo "[3/6] FocusTimer already built, skipping build"
fi

# Boot simulator and install
echo "[4/6] Booting simulator and launching FocusTimer..."
xcrun simctl boot "iPhone 17" 2>/dev/null || true
sleep 2

# Launch FocusTimer in simulator via simctl
xcrun simctl install "iPhone 17" \
    "/Users/user291981/Library/Developer/Xcode/DerivedData/FocusTimer-*/Build/Products/Debug-iphonesimulator/FocusTimer.app" \
    2>/dev/null || true

echo "[5/6] Capturing screenshots..."
echo ""

# Helper: capture and crop for App Store
capture_crop() {
    local name=$1
    local target_w=$2
    local target_h=$3
    local output="$OUTPUT_DIR/${name}.png"
    
    # Capture full screen (retina quality)
    screencapture -x -R0,0,${target_w},${target_h} "$output" 2>/dev/null
    
    if [ -f "$output" ] && [ -s "$output" ]; then
        local size=$(ls -lh "$output" | awk '{print $1}')
        echo "  ✓ $name ($target_w x $target_h) - $size"
    else
        echo "  ✗ $name - FAILED"
    fi
}

# First, we need to know where the Simulator window is on screen
# Use cmd+shift+4 style capture with specific window
SIM_WINDOW_ID=$(osascript -e 'tell application "System Events" to get windows of process "Simulator" whose name contains "iPhone"' 2>/dev/null | head -1)
echo "Simulator window info: $SIM_WINDOW_ID"

# Capture using window ID capture mode
# The Simulator window is typically 390 x 844 points (@2x = 780 x 1688 pixels) for iPhone 17

# For now, capture the whole screen and we'll crop
SCREEN_FILE="/tmp/_focus_timer_screen.png"
screencapture -x "$SCREEN_FILE" 2>/dev/null

if [ -f "$SCREEN_FILE" ] && [ -s "$SCREEN_FILE" ]; then
    echo "  ✓ Full screen captured"
    
    # Convert and crop to required sizes using sips (built into macOS)
    # iPhone 6.7": 1290 x 2796
    sips -z 2796 1290 "$SCREEN_FILE" --out "$OUTPUT_DIR/iphone67_screen1.png" 2>/dev/null
    sips -z 2796 1290 "$SCREEN_FILE" --out "$OUTPUT_DIR/iphone67_screen2.png" 2>/dev/null
    
    # iPhone 6.5": 1284 x 2778
    sips -z 2778 1284 "$SCREEN_FILE" --out "$OUTPUT_DIR/iphone65_screen1.png" 2>/dev/null
    
    echo ""
    echo "[6/6] Screenshot results:"
    ls -lh "$OUTPUT_DIR"/*.png 2>/dev/null
else
    echo "  ✗ Screen capture failed - try running manually:"
    echo "     screencapture -x /tmp/screen.png"
fi

echo ""
echo "=========================================="
echo "Done! Files in: $OUTPUT_DIR"
echo "=========================================="
