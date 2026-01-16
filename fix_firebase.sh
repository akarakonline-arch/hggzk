#!/bin/bash

IPA_FILE="/home/ameen/Downloads/hggzk.ipa"
WORK_DIR="/tmp/ipa_fix"
FIREBASE_PLIST="$WORK_DIR/GoogleService-Info.plist"

echo "=== إصلاح Firebase في IPA ==="
echo ""

# Create Firebase plist template
cat > "$FIREBASE_PLIST" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>API_KEY</key>
    <string>PLACEHOLDER_API_KEY</string>
    <key>GCM_SENDER_ID</key>
    <string>000000000000</string>
    <key>PLIST_VERSION</key>
    <string>1</string>
    <key>BUNDLE_ID</key>
    <string>com.hggzk.app</string>
    <key>PROJECT_ID</key>
    <string>placeholder-project</string>
    <key>STORAGE_BUCKET</key>
    <string>placeholder-project.appspot.com</string>
    <key>IS_ADS_ENABLED</key>
    <false/>
    <key>IS_ANALYTICS_ENABLED</key>
    <false/>
    <key>IS_APPINVITE_ENABLED</key>
    <false/>
    <key>IS_GCM_ENABLED</key>
    <true/>
    <key>IS_SIGNIN_ENABLED</key>
    <true/>
    <key>GOOGLE_APP_ID</key>
    <string>1:000000000000:ios:0000000000000000</string>
    <key>DATABASE_URL</key>
    <string>https://placeholder-project.firebaseio.com</string>
</dict>
</plist>
EOF

echo "✅ تم إنشاء Firebase config template"
echo ""
echo "⚠️  ملاحظة:"
echo "هذا ملف مؤقت - التطبيق قد لا يعمل بشكل كامل"
echo "للحصول على ملف حقيقي:"
echo "  1. اذهب إلى https://console.firebase.google.com"
echo "  2. افتح مشروع hggzk أو أنشئ مشروع جديد"
echo "  3. iOS App → Download GoogleService-Info.plist"
echo "  4. ضع الملف في: $WORK_DIR/GoogleService-Info.plist"
echo ""
read -p "هل لديك ملف GoogleService-Info.plist الحقيقي؟ (y/n): " HAS_FILE

if [ "$HAS_FILE" = "y" ]; then
    read -p "أدخل مسار الملف: " REAL_PLIST
    if [ -f "$REAL_PLIST" ]; then
        cp "$REAL_PLIST" "$FIREBASE_PLIST"
        echo "✅ تم نسخ الملف الحقيقي"
    else
        echo "❌ الملف غير موجود - استخدام template"
    fi
fi

echo ""
echo "=== فك IPA ==="
rm -rf "$WORK_DIR"
mkdir -p "$WORK_DIR"
cd "$WORK_DIR"

unzip -q "$IPA_FILE"

# Find Runner.app
APP_DIR=$(find . -name "Runner.app" -type d | head -1)

if [ -z "$APP_DIR" ]; then
    echo "❌ لم يتم العثور على Runner.app"
    exit 1
fi

echo "✅ تم فك IPA"
echo ""

# Add Firebase plist
cp "$FIREBASE_PLIST" "$APP_DIR/"
echo "✅ تم إضافة GoogleService-Info.plist"
echo ""

# Re-zip
echo "=== إعادة تجميع IPA ==="
cd "$WORK_DIR"
zip -qr modified.ipa Payload/

MODIFIED_IPA="$WORK_DIR/modified.ipa"
echo "✅ تم إنشاء IPA جديدة: $MODIFIED_IPA"
echo ""

# Install
read -p "هل تريد تثبيت IPA المعدلة الآن؟ (y/n): " INSTALL_NOW

if [ "$INSTALL_NOW" = "y" ]; then
    cp "$MODIFIED_IPA" /tmp/altcon_final/app.ipa
    
    read -p "أدخل Apple ID password: " -s APPLE_PASS
    echo ""
    
    DEVICE_UDID="00008030-001A755C2ED2402E"
    APPLE_ID="ameenmamwn7@gmail.com"
    
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
            ./AltServer -u $DEVICE_UDID -a $APPLE_ID -p '$APPLE_PASS' /mnt/app.ipa
        "
fi

echo ""
echo "✅ انتهى"
