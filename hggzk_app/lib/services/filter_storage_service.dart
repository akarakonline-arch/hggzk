import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FilterStorageService {
  final SharedPreferences _prefs;
  FilterStorageService(this._prefs);

  static const String _kLastPropertyTypeId = 'filter_last_property_type_id';
  static const String _kLastUnitTypeId = 'filter_last_unit_type_id';
  static const String _kCheckIn = 'filter_check_in';
  static const String _kCheckOut = 'filter_check_out';
  static const String _kAdults = 'filter_adults';
  static const String _kChildren = 'filter_children';
  static const String _kCurrentFilters = 'filter_current_filters';
  static const String _kCity = 'filter_city';
  static const String _kSearchTerm = 'filter_search_term';

  Future<void> saveHomeSelections({
    String? propertyTypeId,
    String? unitTypeId,
    required Map<String, dynamic> dynamicFieldValues,
  }) async {
    if (propertyTypeId != null) {
      await _prefs.setString(_kLastPropertyTypeId, propertyTypeId);
    }
    if (unitTypeId != null) {
      await _prefs.setString(_kLastUnitTypeId, unitTypeId);
    }

    final DateTime? checkIn = dynamicFieldValues['checkIn'] is DateTime
        ? dynamicFieldValues['checkIn'] as DateTime
        : null;
    final DateTime? checkOut = dynamicFieldValues['checkOut'] is DateTime
        ? dynamicFieldValues['checkOut'] as DateTime
        : null;
    final int adults = (dynamicFieldValues['adults'] as int?) ?? 0;
    final int children = (dynamicFieldValues['children'] as int?) ?? 0;

    if (checkIn != null) {
      await _prefs.setString(_kCheckIn, checkIn.toIso8601String());
    } else {
      await _prefs.remove(_kCheckIn);
    }
    if (checkOut != null) {
      await _prefs.setString(_kCheckOut, checkOut.toIso8601String());
    } else {
      await _prefs.remove(_kCheckOut);
    }
    await _prefs.setInt(_kAdults, adults);
    await _prefs.setInt(_kChildren, children);

    // لم نعد نخزن فلاتر الحقول الديناميكية في التخزين المحلي
  }

  Map<String, dynamic> getHomeSelections() {
    final map = <String, dynamic>{};

    final pt = _prefs.getString(_kLastPropertyTypeId);
    final ut = _prefs.getString(_kLastUnitTypeId);
    if (pt != null) map['propertyTypeId'] = pt;
    if (ut != null) map['unitTypeId'] = ut;

    final checkInStr = _prefs.getString(_kCheckIn);
    final checkOutStr = _prefs.getString(_kCheckOut);
    bool hasExpiredSavedDates = false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    DateTime? checkIn;
    if (checkInStr != null) {
      final parsed = DateTime.tryParse(checkInStr);
      if (parsed != null) {
        if (parsed.isBefore(today)) {
          hasExpiredSavedDates = true;
        } else {
          checkIn = parsed;
        }
      }
    }

    DateTime? checkOut;
    if (checkOutStr != null) {
      final parsed = DateTime.tryParse(checkOutStr);
      if (parsed != null) {
        final minAllowed = checkIn ?? today;
        if (parsed.isBefore(minAllowed)) {
          hasExpiredSavedDates = true;
        } else {
          checkOut = parsed;
        }
      }
    }

    if (checkIn != null) map['checkIn'] = checkIn;
    if (checkOut != null) map['checkOut'] = checkOut;

    final adults = _prefs.getInt(_kAdults) ?? 0;
    final children = _prefs.getInt(_kChildren) ?? 0;
    map['adults'] = adults;
    map['children'] = children;

    // dynamicFieldValues تحتوي الآن فقط على التواريخ وعدد الضيوف
    final dynamicFieldValuesCombined = {
      if (map['checkIn'] != null) 'checkIn': map['checkIn'],
      if (map['checkOut'] != null) 'checkOut': map['checkOut'],
      'adults': adults,
      'children': children,
    };
    map['dynamicFieldValues'] = dynamicFieldValuesCombined;

    if (hasExpiredSavedDates) {
      map['hasExpiredSavedDates'] = true;
    }

    final city = _prefs.getString(_kCity);
    final searchTerm = _prefs.getString(_kSearchTerm);
    if (city != null) map['city'] = city;
    if (searchTerm != null) map['searchTerm'] = searchTerm;

    return map;
  }

  Future<void> saveCurrentFilters(Map<String, dynamic> filters) async {
    final f = Map<String, dynamic>.from(filters);
    if (f['checkIn'] is DateTime) {
      f['checkIn'] = (f['checkIn'] as DateTime).toIso8601String();
    }
    if (f['checkOut'] is DateTime) {
      f['checkOut'] = (f['checkOut'] as DateTime).toIso8601String();
    }
    final serializedMap = _serializeMap(f);
    await _prefs.setString(_kCurrentFilters, jsonEncode(serializedMap));

    if (f['propertyTypeId'] is String) {
      await _prefs.setString(_kLastPropertyTypeId, f['propertyTypeId']);
    }
    if (f['unitTypeId'] is String) {
      await _prefs.setString(_kLastUnitTypeId, f['unitTypeId']);
    }
    if (f['city'] is String) {
      await _prefs.setString(_kCity, f['city']);
    }
    if (f['searchTerm'] is String) {
      await _prefs.setString(_kSearchTerm, f['searchTerm']);
    }
  }

  Map<String, dynamic>? getCurrentFilters() {
    final jsonStr = _prefs.getString(_kCurrentFilters);
    if (jsonStr == null) return null;
    try {
      final decoded = Map<String, dynamic>.from(jsonDecode(jsonStr));
      final m = _deserializeMap(decoded);
      if (m['checkIn'] is String) {
        m['checkIn'] = DateTime.tryParse(m['checkIn']);
      }
      if (m['checkOut'] is String) {
        m['checkOut'] = DateTime.tryParse(m['checkOut']);
      }
      return m;
    } catch (_) {
      return null;
    }
  }

  Future<void> clearSelections() async {
    await _prefs.remove(_kLastPropertyTypeId);
    await _prefs.remove(_kLastUnitTypeId);
    await _prefs.remove(_kCheckIn);
    await _prefs.remove(_kCheckOut);
    await _prefs.remove(_kAdults);
    await _prefs.remove(_kChildren);
  }

  Future<void> clearCurrentFilters() async {
    await _prefs.remove(_kCurrentFilters);
  }

  dynamic _serializeValue(dynamic value) {
    if (value is RangeValues) {
      return {
        '_type': 'RangeValues',
        'start': value.start,
        'end': value.end,
      };
    }
    return value;
  }

  dynamic _deserializeValue(dynamic value) {
    if (value is Map && value['_type'] == 'RangeValues') {
      return RangeValues(
        (value['start'] as num).toDouble(),
        (value['end'] as num).toDouble(),
      );
    }
    return value;
  }

  Map<String, dynamic> _serializeMap(Map<String, dynamic> map) {
    final result = <String, dynamic>{};
    map.forEach((key, value) {
      if (value is Map<String, dynamic>) {
        result[key] = _serializeMap(value);
      } else {
        result[key] = _serializeValue(value);
      }
    });
    return result;
  }

  Map<String, dynamic> _deserializeMap(Map<String, dynamic> map) {
    final result = <String, dynamic>{};
    map.forEach((key, value) {
      if (value is Map && value['_type'] == null && value is Map<String, dynamic>) {
        result[key] = _deserializeMap(value);
      } else {
        result[key] = _deserializeValue(value);
      }
    });
    return result;
  }
}
