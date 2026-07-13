import 'package:LawyerOnline/shared/api_provider.dart';

class LawyerDashboardStats {
  final int totalCases;
  final int activeCases;
  final int completedCases;
  final int cancelledCases;
  final int pendingCases;
  final double averageRating;
  final int reviewCount;
  final double estimatedEarnings;
  final int acceptedUrgentCases;
  final int acceptedBookingCases;

  const LawyerDashboardStats({
    this.totalCases = 0,
    this.activeCases = 0,
    this.completedCases = 0,
    this.cancelledCases = 0,
    this.pendingCases = 0,
    this.averageRating = 0,
    this.reviewCount = 0,
    this.estimatedEarnings = 0,
    this.acceptedUrgentCases = 0,
    this.acceptedBookingCases = 0,
  });
}

class LawyerDashboardService {
  LawyerDashboardService._();

  static Future<LawyerDashboardStats> loadForLawyer(String lawyerCode) async {
    if (lawyerCode.isEmpty) return const LawyerDashboardStats();

    final casesRes = await postDio('${server}/m/case/read', {
      'lawyer': lawyerCode,
    });
    final reviewsRes = await postDio('${server}/m/case/review/read', {
      'lawyerRef': lawyerCode,
    });

    final cases = (casesRes['objectData'] as List?) ?? [];
    int active = 0, done = 0, cancelled = 0, pending = 0;
    int urgent = 0, booking = 0;
    double earnings = 0;

    for (final raw in cases) {
      if (raw is! Map) continue;
      final m = Map<String, dynamic>.from(raw);
      final status = int.tryParse(m['caseStatus']?.toString() ?? '') ?? 0;
      final caseType = int.tryParse(m['caseType']?.toString() ?? '') ?? 1;
      final price = double.tryParse(m['price']?.toString() ?? '') ?? 0;

      if (caseType == 2) urgent++;
      if (caseType == 1) booking++;

      switch (status) {
        case 0:
          cancelled++;
          break;
        case 1:
          pending++;
          break;
        case 2:
        case 3:
          active++;
          break;
        case 4:
          done++;
          if (m['isPay'] == true || m['isPay'] == 1) earnings += price;
          break;
      }
    }

    final reviews = (reviewsRes['objectData'] as List?) ?? [];
    double ratingSum = 0;
    for (final raw in reviews) {
      if (raw is! Map) continue;
      ratingSum += (raw['rate'] as num?)?.toDouble() ?? 0;
    }
    final avg = reviews.isEmpty ? 0.0 : ratingSum / reviews.length;

    return LawyerDashboardStats(
      totalCases: cases.length,
      activeCases: active,
      completedCases: done,
      cancelledCases: cancelled,
      pendingCases: pending,
      averageRating: avg,
      reviewCount: reviews.length,
      estimatedEarnings: earnings,
      acceptedUrgentCases: urgent,
      acceptedBookingCases: booking,
    );
  }
}
