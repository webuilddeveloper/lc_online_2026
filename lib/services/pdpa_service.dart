import 'package:shared_preferences/shared_preferences.dart';

/// จัดการ consent PDPA / disclaimer
class PdpaService {
  PdpaService._();

  static const _consentKey = 'pdpa_consent_accepted_v1';
  static const _videoConsentKey = 'video_consent_accepted_v1';
  static const _disclaimerKey = 'legal_disclaimer_accepted_v1';

  static Future<bool> hasAcceptedPdpa() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_consentKey) ?? false;
  }

  static Future<void> acceptPdpa() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_consentKey, true);
  }

  static Future<bool> hasAcceptedVideoConsent() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_videoConsentKey) ?? false;
  }

  static Future<void> acceptVideoConsent() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_videoConsentKey, true);
  }

  static Future<bool> hasAcceptedDisclaimer() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_disclaimerKey) ?? false;
  }

  static Future<void> acceptDisclaimer() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_disclaimerKey, true);
  }
}
