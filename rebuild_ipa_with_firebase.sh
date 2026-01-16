#!/bin/bash

IPA_FILE="/home/ameen/Downloads/hggzk.ipa"
FIREBASE_SOURCE="/home/ameen/Desktop/BOOKIN/BOOKIN/hggzk_app/ios/Runner/GoogleService-Info.plist"
WORK_DIR="/tmp/ipa_rebuild"
DEVICE_UDID="00008030-001A755C2ED2402E"
APPLE_ID="ameenmamwn7@gmail.com"

echo "=== إصلاح IPA مع Firebase Config الصحيح ==="
echo ""

# Clean up
rm -rf "$WORK_DIR"
mkdir -p "$WORK_DIR"
cd "$WORK_DIR"

# Extract IPA
echo "📦 فك IPA..."
unzip -q "$IPA_FILE"

# Find Runner.app
APP_DIR=$(find . -name "Runner.app" -type d | head -1)

if [ -z "$APP_DIR" ]; then
    echo "❌ لم يتم العثور على Runner.app"
    exit 1
fi

echo "✅ تم فك IPA: $APP_DIR"
echo ""

# Fix Firebase plist - update bundle ID
echo "📝 تعديل GoogleService-Info.plist..."
cp "$FIREBASE_SOURCE" "$WORK_DIR/GoogleService-Info.plist"

# Update bundle ID to match the IPA
sed -i 's/com\.hggzkportal\.app/com.hggzk.app/g' "$WORK_DIR/GoogleService-Info.plist"

# Copy to app
cp "$WORK_DIR/GoogleService-Info.plist" "$APP_DIR/"

echo "✅ تم إضافة Firebase config مع Bundle ID الصحيح: com.hggzk.app"
echo ""

# Show Firebase config
echo "🔍 Firebase Project Info:"
grep -A1 "PROJECT_ID\|GOOGLE_APP_ID\|BUNDLE_ID" "$WORK_DIR/GoogleService-Info.plist" | grep "<string>" | sed 's/.*<string>\(.*\)<\/string>.*/  \1/'
echo ""

# Re-package IPA
echo "📦 إعادة تجميع IPA..."
zip -qr modified.ipa Payload/

MODIFIED_IPA="$WORK_DIR/modified.ipa"
echo "✅ تم إنشاء: $MODIFIED_IPA"
echo ""

# Prepare for installation
mkdir -p /tmp/altcon_final
cp "$MODIFIED_IPA" /tmp/altcon_final/app.ipa

echo "=== جاهز للتثبيت ==="
echo ""
read -p "أدخل Apple ID password (أو App-Specific Password): " -s APPLE_PASS
echo ""
echo ""

echo "⚠️  تأكد من:"
echo "  1. iPhone مفتوح وموصول"
echo "  2. إذا طُلب 2FA، افتح Settings > Apple ID > Password & Security > Get Verification Code"
echo ""
read -p "اضغط Enter للمتابعة..." 

echo ""
echo "🚀 بدء التثبيت..."
echo ""

docker run --rm -it \
    --privileged \
    --network host \
    -e ALTSERVER_ANISETTE_SERVER="https://ani.sidestore.io/" \
    -v /tmp/altcon_final:/mnt/ \
    -v /var/run/usbmuxd:/var/run/usbmuxd \
    -v /var/lib/lockdown:/tmp/lockdown \
    ghcr.io/sidestore/altcon \
    bash -c "
        echo 'nameserver 8.8.8.8' > /etc/resolv.conf && \
        echo 'nameserver 8.8.4.4' >> /etc/resolv.conf && \
        echo 'nameserver 1.1.1.1' >> /etc/resolv.conf && \
        echo '=== تثبيت IPA المعدلة ===' && \
        ./AltServer -u $DEVICE_UDID -a $APPLE_ID -p '$APPLE_PASS' /mnt/app.ipa
    "

EXIT_CODE=$?

echo ""
if [ $EXIT_CODE -eq 0 ]; then
    echo "✅ تم التثبيت بنجاح!"
    echo ""
    echo "الآن على iPhone:"
    echo "  1. Settings → General → VPN & Device Management"
    echo "  2. Trust \"$APPLE_ID\""
    echo "  3. افتح التطبيق"
    echo ""
    echo "⚠️  التطبيق الآن يحتوي على Firebase config صحيح"
else
    echo "❌ فشل التثبيت"
    echo ""
    echo "إذا طُلب 2FA:"
    echo "  Settings > اسمك > Password & Security > Get Verification Code"
fi

echo ""
echo "ملفات العمل في: $WORK_DIR"
