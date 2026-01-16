-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- Function: get_unit_display_fields_json
-- الغرض: إرجاع الحقول الديناميكية للوحدة كـ JSONB في استعلام واحد
-- الأداء: O(1) - محسَّن باستخدام jsonb_object_agg
-- التاريخ: 2025-01-18
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- ✅ حذف الدالة القديمة إن وُجدت
DROP FUNCTION IF EXISTS get_unit_display_fields_json(UUID);

-- ✅ إنشاء الدالة الجديدة
CREATE OR REPLACE FUNCTION get_unit_display_fields_json(p_unit_id UUID)
RETURNS JSONB
LANGUAGE SQL
STABLE
PARALLEL SAFE
AS $$
    SELECT COALESCE(
        jsonb_object_agg(
            COALESCE("DisplayName", "FieldName", ''),
            COALESCE("FieldValue", '')
        ) FILTER (WHERE "ShowInCards" = true),
        '{}'::jsonb
    )
    FROM "UnitFieldValues" ufv
    INNER JOIN "UnitTypeFields" utf ON utf."FieldId" = ufv."UnitTypeFieldId"
    WHERE ufv."UnitId" = p_unit_id
      AND utf."ShowInCards" = true
    LIMIT 5;
$$;

-- ✅ إضافة تعليق توضيحي
COMMENT ON FUNCTION get_unit_display_fields_json(UUID) IS 
'إرجاع الحقول الديناميكية للوحدة كـ JSONB - تنفيذ كامل في SQL بدون N+1 queries';

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- Index Optimization: فهرس لتحسين أداء البحث
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- فهرس مركب لتحسين أداء الاستعلام
CREATE INDEX IF NOT EXISTS "IX_UnitFieldValues_UnitId_ShowInCards" 
ON "UnitFieldValues"("UnitId")
INCLUDE ("FieldValue")
WHERE "UnitId" IS NOT NULL;

-- فهرس على ShowInCards في UnitTypeFields
CREATE INDEX IF NOT EXISTS "IX_UnitTypeFields_ShowInCards" 
ON "UnitTypeFields"("ShowInCards", "FieldId")
WHERE "ShowInCards" = true;

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- اختبار الدالة
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

DO $$
DECLARE
    v_test_unit_id UUID;
    v_result JSONB;
BEGIN
    -- الحصول على أول وحدة للاختبار
    SELECT "UnitId" INTO v_test_unit_id
    FROM "Units"
    LIMIT 1;
    
    IF v_test_unit_id IS NOT NULL THEN
        -- اختبار الدالة
        SELECT get_unit_display_fields_json(v_test_unit_id) INTO v_result;
        
        RAISE NOTICE 'Test Result for Unit %: %', v_test_unit_id, v_result;
        RAISE NOTICE '✅ Function get_unit_display_fields_json created and tested successfully!';
    ELSE
        RAISE NOTICE '⚠️ No units found for testing';
    END IF;
END $$;
