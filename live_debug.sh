#!/bin/bash

echo "=== Live Debug Session ==="
echo ""
echo "This will show real-time logs from your iPhone"
echo "After starting, open the app on your iPhone"
echo ""
echo "Press Ctrl+C to stop"
echo ""
sleep 3

echo "Starting log capture..."
echo ""

# Capture logs related to the app
idevicesyslog | grep -i --line-buffered -E "(com\.hggzk|Runner|assertion|crashed|terminated)"
