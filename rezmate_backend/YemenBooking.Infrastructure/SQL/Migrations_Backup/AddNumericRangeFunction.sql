-- Migration: إضافة دالة للتحقق من النطاق الرقمي في PostgreSQL
-- تُستخدم لفلترة الحقول الديناميكية التي تحتوي على أرقام

CREATE OR REPLACE FUNCTION is_numeric_in_range(
    value TEXT,
    min_value NUMERIC,
    max_value NUMERIC
) RETURNS BOOLEAN AS $$
BEGIN
    -- محاولة تحويل النص لرقم والتحقق من النطاق
    RETURN (value ~ '^[0-9]+(\.[0-9]+)?$') AND 
           (value::NUMERIC BETWEEN min_value AND max_value);
EXCEPTION
    WHEN OTHERS THEN
        RETURN FALSE;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- إنشاء index للحقول الرقمية (اختياري - لتحسين الأداء)
CREATE INDEX IF NOT EXISTS idx_unit_field_values_numeric 
ON "UnitFieldValues" ("UnitTypeFieldId", "FieldValue") 
WHERE "FieldValue" ~ '^[0-9]+(\.[0-9]+)?$';
