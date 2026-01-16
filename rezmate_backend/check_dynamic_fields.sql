-- التحقق من وجود UnitTypeFields (الحقول المُعرّفة)
SELECT 
    utf."FieldId",
    utf."FieldName",
    utf."DisplayName",
    utf."FieldTypeId",
    utf."IsPrimaryFilter",
    utf."IsRequired",
    ut."Name" as "UnitTypeName"
FROM "UnitTypeFields" utf
JOIN "UnitTypes" ut ON utf."UnitTypeId" = ut."UnitTypeId"
WHERE NOT utf."IsDeleted"
  AND utf."IsPrimaryFilter" = true
ORDER BY ut."Name", utf."DisplayName";

-- التحقق من وجود UnitFieldValues (القيم الفعلية للوحدات)
SELECT 
    ufv."Id",
    u."UnitId",
    u."Name" as "UnitName",
    utf."FieldName",
    ufv."FieldValue",
    ut."Name" as "UnitTypeName"
FROM "UnitFieldValues" ufv
JOIN "Units" u ON ufv."UnitId" = u."UnitId"
JOIN "UnitTypeFields" utf ON ufv."UnitTypeFieldId" = utf."FieldId"
JOIN "UnitTypes" ut ON u."UnitTypeId" = ut."UnitTypeId"
WHERE NOT ufv."IsDeleted"
  AND NOT u."IsDeleted"
  AND utf."FieldName" IN ('has_pool', 'chalet_size', 'has_garden')
LIMIT 20;
