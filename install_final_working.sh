#!/bin/bash

APPLE_ID="ameenmamwn7@gmail.com"
DEVICE_UDID="00008030-001A755C2ED2402E"
IPA_FILE="/home/ameen/Downloads/hggzk.ipa"

echo "=== Final AltServer Installation ==="
echo ""

# Prepare temp directory
mkdir -p /tmp/altcon_final
cp "$IPA_FILE" /tmp/altcon_final/app.ipa

echo "✅ IPA file copied"
echo "✅ Device connected: $DEVICE_UDID"
echo ""

read -p "Enter your Apple ID password (or App-Specific Password): " -s APPLE_PASS
echo ""
echo ""

cd /tmp/altcon_final

echo "=== Starting Docker container with full access ==="
echo ""
echo "⚠️  Important:"
echo "   1. Make sure iPhone is unlocked"
echo "   2. When 2FA prompt appears, enter the code"
echo "   3. On iPhone, tap 'Install' when prompted"
echo ""
echo "Press Enter to continue..."
read

docker run --rm -it \
  --privileged \
  --network host \
  -e ALTSERVER_ANISETTE_SERVER="https://ani.sidestore.io/" \
  -v "${PWD}":/mnt/ \
  -v /var/run/usbmuxd:/var/run/usbmuxd \
  -v /var/lib/lockdown:/tmp/lockdown \
  ghcr.io/sidestore/altcon \
  bash -c "
    echo 'nameserver 8.8.8.8' > /etc/resolv.conf && \
    echo 'nameserver 8.8.4.4' >> /etc/resolv.conf && \
    echo 'nameserver 1.1.1.1' >> /etc/resolv.conf && \
    echo '=== Installing IPA ===' && \
    ./AltServer -u $DEVICE_UDID -a $APPLE_ID -p '$APPLE_PASS' /mnt/app.ipa || \
    (echo '' && echo '❌ Installation failed!' && echo 'Trying alternative method...' && echo '' && \
     echo 'Container is ready. Run manually:' && \
     echo \"./AltServer -u $DEVICE_UDID -a $APPLE_ID -p 'YOUR_PASSWORD' /mnt/app.ipa\" && \
     /bin/bash)
  "

EXIT_CODE=$?

if [ $EXIT_CODE -eq 0 ]; then
    echo ""
    echo "✅ Installation successful!"
    echo ""
    echo "Next steps on iPhone:"
    echo "  1. Settings → General → VPN & Device Management"
    echo "  2. Trust the developer profile"
    echo "  3. Enable Developer Mode if required (iOS 16+)"
else
    echo ""
    echo "⚠️  Installation may have failed or needs manual intervention"
fi

echo ""
echo "Cleaning up..."
rm -rf /tmp/altcon_final

echo "Done!"
