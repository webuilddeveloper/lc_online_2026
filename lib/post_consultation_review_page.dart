import 'package:LawyerOnline/component/appbar.dart';
import 'package:LawyerOnline/component/dialog_service.dart';
import 'package:LawyerOnline/component/loading_service.dart';
import 'package:LawyerOnline/shared/api_provider.dart';
import 'package:LawyerOnline/shared/app_typography.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

class PostConsultationReviewPage extends StatefulWidget {
  final String caseCode;
  final String lawyerRef;
  final String userRef;
  final String lawyerName;

  const PostConsultationReviewPage({
    super.key,
    required this.caseCode,
    required this.lawyerRef,
    required this.userRef,
    this.lawyerName = '',
  });

  @override
  State<PostConsultationReviewPage> createState() =>
      _PostConsultationReviewPageState();
}

class _PostConsultationReviewPageState
    extends State<PostConsultationReviewPage> {
  final _commentCtrl = TextEditingController();
  double _rating = 5;
  bool _submitting = false;

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_commentCtrl.text.trim().isEmpty) {
      DialogService.showError(
        context,
        title: 'errorTitle'.tr(),
        message: 'reviewCommentRequired'.tr(),
      );
      return;
    }

    setState(() => _submitting = true);
    DialogService.showLoading(context);
    try {
      final model = {
        'lawyerRef': widget.lawyerRef,
        'caseRef': widget.caseCode,
        'userRef': widget.userRef,
        'comment': _commentCtrl.text.trim(),
        'rate': _rating.round(),
      };
      final param = await postDio('${server}/m/case/review/create', model);
      if (param['status'] == 'S') {
        await postDio('${server}/m/case/update', {
          'code': widget.caseCode,
          'isReview': true,
          'caseStatus': 4,
        });
        if (!mounted) return;
        Navigator.pop(context);
        DialogService.showSuccess(
          context,
          title: 'reviewSuccessTitle'.tr(),
          message: 'reviewSuccessMessage'.tr(),
          onClose: () => Navigator.pop(context, true),
        );
      } else {
        throw Exception(param['message']?.toString() ?? 'reviewFailed'.tr());
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      DialogService.showError(
        context,
        title: 'errorTitle'.tr(),
        message: e.toString(),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEEF2F5),
      appBar: appBar(
        title: 'reviewPageTitle'.tr(),
        backBtn: true,
        rightBtn: false,
        backAction: () => Navigator.pop(context),
        rightAction: () {},
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            widget.lawyerName.isNotEmpty
                ? widget.lawyerName
                : 'reviewLawyerDefault'.tr(),
            style: AppTypography.prompt(
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text('reviewPageSubtitle'.tr(), style: AppTypography.hint()),
          const SizedBox(height: 24),
          Center(
            child: RatingBar.builder(
              initialRating: _rating,
              minRating: 1,
              itemSize: 36,
              unratedColor: const Color(0xFFE0E0E0),
              itemBuilder: (_, __) =>
                  const Icon(Icons.star_rounded, color: Color(0xFFFFC107)),
              onRatingUpdate: (v) => setState(() => _rating = v),
            ),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _commentCtrl,
            maxLines: 5,
            decoration: InputDecoration(
              hintText: 'reviewCommentHint'.tr(),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _submitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0262EC),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _submitting
                  ? const AppRingSpinner(color: Colors.white, size: 20)
                  : Text('reviewSubmit'.tr(), style: AppTypography.button()),
            ),
          ),
        ],
      ),
    );
  }
}
