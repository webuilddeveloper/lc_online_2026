import 'package:LawyerOnline/models/user_profile_store.dart';
import 'package:LawyerOnline/shared/api_provider.dart';

/// โหลดรายการทนายที่ผู้ใช้กดถูกใจ
class FavoriteLawyerService {
  FavoriteLawyerService._();

  static Future<List<Map<String, dynamic>>> loadFavorites() async {
    final userId = UserProfileStore.instance.code;
    if (userId.isEmpty) return [];

    try {
      final result = await postDio('${server}/m/favoriteLawyer/read', {
        'reference': userId,
        'skip': 0,
        'limit': 100,
      });

      final raw = result['objectData'];
      if (raw is! List) return [];

      final favorites = <Map<String, dynamic>>[];
      for (final item in raw) {
        if (item is! Map) continue;
        final mapped = await _mapFavorite(Map<String, dynamic>.from(item));
        if (mapped != null) favorites.add(mapped);
      }
      return favorites;
    } catch (_) {
      return [];
    }
  }

  static Future<Map<String, dynamic>?> _mapFavorite(
    Map<String, dynamic> item,
  ) async {
    // กรณี API ส่งข้อมูลทนายมาครบ
    final embeddedCode = item['code']?.toString() ??
        item['lawyerCode']?.toString() ??
        item['referenceLawyer']?.toString() ??
        '';
    if (embeddedCode.isEmpty) return null;

    final hasProfile = (item['fullName'] ?? item['name']) != null;
    if (hasProfile) {
      return _normalizeLawyer(item, embeddedCode);
    }

    // ดึงโปรไฟล์ทนายเพิ่มเติม
    try {
      final result = await postDio('${server}/m/register/read', {
        'code': embeddedCode,
      });
      final data = result['objectData'];
      if (data is List && data.isNotEmpty && data.first is Map) {
        return _normalizeLawyer(
          Map<String, dynamic>.from(data.first as Map),
          embeddedCode,
        );
      }
    } catch (_) {}

    return null;
  }

  static Map<String, dynamic> _normalizeLawyer(
    Map<String, dynamic> raw,
    String code,
  ) {
    final name = raw['fullName']?.toString().trim().isNotEmpty == true
        ? raw['fullName'].toString()
        : '${raw['firstName'] ?? ''} ${raw['lastName'] ?? ''}'.trim();
    final rating = raw['rateAverage'] ?? raw['rating'] ?? 0;
    final reviews = raw['totalReview'] ?? raw['reviews'] ?? 0;
    final experience = raw['experience']?.toString() ?? '';
    final imageUrl = raw['imageUrl']?.toString() ?? '';
    final category = raw['category']?.toString() ?? '-';
    final isOnline = raw['isOnline'] == true || raw['status'] == 'online';

    return {
      'code': code,
      'name': name.isNotEmpty ? name : 'ทนายความ',
      'imageUrl': imageUrl,
      'category': category,
      'experience': experience.isNotEmpty ? '$experience ปี' : '-',
      'rating': rating is num
          ? rating.toStringAsFixed(1)
          : (rating?.toString() ?? '0'),
      'reviews': reviews.toString(),
      'status': isOnline ? 'online' : 'offline',
    };
  }
}
