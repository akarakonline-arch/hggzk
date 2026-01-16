#!/bin/bash

DEVICE_UDID="00008030-001A755C2ED2402E"

echo "=== Analyzing App Crash ==="
echo ""

# Check if idevicesyslog is available
if ! command -v idevicesyslog &> /dev/null; then
    echo "idevicesyslog not found, it should be in libimobiledevice-utils"
fi

echo "1. Getting system log (last 100 lines)..."
echo "   Open the app now, then press Ctrl+C after it crashes"
echo ""
sleep 2

# Capture live logs
idevicesyslog | grep -i -E "(error|crash|exception|assertion|com\.hggzk|Runner)" | tail -100

echo ""
echo "=== Done ==="
