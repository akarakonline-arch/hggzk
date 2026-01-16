#!/bin/bash

# 🔧 Quick Update Team ID Script
# هذا السكريبت يساعدك في تحديث Team ID في جميع ملفات ExportOptions.plist

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔧 Update Team ID in ExportOptions.plist"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

# Get Team ID
echo "كيفية الحصول على Team ID:"
echo "1. من Apple Developer Portal → Membership"
echo "2. أو من Xcode → Signing & Capabilities"
echo ""
read -p "Enter your Team ID: " TEAM_ID

if [ -z "$TEAM_ID" ]; then
    echo "❌ Team ID is required!"
    exit 1
fi

echo ""
echo "Updating ExportOptions.plist files..."
echo ""

# Update all ExportOptions.plist files
for app in hggzk_app hggzkportal_app rezmate_app rezmateportal_app; do
    FILE="$app/ios/ExportOptions.plist"
    if [ -f "$FILE" ]; then
        sed -i '' "s/YOUR_TEAM_ID/$TEAM_ID/g" "$FILE"
        echo -e "${GREEN}✅ Updated: $FILE${NC}"
    else
        echo "⚠️  File not found: $FILE"
    fi
done

echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}✅ All files updated successfully!${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "Next steps:"
echo "1. Verify the changes:"
echo "   git diff"
echo ""
echo "2. Commit and push:"
echo "   git add */ios/ExportOptions.plist"
echo "   git commit -m 'Update Team ID in ExportOptions.plist'"
echo "   git push"
echo ""
echo "3. Run the workflow:"
echo "   gh workflow run build-ios-apps.yml -f app_to_build=all"
echo ""
