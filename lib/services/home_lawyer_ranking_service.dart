import 'package:LawyerOnline/shared/api_provider.dart';

/// จัดอันดับ/กรองทนายสำหรับหน้าแรก
/// - หมอความสำหรับคุณ: กรองจากคดี/นัดหมายที่ผู้ใช้เคยเปิด + หัวข้อที่โพสในชุมชน
/// - หมอความมาแรง: ทนายโปร (เรียงรีวิวดี) -> ทนายหน้าใหม่ (ยังไม่โปร)
class HomeLawyerRankingService {
  HomeLawyerRankingService._();

  static final HomeLawyerRankingService instance =
      HomeLawyerRankingService._();

  // ── helpers ─────────────────────────────────────────────────────────
  static bool _isPro(dynamic m) =>
      m is Map && (m['isPro'] == true || m['isPro']?.toString() == 'true');

  static double _rating(dynamic m) {
    if (m is! Map) return 0;
    final v = m['scroll'] ?? m['rating'] ?? m['reviewScore'];
    if (v is num) return v.toDouble();
    return double.tryParse(v?.toString() ?? '') ?? 0;
  }

  static DateTime _createdAt(dynamic m) {
    if (m is Map) {
      final raw = m['createDate'] ??
          m['createdDate'] ??
          m['createdAt'] ??
          m['registerDate'];
      final d = DateTime.tryParse(raw?.toString() ?? '');
      if (d != null) return d;
    }
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  static String _norm(String s) => s.trim().toLowerCase();

  // ── หมอความมาแรง ────────────────────────────────────────────────────
  /// เรียงลำดับ:
  /// 1) ทนายที่สมัครโปร (เรียงตามคะแนนรีวิวสูง -> ต่ำ)
  /// 2) ทนายหน้าใหม่ที่ยังไม่สมัครโปร (เรียงตามวันสมัครล่าสุด)
  List<dynamic> rankTrending(List<dynamic> lawyers, {int limit = 10}) {
    final pro = <dynamic>[];
    final free = <dynamic>[];
    for (final l in lawyers) {
      (_isPro(l) ? pro : free).add(l);
    }
    pro.sort((a, b) => _rating(b).compareTo(_rating(a)));
    free.sort((a, b) => _createdAt(b).compareTo(_createdAt(a)));
    return [...pro, ...free].take(limit).toList(growable: false);
  }

  // ── ความสนใจของผู้ใช้ ───────────────────────────────────────────────
  static void _collect(Set<String> out, dynamic v) {
    if (v == null) return;
    if (v is String) {
      final s = _norm(v);
      if (s.length >= 2) out.add(s);
    } else if (v is List) {
      for (final e in v) {
        _collect(out, e);
      }
    } else if (v is Map) {
      for (final key in const [
        'title',
        'name',
        'topicTitle',
        'subTopicTitle',
        'category',
        'topic',
      ]) {
        if (v[key] != null) _collect(out, v[key]);
      }
    }
  }

  /// รวบรวมหัวข้อที่ผู้ใช้สนใจจากเคส/นัดหมาย และโพสในชุมชน
  Future<Set<String>> deriveInterests({required String userCode}) async {
    final out = <String>{};
    if (userCode.isEmpty) return out;

    // 1) เคส/นัดหมายทั้งหมดที่ผู้ใช้เคยเปิด (รวมที่จบ/ยกเลิกด้วย เพราะเป็นความสนใจ)
    try {
      final res = await postDio('$server/m/case/read', {'userCode': userCode});
      final data = res['objectData'];
      if (data is List) {
        for (final item in data) {
          if (item is! Map) continue;
          _collect(out, item['topicTitle']);
          _collect(out, item['topic']);
          _collect(out, item['subTopicTitle']);
          _collect(out, item['subTopic']);
          _collect(out, item['category']);
          _collect(out, item['expertiseList']);
        }
      }
    } catch (_) {}

    // 2) โพสในชุมชนที่ผู้ใช้เป็นเจ้าของ
    try {
      final res = await postDio('$server/m/community/read', {
        'profileCode': userCode,
        'skip': 0,
        'limit': 50,
      });
      final data = res['objectData'];
      if (data is List) {
        for (final item in data) {
          if (item is! Map) continue;
          final author = (item['profileCode'] ??
                      item['createBy'] ??
                      item['userCode'] ??
                      (item['author'] is Map
                          ? (item['author']['code'] ?? item['author']['id'])
                          : null))
                  ?.toString() ??
              '';
          if (author.isEmpty || author != userCode) continue;
          _collect(out, item['subTopicTitle']);
          _collect(out, item['topicTitle']);
          _collect(out, item['category']);
        }
      }
    } catch (_) {}

    return out;
  }

  static String _lawyerBlob(dynamic m) {
    if (m is! Map) return '';
    final parts = <String>[];
    void add(dynamic v) {
      if (v == null) return;
      if (v is String) {
        parts.add(v);
      } else if (v is List) {
        for (final e in v) {
          add(e);
        }
      } else if (v is Map) {
        for (final e in v.values) {
          add(e);
        }
      }
    }

    add(m['category']);
    add(m['specialty']);
    add(m['expertiseList']);
    add(m['expertiseData']);
    add(m['skills']);
    add(m['title']);
    add(m['lv0']);
    add(m['lv1']);
    add(m['lv2']);
    add(m['lv3']);
    return _norm(parts.join(' '));
  }

  bool _matches(dynamic lawyer, Set<String> interests) {
    final blob = _lawyerBlob(lawyer);
    if (blob.isEmpty) return false;
    for (final kw in interests) {
      if (kw.length < 2) continue;
      if (blob.contains(kw)) return true;
    }
    return false;
  }

  // ── หมอความสำหรับคุณ ────────────────────────────────────────────────
  /// กรองทนายให้ตรงกับความสนใจของผู้ใช้ (เคส/นัดหมาย/โพสชุมชน)
  /// ถ้าไม่มีข้อมูลความสนใจ หรือไม่มีทนายที่ตรง -> คืนรายการเริ่มต้น
  List<dynamic> rankForYou(
    List<dynamic> lawyers,
    Set<String> interests, {
    int limit = 10,
  }) {
    if (interests.isEmpty) {
      return lawyers.take(limit).toList(growable: false);
    }
    final matched =
        lawyers.where((l) => _matches(l, interests)).toList(growable: true);
    if (matched.isEmpty) {
      return lawyers.take(limit).toList(growable: false);
    }
    // ที่ตรงความสนใจ: ให้ทนายโปร + รีวิวดีขึ้นก่อน
    matched.sort((a, b) {
      final pa = _isPro(a);
      final pb = _isPro(b);
      if (pa != pb) return pb ? 1 : -1;
      return _rating(b).compareTo(_rating(a));
    });
    return matched.take(limit).toList(growable: false);
  }
}
