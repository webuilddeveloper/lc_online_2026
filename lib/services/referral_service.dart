import 'package:LawyerOnline/shared/api_provider.dart';

class ReferralStats {
  const ReferralStats({
    required this.referralCode,
    required this.totalInvites,
    required this.totalRewards,
  });

  final String referralCode;
  final int totalInvites;
  final int totalRewards;

  factory ReferralStats.fromJson(Map<String, dynamic> json) => ReferralStats(
        referralCode: json['referralCode']?.toString() ?? '',
        totalInvites: int.tryParse(json['totalInvites']?.toString() ?? '') ?? 0,
        totalRewards: int.tryParse(json['totalRewards']?.toString() ?? '') ?? 0,
      );
}

class ReferralService {
  ReferralService._();

  static Future<ReferralStats?> loadStats(String userCode) async {
    final result = await postDio('${server}/m/referral/stats/read', {
      'userCode': userCode,
    });
    if (result['status'] != 'S') return null;
    final raw = result['objectData'];
    if (raw is! Map) return null;
    return ReferralStats.fromJson(Map<String, dynamic>.from(raw));
  }

  static Future<bool> applyCode({
    required String referralCode,
    required String newUserCode,
  }) async {
    final result = await postDio('${server}/m/referral/apply', {
      'referralCode': referralCode,
      'newUserCode': newUserCode,
    });
    return result['status'] == 'S';
  }
}
