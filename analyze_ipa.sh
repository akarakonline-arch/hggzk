#!/bin/bash

IPA_FILE="/home/ameen/Downloads/hggzk.ipa"

echo "=== Analyzing IPA File ==="
echo ""

# Create temp directory
TEMP_DIR=$(mktemp -d)
cd "$TEMP_DIR"

echo "1. Extracting IPA..."
unzip -q "$IPA_FILE"

echo ""
echo "2. App Bundle Info:"
APP_PATH=$(find Payload -name "*.app" -type d | head -1)
if [ -n "$APP_PATH" ]; then
    echo "   App: $APP_PATH"
    
    if [ -f "$APP_PATH/Info.plist" ]; then
        echo ""
        echo "3. Bundle Identifier:"
        plutil -p "$APP_PATH/Info.plist" 2>/dev/null | grep -i "bundleidentifier" || \
        grep -A 1 "CFBundleIdentifier" "$APP_PATH/Info.plist" | tail -1
        
        echo ""
        echo "4. App Version:"
        plutil -p "$APP_PATH/Info.plist" 2>/dev/null | grep -i "version" | head -3 || \
        grep -A 1 "CFBundleVersion" "$APP_PATH/Info.plist" | tail -1
        
        echo ""
        echo "5. Minimum iOS Version:"
        plutil -p "$APP_PATH/Info.plist" 2>/dev/null | grep -i "MinimumOS" || \
        grep -A 1 "MinimumOSVersion" "$APP_PATH/Info.plist" | tail -1
    fi
    
    echo ""
    echo "6. Frameworks/Libraries:"
    if [ -d "$APP_PATH/Frameworks" ]; then
        ls -1 "$APP_PATH/Frameworks" | head -10
    else
        echo "   No frameworks found"
    fi
    
    echo ""
    echo "7. Entitlements (if present):"
    if [ -f "$APP_PATH/archived-expanded-entitlements.xcent" ]; then
        cat "$APP_PATH/archived-expanded-entitlements.xcent"
    else
        echo "   No entitlements file found"
    fi
    
    echo ""
    echo "8. Code Signature Info:"
    if [ -f "$APP_PATH/_CodeSignature/CodeResources" ]; then
        echo "   ✅ Code signature present"
        head -20 "$APP_PATH/_CodeSignature/CodeResources"
    else
        echo "   ❌ No code signature found"
    fi
fi

# Cleanup
cd - > /dev/null
rm -rf "$TEMP_DIR"

echo ""
echo "=== Analysis Complete ==="
