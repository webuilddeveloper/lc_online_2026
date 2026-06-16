import 'package:LawyerOnline/component/appbar.dart';
import 'package:LawyerOnline/shared/api_provider.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LawyerReviewPage extends StatefulWidget {
  final dynamic lawyer;

  const LawyerReviewPage({Key? key, required this.lawyer}) : super(key: key);

  @override
  State<LawyerReviewPage> createState() => _LawyerReviewPageState();
}

class _LawyerReviewPageState extends State<LawyerReviewPage> {
  static const _kPrimary = Color(0xFF0262EC);
  static const _kBg      = Color(0xFFF5F7FA);

  List<dynamic> _reviews   = [];
  bool          _isLoading = true;
  String?       _error;

  double _avgRating    = 0;
  int    _totalReviews = 0;
  final  _starCounts   = <int, int>{5: 0, 4: 0, 3: 0, 2: 0, 1: 0};

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    try {
      final param = await postDio(
        '$server/m/case/review/read',
        {'lawyer': widget.lawyer['code']},
      );
      final list = List<dynamic>.from(param['objectData'] ?? []);

      _starCounts.updateAll((_, __) => 0);
      double total = 0;
      for (final r in list) {
        final rating = (r['rate'] as num?)?.round() ?? 0; // ✅ rate
        total += rating;
        if (_starCounts.containsKey(rating)) {
          _starCounts[rating] = (_starCounts[rating] ?? 0) + 1;
        }
      }

      setState(() {
        _reviews      = list;
        _totalReviews = list.length;
        _avgRating    = list.isEmpty ? 0 : total / list.length;
        _isLoading    = false;
      });
    } catch (e) {
      setState(() {
        _error     = e.toString();
        _isLoading = false;
      });
    }
  }

  /// "20260612151606" + "15:16:06" → "12/06/2026  15:16:06"
  String _formatDate(String? dateStr, String? timeStr) {
    final d = dateStr ?? '';
    final t = timeStr ?? '';
    if (d.length < 8) return t;
    final year  = d.substring(0, 4);
    final month = d.substring(4, 6);
    final day   = d.substring(6, 8);
    return '$day/$month/$year${t.isNotEmpty ? '  $t' : ''}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: appBar(
        title: 'รีวิวทนายความ',
        backBtn: true,
        rightBtn: false,
        backAction: () => Navigator.pop(context),
        rightAction: () {},
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: _kPrimary, strokeWidth: 2))
          : _error != null
              ? _buildError()
              : CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                        child: Column(children: [
                          _buildLawyerHeader(),
                          const SizedBox(height: 16),
                          _buildRatingSummary(),
                          const SizedBox(height: 20),
                          Row(children: [
                            const Text('รีวิวทั้งหมด',
                                style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF1A2340))),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: _kPrimary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text('$_totalReviews',
                                  style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: _kPrimary)),
                            ),
                          ]),
                          const SizedBox(height: 12),
                        ]),
                      ),
                    ),
                    _reviews.isEmpty
                        ? SliverToBoxAdapter(child: _buildEmpty())
                        : SliverPadding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
                            sliver: SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (_, i) => Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: _buildReviewCard(_reviews[i]),
                                ),
                                childCount: _reviews.length,
                              ),
                            ),
                          ),
                  ],
                ),
    );
  }

  Widget _buildLawyerHeader() {
    final name     = '${widget.lawyer['firstName'] ?? ''} ${widget.lawyer['lastName'] ?? ''}'.trim();
    final imageUrl = widget.lawyer['imageUrl']?.toString() ?? '';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0262EC), Color(0xFF34AAFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: _kPrimary.withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 4))],
      ),
      child: Row(children: [
        Container(
          width: 56, height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withOpacity(0.4), width: 2),
          ),
          child: ClipOval(
            child: imageUrl.isNotEmpty
                ? Image.network(imageUrl, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _avatarFallback(name))
                : _avatarFallback(name),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name.isNotEmpty ? name : 'ทนายความ',
                style: GoogleFonts.prompt(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Row(children: [
              const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
              const SizedBox(width: 4),
              Text(_avgRating.toStringAsFixed(1),
                  style: GoogleFonts.prompt(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
              Text('  ($_totalReviews รีวิว)',
                  style: GoogleFonts.prompt(color: Colors.white70, fontSize: 12)),
            ]),
          ]),
        ),
      ]),
    );
  }

  Widget _avatarFallback(String name) {
    final initial = name.isNotEmpty ? name[0] : '?';
    return Container(
      color: Colors.white.withOpacity(0.2),
      child: Center(
          child: Text(initial,
              style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold))),
    );
  }

  Widget _buildRatingSummary() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
        Column(children: [
          Text(_avgRating.toStringAsFixed(1),
              style: GoogleFonts.prompt(
                  fontSize: 52, fontWeight: FontWeight.w800, color: const Color(0xFF1A2340), height: 1)),
          _buildStarRow(_avgRating, size: 16),
          const SizedBox(height: 4),
          Text('จาก $_totalReviews รีวิว',
              style: TextStyle(fontSize: 11, color: Colors.grey[400])),
        ]),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            children: [5, 4, 3, 2, 1].map((star) {
              final count = _starCounts[star] ?? 0;
              final ratio = _totalReviews == 0 ? 0.0 : count / _totalReviews;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(children: [
                  Text('$star',
                      style: TextStyle(fontSize: 11, color: Colors.grey[500], fontWeight: FontWeight.w600)),
                  const SizedBox(width: 4),
                  const Icon(Icons.star_rounded, size: 11, color: Colors.amber),
                  const SizedBox(width: 6),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: ratio,
                        minHeight: 8,
                        backgroundColor: const Color(0xFFF0F3F8),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          star >= 4 ? const Color(0xFF34C759) : star == 3 ? Colors.amber : const Color(0xFFFF3B30),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  SizedBox(
                    width: 20,
                    child: Text('$count', style: TextStyle(fontSize: 11, color: Colors.grey[400])),
                  ),
                ]),
              );
            }).toList(),
          ),
        ),
      ]),
    );
  }

  Widget _buildReviewCard(Map<String, dynamic> review) {
    final rating   = (review['rate'] as num?)?.round() ?? 0;       // ✅ rate
    final comment  = review['comment']?.toString() ?? '';
    final userRef  = review['userRef']?.toString() ?? '';           // ✅ userRef
    final dateStr  = review['dateReview']?.toString() ?? '';        // ✅ dateReview
    final timeStr  = review['timeReview']?.toString() ?? '';        // ✅ timeReview
    final dateText = _formatDate(dateStr, timeStr);

    // แสดง userRef ย่อท้าย 6 ตัว เพื่อความเป็นส่วนตัว
    final userLabel = userRef.length > 6
        ? 'ผู้ใช้ ...${userRef.substring(userRef.length - 6)}'
        : userRef.isNotEmpty ? userRef : 'ผู้ใช้งาน';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: _kPrimary.withOpacity(0.1), shape: BoxShape.circle),
            child: Center(
              child: const Icon(Icons.person_rounded, size: 20, color: _kPrimary),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(userLabel,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1A2340))),
              const SizedBox(height: 2),
              Text(dateText, style: TextStyle(fontSize: 11, color: Colors.grey[400])),
            ]),
          ),
          // Rating badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _ratingColor(rating).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.star_rounded, size: 13, color: _ratingColor(rating)),
              const SizedBox(width: 3),
              Text('$rating',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _ratingColor(rating))),
            ]),
          ),
        ]),

        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: _buildStarRow(rating.toDouble(), size: 14),
        ),

        if (comment.isNotEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FB),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(comment,
                style: const TextStyle(fontSize: 13, color: Color(0xFF3D5270), height: 1.5)),
          )
        else
          Text('ไม่มีความคิดเห็น',
              style: TextStyle(fontSize: 12, color: Colors.grey[400], fontStyle: FontStyle.italic)),
      ]),
    );
  }

  Widget _buildStarRow(double rating, {double size = 16}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final filled = i < rating.floor();
        final half   = !filled && i < rating;
        return Icon(
          filled ? Icons.star_rounded : half ? Icons.star_half_rounded : Icons.star_outline_rounded,
          color: Colors.amber,
          size: size,
        );
      }),
    );
  }

  Color _ratingColor(int rating) {
    if (rating >= 4) return const Color(0xFF34C759);
    if (rating == 3) return Colors.amber;
    return const Color(0xFFFF3B30);
  }

  Widget _buildEmpty() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 72, height: 72,
          decoration: BoxDecoration(color: const Color(0xFFEEF4FF), shape: BoxShape.circle),
          child: const Icon(Icons.rate_review_outlined, color: _kPrimary, size: 32),
        ),
        const SizedBox(height: 14),
        const Text('ยังไม่มีรีวิว',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF1A2340))),
        const SizedBox(height: 6),
        Text('เมื่อลูกความรีวิวแล้วจะแสดงที่นี่',
            style: TextStyle(fontSize: 12, color: Colors.grey[400])),
      ]),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.error_outline_rounded, color: Color(0xFFFF3B30), size: 48),
          const SizedBox(height: 12),
          const Text('โหลดข้อมูลไม่สำเร็จ',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF1A2340))),
          const SizedBox(height: 8),
          Text(_error ?? '',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey[400])),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: () {
              setState(() => _isLoading = true);
              _loadReviews();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(color: _kPrimary, borderRadius: BorderRadius.circular(12)),
              child: const Text('ลองใหม่',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
            ),
          ),
        ]),
      ),
    );
  }
}