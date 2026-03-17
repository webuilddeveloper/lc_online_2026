import 'package:LawyerOnline/component/appbar.dart';
import 'package:LawyerOnline/consult/consult_status.dart';
import 'package:LawyerOnline/message-form.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ConsultDetailPage extends StatefulWidget {
  final Map<String, dynamic> lawyer;
  const ConsultDetailPage({super.key, required this.lawyer});

  @override
  State<ConsultDetailPage> createState() => _ConsultDetailPageState();
}

class _ConsultDetailPageState extends State<ConsultDetailPage> {
  bool isFavorite = false;

  @override
  Widget build(BuildContext context) {
    final color = Color(widget.lawyer['color'] as int);

    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F7),
      appBar: appBar(
        title: "รายละเอียดหมอความ",
        backBtn: true,
        rightBtn: true,
        backAction: () => Navigator.pop(context, false),
        isFavorite: isFavorite,
        rightAction: () {
          setState(() {
            isFavorite = !isFavorite;
          });
        },
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 15, 16, 16),
              children: [
                _buildHeaderCard(context, color),
                const SizedBox(height: 16),
                _buildAboutCard(widget.lawyer),
              ],
            ),
          ),
          _buildBookingButton(context),
        ],
      ),
    );
  }

  Widget _buildHeaderCard(BuildContext context, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            child: Opacity(
              opacity: 0.07,
              child: Icon(Icons.balance, size: 120, color: color),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.lawyer['name'] as String,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                              color: Color(0xFF1A2340)),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Text(
                              '${widget.lawyer['rating']}',
                              style: const TextStyle(
                                  color: Color(0xFF0262EC),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.star_rounded,
                                color: Color(0xFFFFC107), size: 18),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            btmCard(
                                icon: "assets/icons/phone.png",
                                action: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => MessageFormPage(
                                        model: widget.lawyer,
                                      ),
                                    ),
                                  );
                                }),
                            const SizedBox(width: 15),
                            btmCard(
                                icon: "assets/icons/videocall.png",
                                action: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => MessageFormPage(
                                        model: widget.lawyer,
                                      ),
                                    ),
                                  );
                                }),
                            const SizedBox(width: 15),
                            btmCard(
                                icon: "assets/icons/chat.png",
                                action: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => MessageFormPage(
                                        model: widget.lawyer,
                                      ),
                                    ),
                                  );
                                }),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      width: 110,
                      height: 130,
                      color: const Color(0xFFF2F4F7),
                      child: widget.lawyer['imageUrl'] != null
                          ? Image.asset(
                              widget.lawyer['imageUrl'] as String,
                              fit: BoxFit.cover,
                            )
                          : Center(
                              child: Text(
                                widget.lawyer['avatar'] as String,
                                style: TextStyle(
                                    fontSize: 48,
                                    color: Color(widget.lawyer['color'] as int),
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget btmCard({String? icon, Function? action}) {
    return GestureDetector(
      onTap: () => action?.call(),
      child: Container(
        width: 35,
        height: 35,
        alignment: Alignment.center,
        // padding: const EdgeInsets.symmetric(
        //   horizontal: 12,
        //   vertical: 10,
        // ),
        decoration: BoxDecoration(
          color: const Color(0xFFFAFAFA),
          borderRadius: BorderRadius.circular(12.8),
          border: Border.all(
            width: 1,
            color: const Color(0xFFDBDBDB),
          ),
        ),
        child: Image.asset(
          icon ?? '',
          width: 16,
          height: 16,
        ),
      ),
    );
  }

  Widget _buildAboutCard(Map<String, dynamic> l) {
    final specialties = (l['specialty'] as String).split(', ');
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('About Lawyer',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Color(0xFF1A2340))),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: specialties
                .map((s) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFDDE3EE)),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(s,
                          style: const TextStyle(
                              fontSize: 12, color: Color(0xFF444E6A))),
                    ))
                .toList(),
          ),
          const SizedBox(height: 16),
          const Divider(color: Color(0xFFEEF2F5)),
          const SizedBox(height: 16),
          Row(
            children: [
              _statBox('🏆', '148+', 'Cases Won'),
              const SizedBox(width: 10),
              _statBox('📅', l['experience'] as String, 'Experience'),
              const SizedBox(width: 10),
              _statBox('⭐', '${l['reviews']}+', 'Client Reviews'),
            ],
          ),
          const SizedBox(height: 20),
          const Text('Social Media Names',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: Color(0xFF1A2340))),
          const SizedBox(height: 14),
          Row(
            children: [
              socialItem(
                  icon: "assets/icons/facebook.png",
                  action: () {
                    launch("https://www.facebook.com/");
                  }),
              const SizedBox(width: 15),
              socialItem(
                  icon: "assets/icons/ig.png",
                  action: () {
                    launch("https://www.instagram.com/");
                  }),
              const SizedBox(width: 15),
              socialItem(
                  icon: "assets/icons/x.png",
                  action: () {
                    launch("https://x.com/");
                  }),
              const SizedBox(width: 15),
              socialItem(
                  icon: "assets/icons/linkin.png",
                  action: () {
                    launch("https://www.linkedin.com/");
                  }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statBox(String emoji, String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F9FB),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFEEF2F5)),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 4),
            Text(value,
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Color(0xFF1A2340))),
            const SizedBox(height: 2),
            Text(label,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 10, color: Colors.grey[500])),
          ],
        ),
      ),
    );
  }

  Widget socialItem({String? icon, Function? action}) {
    return GestureDetector(
      onTap: () => action?.call(),
      child: Container(
        width: 42,
        height: 42,
        alignment: Alignment.center,
        // padding: const EdgeInsets.symmetric(
        //   horizontal: 12,
        //   vertical: 10,
        // ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.8),
          border: Border.all(
            width: 1,
            color: const Color(0xFFDBDBDB),
          ),
        ),
        child: Image.asset(
          icon ?? '',
          width: 18,
          height: 18,
        ),
      ),
    );
  }

  Widget _socialBtnIcon(IconData icon) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFDDE3EE)),
      ),
      child: Icon(icon, size: 20, color: const Color(0xFF1A2340)),
    );
  }

  Widget _buildBookingButton(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          16, 8, 16, MediaQuery.of(context).padding.bottom + 12),
      child: GestureDetector(
        onTap: () => _showSuccessDialog(context),
        child: Container(
          height: 54,
          decoration: BoxDecoration(
            color: const Color(0xFF0262EC),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0262EC).withOpacity(0.35),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Center(
            child: Text(
              'จองนัดหมาย',
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16),
            ),
          ),
        ),
      ),
    );
  }

  void _showSuccessDialog(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.6),
      transitionDuration: const Duration(milliseconds: 400),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return ScaleTransition(
          scale: CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
          child: FadeTransition(opacity: animation, child: child),
        );
      },
      pageBuilder: (context, _, __) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 36),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF4CAF50).withOpacity(0.15),
                blurRadius: 40,
                offset: const Offset(0, 16),
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 24,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF66BB6A), Color(0xFF43A047)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF4CAF50).withOpacity(0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(Icons.check_rounded,
                    color: Colors.white, size: 40),
              ),
              const SizedBox(height: 24),
              const Text(
                'สำเร็จ',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 20,
                  color: Color(0xFF1A1A2E),
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'บันทึกข้อมูลเรียบร้อยแล้ว...',
                style: TextStyle(color: Colors.grey[400], fontSize: 13.5),
              ),
              const SizedBox(height: 28),
              GestureDetector(
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ConsultStatusPage(lawyer: widget.lawyer),
                    ),
                  );
                },
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFF4CAF50),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Center(
                    child: Text('ตกลง',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 15)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void goBack(value) async {
    Navigator.pop(context, value);
  }
}
