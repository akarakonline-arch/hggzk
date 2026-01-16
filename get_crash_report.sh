#!/bin/bash

echo "=== Fetching Crash Reports from iPhone ==="
echo ""

CRASH_DIR=~/iphone_crash_reports
mkdir -p "$CRASH_DIR"

echo "Downloading crash reports..."
idevicecrashreport -e "$CRASH_DIR"

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Crash reports downloaded to: $CRASH_DIR"
    echo ""
    echo "Latest Runner crashes:"
    ls -lt "$CRASH_DIR" | grep -i runner | head -5
    echo ""
    echo "Showing latest crash report:"
    LATEST_CRASH=$(ls -t "$CRASH_DIR" | grep -i runner | head -1)
    if [ -n "$LATEST_CRASH" ]; then
        echo "=== $LATEST_CRASH ==="
        cat "$CRASH_DIR/$LATEST_CRASH"
    fi
else
    echo "❌ Failed to download crash reports"
fi
