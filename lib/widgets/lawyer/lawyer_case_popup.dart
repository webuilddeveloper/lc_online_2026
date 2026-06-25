import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LawyerCasePopup extends StatefulWidget {
  final dynamic caseData;
  final int expiresInSeconds;
  final Function() onAccept;
  final VoidCallback onDismiss;

  const LawyerCasePopup({
    super.key,
    required this.caseData,
    required this.expiresInSeconds,
    required this.onAccept,
    required this.onDismiss,
  });

  @override
  State<LawyerCasePopup> createState() => _LawyerCasePopupState();
}

class _LawyerCasePopupState extends State<LawyerCasePopup>
    with TickerProviderStateMixin {
  late int _secondsLeft;
  Timer? _timer;
  bool _isSubmitting = false;
  bool _accepted = false;
  String? _errorMsg;
  bool _isMounted = true;

  // ✅ Animation controllers
  late AnimationController _enterCtrl;
  late Animation<double> _scaleAnim;
  late Animation<double> _opacityAnim;
  late Animation<Offset> _slideAnim;

  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _secondsLeft = widget.expiresInSeconds;

    // ✅ Enter animation
    _enterCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _scaleAnim = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _enterCtrl, curve: Curves.easeOutBack),
    );

    _opacityAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _enterCtrl, curve: Curves.easeInOut),
    );

    _slideAnim =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
      CurvedAnimation(parent: _enterCtrl, curve: Curves.easeOutCubic),
    );

    // ✅ Pulse animation untuk icon
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnim = Tween<double>(begin: 1.0, end: 1.12).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );

    // ✅ Mulai enter animation
    _enterCtrl.forward();

    // ✅ Countdown timer
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      if (_secondsLeft <= 1) {
        t.cancel();
        _close();
        return;
      }

      if (_isMounted && mounted) {
        setState(() => _secondsLeft--);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _enterCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  void _close() {
    _timer?.cancel();
    widget.onDismiss();
    // if (mounted) Navigator.pop(context);
  }

  Future<void> _handleAccept() async {
    if (_isSubmitting || _accepted) return;

    // ✅ หยุด timer ทันทีตอนกดปุ่ม
    _timer?.cancel();

    setState(() {
      _isSubmitting = true;
      _errorMsg = null;
    });

    try {
      await widget.onAccept();
      if (!_isMounted || !mounted) return;
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _accepted = true;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _errorMsg = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  String _text(String key, [String fallback = '-']) {
    final v = widget.caseData[key];
    if (v == null) return fallback;
    final s = v.toString().trim();
    return s.isEmpty ? fallback : s;
  }

  // ✅ Timer Progress Widget - ลดขนาด
  Widget _buildTimerProgress() {
    final progress = _secondsLeft / widget.expiresInSeconds;
    final progressColor = progress > 0.3
        ? const Color(0xFF0262EC)
        : progress > 0.1
            ? Colors.orange
            : Colors.red;

    return Column(
      children: [
        // ✅ Circular progress - เล็กลง
        SizedBox(
          width: 50,
          height: 50,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFEEF2F5),
                ),
              ),
              SizedBox(
                width: 50,
                height: 50,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                  backgroundColor: const Color(0xFFEEF2F5),
                ),
              ),
              Text(
                _secondsLeft.toString(),
                style: GoogleFonts.prompt(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: progressColor,
                  decoration: TextDecoration.none,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'วินาที',
          style: GoogleFonts.prompt(
            fontSize: 11,
            color: Colors.grey[600],
            decoration: TextDecoration.none,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnim,
      child: FadeTransition(
        opacity: _opacityAnim,
        child: SlideTransition(
          position: _slideAnim,
          child: Center(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              constraints: const BoxConstraints(maxWidth: 360),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0262EC).withOpacity(0.15),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ✅ Header - ลดความสูง padding
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                    decoration: const BoxDecoration(
                      color: Color(0xFFFAFBFD),
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(24)),
                      border: Border(
                        bottom: BorderSide(
                          color: Color(0xFFEEF2F5),
                          width: 1,
                        ),
                      ),
                    ),
                    child: Column(
                      children: [
                        // ✅ Animated Icon - เล็กลง
                        ScaleTransition(
                          scale: _pulseAnim,
                          child: Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: const Color(0xFF0262EC).withOpacity(0.08),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.gavel_rounded,
                              color: Color(0xFF0262EC),
                              size: 26,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          _accepted ? 'ส่งคำขอแล้ว' : 'เคสด่วนใหม่!',
                          style: GoogleFonts.prompt(
                            color: const Color(0xFF1A2340),
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            decoration: TextDecoration.none,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _accepted
                              ? 'คำขอของคุณส่งไปแล้ว'
                              : 'รับเคสก่อนทนายท่านอื่น',
                          style: GoogleFonts.prompt(
                            color: Colors.grey[600],
                            fontSize: 12,
                            decoration: TextDecoration.none,
                          ),
                        ),
                        if (!_accepted) ...[
                          const SizedBox(height: 10),
                          _buildTimerProgress(),
                        ],
                      ],
                    ),
                  ),

                  // ✅ Content - ลดความสูง
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ✅ Info tiles - เล็กลง compact
                          _infoTile(
                            Icons.person_outline,
                            'ลูกความ',
                            _text(
                                'userName', _text('clientName', 'ไม่ระบุชื่อ')),
                          ),
                          const SizedBox(height: 8),
                          _infoTile(
                            Icons.gavel_outlined,
                            'ประเภทคดี',
                            _text('topicTitle', 'ไม่ระบุ'),
                          ),
                          const SizedBox(height: 8),
                          _infoTile(
                            Icons.folder_outlined,
                            'ประเภทย่อย',
                            _text('subTopicTitle', 'ไม่ระบุ'),
                          ),
                          const SizedBox(height: 8),
                          _infoTile(
                            Icons.location_on_outlined,
                            'จังหวัด',
                            _text(
                                'provinceTitle', _text('province', 'ไม่ระบุ')),
                          ),
                          const SizedBox(height: 8),
                          _infoTile(
                            Icons.notes_outlined,
                            'รายละเอียด',
                            _text('details',
                                _text('details', 'ไม่ได้ระบุรายละเอียด')),
                            maxLines: 2,
                          ),

                          // ✅ Error message
                          if (_errorMsg != null) ...[
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFEBEE),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color:
                                      const Color(0xFFEF5350).withOpacity(0.3),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.error_outline,
                                    color: Color(0xFFC62828),
                                    size: 16,
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      _errorMsg!,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.prompt(
                                        color: const Color(0xFFC62828),
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        decoration: TextDecoration.none,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          const SizedBox(height: 12),

                          // ✅ Buttons - เล็กลง
                          if (_accepted)
                            _buildButton(
                              label: 'ปิด',
                              onPressed: _close,
                              isPrimary: true,
                            )
                          else
                            Row(
                              children: [
                                Expanded(
                                  child: _buildButton(
                                    label: 'ปิด',
                                    onPressed: _isSubmitting ? null : _close,
                                    isPrimary: false,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  flex: 2,
                                  child: _buildButton(
                                    label: _isSubmitting ? '' : 'รับเคส',
                                    onPressed:
                                        _isSubmitting ? null : _handleAccept,
                                    isPrimary: true,
                                    isLoading: _isSubmitting,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ✅ Modern button widget - เล็กลง
  Widget _buildButton({
    required String label,
    required VoidCallback? onPressed,
    required bool isPrimary,
    bool isLoading = false,
  }) {
    return SizedBox(
      height: 44,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              color: isPrimary ? const Color(0xFF0262EC) : Colors.white,
              border: isPrimary
                  ? null
                  : Border.all(color: const Color(0xFFDDE3EE), width: 1.5),
              borderRadius: BorderRadius.circular(12),
              boxShadow: isPrimary
                  ? [
                      BoxShadow(
                        color: const Color(0xFF0262EC).withOpacity(0.25),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Center(
              child: isLoading
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isPrimary ? Colors.white : const Color(0xFF0262EC),
                        ),
                      ),
                    )
                  : Text(
                      label,
                      style: GoogleFonts.prompt(
                        color: isPrimary ? Colors.white : Colors.grey[700],
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        decoration: TextDecoration.none,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }

  // ✅ Clean info tile - ลดความสูง
  Widget _infoTile(
    IconData icon,
    String label,
    String value, {
    int maxLines = 2,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFBFD),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xFFEEF2F5),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFF0262EC).withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 16,
              color: const Color(0xFF0262EC),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.prompt(
                    fontSize: 10,
                    color: Colors.grey[500],
                    fontWeight: FontWeight.w500,
                    decoration: TextDecoration.none,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: maxLines,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.prompt(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1A2340),
                    decoration: TextDecoration.none,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
