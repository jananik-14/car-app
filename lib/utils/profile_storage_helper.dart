import 'package:shared_preferences/shared_preferences.dart';

// TODO: TEMPORARY - This per-phone-number local storage approach is a frontend-only placeholder.
// Once backend is connected, profile data and completion status should come from the backend API 
// tied to the authenticated user's account (via JWT/session), and this entire shared_preferences 
// profile system should be removed.
class ProfileStorageHelper {
  static String normalizePhone(String phone) {
    final cleaned = phone.replaceAll(RegExp(r'[^0-9]'), '');
    return cleaned.length >= 10 ? cleaned.substring(cleaned.length - 10) : cleaned;
  }

  static Future<void> setCurrentLoggedInPhone(String phone) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('current_logged_in_phone', normalizePhone(phone));
  }

  static Future<String?> getCurrentLoggedInPhone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('current_logged_in_phone');
  }

  static Future<bool> isProfileComplete(String phone) async {
    final name = await getProfileField(phone, 'user_name');
    final email = await getProfileField(phone, 'user_email');
    final city = await getProfileField(phone, 'user_city');
    
    final prefs = await SharedPreferences.getInstance();
    final hasKyc = prefs.getBool('kyc_uploaded_$phone') ?? prefs.getBool('kyc_uploaded_${normalizePhone(phone)}') ?? false;
    
    return name != null && name.trim().isNotEmpty &&
           email != null && email.trim().isNotEmpty &&
           city != null && city.trim().isNotEmpty &&
           hasKyc;
  }

  static Future<void> saveProfileField(String phone, String fieldKey, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('${fieldKey}_${normalizePhone(phone)}', value);
  }

  static Future<String?> getProfileField(String phone, String fieldKey) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('${fieldKey}_${normalizePhone(phone)}');
  }
}
