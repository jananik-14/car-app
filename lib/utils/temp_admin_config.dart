// TODO: TEMPORARY - Remove this once backend sends real role-based login (isAdmin flag from API)
class TempAdminConfig {
  static const List<String> adminPhoneNumbers = [
    '+91 99999 99999', // Test admin number format used in app (e.g. +91 98765 43210)
    '+919999999999',
    '9999999999',
  ];
  
  static bool isAdminNumber(String phone) {
    final cleaned = phone.replaceAll(RegExp(r'[^0-9]'), '');
    final last10 = cleaned.length >= 10 ? cleaned.substring(cleaned.length - 10) : cleaned;
    
    for (var adminNum in adminPhoneNumbers) {
      final adminCleaned = adminNum.replaceAll(RegExp(r'[^0-9]'), '');
      final adminLast10 = adminCleaned.length >= 10 ? adminCleaned.substring(adminCleaned.length - 10) : adminCleaned;
      if (last10 == adminLast10) {
        return true;
      }
    }
    return false;
  }
}
