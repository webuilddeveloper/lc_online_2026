import 'package:LawyerOnline/shared/api_provider.dart';

/// โหลดแบนเนอร์หน้าแรกจาก API
class BannerService {
  BannerService._();

  static const _fallbackBanners = [
    {'code': '0', 'imageUrl': 'assets/images/banner1.png', 'action': ''},
    {'code': '1', 'imageUrl': 'assets/images/banner2.png', 'action': ''},
  ];

  static Future<List<Map<String, dynamic>>> loadMainBanners() async {
    try {
      final result = await post(mainBannerApi, {'skip': 0, 'limit': 10});
      if (result is! List || result.isEmpty) {
        return List<Map<String, dynamic>>.from(_fallbackBanners);
      }

      final banners = <Map<String, dynamic>>[];
      for (final item in result) {
        if (item is! Map) continue;
        final map = Map<String, dynamic>.from(item);
        final imageUrl = map['imageUrl']?.toString() ?? '';
        if (imageUrl.isEmpty) continue;
        banners.add({
          'code': map['code']?.toString() ?? '',
          'imageUrl': imageUrl,
          'title': map['title']?.toString() ?? '',
          'action': map['action']?.toString() ?? '',
          'path': map['path']?.toString() ?? '',
        });
      }

      return banners.isNotEmpty
          ? banners
          : List<Map<String, dynamic>>.from(_fallbackBanners);
    } catch (_) {
      return List<Map<String, dynamic>>.from(_fallbackBanners);
    }
  }
}
