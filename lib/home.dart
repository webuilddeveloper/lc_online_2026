import 'package:LawyerOnline/appointment-details-lawyer.dart';
import 'package:LawyerOnline/booking/topic-page.dart';
import 'package:LawyerOnline/carousel_form.dart';
import 'package:LawyerOnline/case-status-all.dart';
import 'package:LawyerOnline/component/appbar.dart';
import 'package:LawyerOnline/component/comming-soon.dart';
import 'package:LawyerOnline/component/link_url_in.dart';
import 'package:LawyerOnline/consult/consult.dart';
import 'package:LawyerOnline/consult/consult_status.dart';
import 'package:LawyerOnline/law_type_all_page.dart';
import 'package:LawyerOnline/lawyer-job-list.dart';
import 'package:LawyerOnline/lawyer-online-details.dart';
import 'package:LawyerOnline/lawyer-online-list.dart';
import 'package:LawyerOnline/menu.dart';
import 'package:LawyerOnline/notification.dart';
import 'package:LawyerOnline/shared/api_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:permission_handler/permission_handler.dart';

// ─── Palette & theme constants ───────────────────────────────────────
const _kPrimary = Color(0xFF0262EC); // deep navy
const _kAccent = Color(0xFF2F80ED); // bright blue
const _kGold = Color(0xFFF5A623); // justice-gold accent
const _kSurface = Color(0xFFF4F6FB); // cool light background
const _kCard = Colors.white;
const _kText = Color(0xFF0D1B2A);
const _kSub = Color(0xFF6B7A99);

class HomePage extends StatefulWidget {
  const HomePage({Key? key, this.userType});
  final String? userType;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  List<dynamic> mockBannerList = [];
  int _currentBanner = 0;
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  List<dynamic> lawyerOnlineList = [
    {
      "code": "0",
      "name": "ศักดิ์สิทธิ์ พิพากษ์",
      'title': 'ทนายความอาวุโส',
      "scroll": 4.8,
      "cost": "Free",
      "costUnit": "/hr",
      "imageUrl": "assets/images/lawyer-avatar-1.png",
      "experience": "11+ ปี",
      "price": 500,
      "skills": ["อาญาและอาชญากรรม", "ครอบครัวและมรดก"],
    },
    {
      "code": "1",
      "name": "ธนากร นิติศักดิ์",
      'title': 'ทนายความอาวุโส',
      "scroll": 4.1,
      "cost": "Free",
      "costUnit": "/hr",
      "imageUrl": "assets/images/lawyer-avatar-2.png",
      "experience": "19+ ปี",
      "price": 500,
      "skills": ["หนี้สินและการเงิน", "ธุรกิจและบริษัท"],
    },
    {
      "code": "2",
      "name": "พงษ์ภพ ยุติธรรม",
      'title': 'ทนายความอาวุโส',
      "scroll": 3.9,
      "cost": "Free",
      "costUnit": "/hr",
      "imageUrl": "assets/images/lawyer-avatar-3.png",
      "experience": "10+ ปี",
      "price": 500,
      "skills": ["แรงงานและการจ้างงาน", "ประกันภัยและผู้บริโภค"],
    },
    {
      "code": "3",
      "name": "อาริย์ ศิษย์กฎหมาย",
      'title': 'ทนายความอาวุโส',
      "scroll": 3.0,
      "cost": "200",
      "costUnit": "/hr",
      "imageUrl": "assets/images/lawyer-avatar-4.png",
      "experience": "12+ ปี",
      "price": 500,
      "skills": ["ทรัพย์สินและที่ดิน", "ฟ้องศาล เรียกค่าเสียหาย"],
    },
    {
      "code": "4",
      "name": "Sachin K",
      'title': 'ทนายความอาวุโส',
      "scroll": 4.9,
      "cost": "1,000",
      "costUnit": "/hr",
      "imageUrl": "assets/images/lawyer-avatar-5.png",
      "experience": "20+ ปี",
      "price": 500,
      "skills": ["คดีออนไลน์และเทคโนโลยี", "อื่นๆและระหว่างประเทศ"],
    },
  ];

  List<dynamic> appointmentList = [
    {
      "code": "0",
      "clientName": "อนงค์ ดำเนิน",
      "caseType": "คดีมรดกทุกประเภท",
      "subCaseType": "ฟ้องร้องมรดก",
      "appointmentDate": "28/03/2026",
      "appointmentTime": "11.00 - 14.00",
      "title": "ขอฟ้องร้องมรดกพี่น้อง",
      "details": "ต้องการฟ้องร้องพี่น้องที่โกงเงินมรดก",
      "paymentStatus": "1",
    },
    {
      "code": "1",
      "clientName": "อนงค์ ดำเนิน",
      "caseType": "คดีมรดกทุกประเภท",
      "subCaseType": "ฟ้องร้องมรดก",
      "appointmentDate": "28/03/2026",
      "appointmentTime": "11.00 - 14.00",
      "title": "ขอฟ้องร้องมรดกพี่น้อง",
      "details": "ต้องการฟ้องร้องพี่น้องที่โกงเงินมรดก",
      "paymentStatus": "1",
    },
  ];

  List<dynamic> caseList = [
    {
      "code": "0",
      "name": "ศักดิ์สิทธิ์ พิพากษ์",
      "category": "กฏหมายครอบครัว",
      "story": "เมื่อ2ปีที่แล้ว ดิฉันได้จ้างทนายท่านนี้เพื่อทำคดีของสามี",
      "createDate": "9 ชั่วโมงที่ผ่านมา",
      "appointmentDate": "28/03/2026",
      "appointmentTime": "11.00 - 14.00",
      "lawyerApprove": true,
      "lawyerModel": {
        "code": "0",
        "name": "ศักดิ์สิทธิ์ พิพากษ์",
        "scroll": 4.8,
        "cost": "ไม่เสียค่าใช้จ่าย",
        "costUnit": "/hr",
        "imageUrl": "assets/images/lawyer-avatar-1.png",
        "experience": "11+ years",
        "skills": ["Family lawyer", "Estate planning lawyer"]
      },
      "position": const LatLng(13.7466, 100.5393),
      "status": "3",
      "statusText": "กำลังปรึกษา",
    },
    {
      "code": "1",
      "name": "ศักดิ์สิทธิ์ พิพากษ์",
      "category": "กฏหมายครอบครัว",
      "story": "เมื่อ2ปีที่แล้ว ดิฉันได้จ้างทนายท่านนี้เพื่อทำคดีของสามี",
      "createDate": "9 ชั่วโมงที่ผ่านมา",
      "appointmentDate": "28/03/2026",
      "appointmentTime": "11.00 - 14.00",
      "lawyerApprove": true,
      "lawyerModel": {
        "code": "0",
        "name": "ศักดิ์สิทธิ์ พิพากษ์",
        "scroll": 4.8,
        "cost": "ไม่เสียค่าใช้จ่าย",
        "costUnit": "/hr",
        "imageUrl": "assets/images/lawyer-avatar-1.png",
        "experience": "11+ years",
        "skills": ["Family lawyer", "Estate planning lawyer"]
      },
      "position": const LatLng(13.7466, 100.5393),
      "status": "4",
      "statusText": "เสร็จสิ้น",
    },
  ];

  // ─── law categories ───────────────────────────────────────────────
  final List<Map<String, dynamic>> _lawCategories = [
    {
      "title": "อาญา\nและอาชญากรรม",
      "icon": "assets/icons/law-type-1.png",
      "topic": "อาญาและอาชญากรรม"
    },
    {
      "title": "ครอบครัว\nและมรดก",
      "icon": "assets/icons/law-type-2.png",
      "topic": "ครอบครัวและมรดก"
    },
    {
      "title": "ธุรกิจ\nและบริษัท",
      "icon": "assets/icons/law-type-3.png",
      "topic": "ธุรกิจและบริษัท"
    },
    {
      "title": "แรงงาน\nและจ้างงาน",
      "icon": "assets/icons/law-type-4.png",
      "topic": "แรงงานและการจ้างงาน"
    },
  ];

  final storage = FlutterSecureStorage();
  String userType = "";
  String imageUrl = "";
  String name = "";
  String typeLogin = "";

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    callRead();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      requestPermissions();
      _fadeCtrl.forward();
    });
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  Future<void> requestPermissions() async {
    await [
      Permission.camera,
      Permission.microphone,
      Permission.photos,
      Permission.location
    ].request();
  }

  callRead() async {
    final uType = await storage.read(key: 'userType');
    final imgPro = await storage.read(key: 'imageUrlSocial');
    final namePro = await storage.read(key: 'name');
    final type = await storage.read(key: 'typeLogin');
    setState(() {
      userType = uType ?? '';
      name = namePro ?? '';
      imageUrl = imgPro ?? '';
      typeLogin = type.toString();
    });
    final value =
        await postDio('${mainBannerApi}read', {'skip': 0, 'limit': 10});
    setState(() {
      mockBannerList = value;
    });
  }

  // ─── status helpers ───────────────────────────────────────────────
  _StatusStyle _statusStyle(String status) {
    switch (status) {
      case '1':
        return _StatusStyle(const Color(0xFFDC2626), const Color(0xFFFEF2F2),
            Icons.info_outline_rounded);
      case '2':
        return _StatusStyle(const Color(0xFFD97706), const Color(0xFFFFFBEB),
            Icons.pending_actions_rounded);
      case '3':
        return _StatusStyle(
            _kAccent, const Color(0xFFEFF6FF), Icons.pending_actions_rounded);
      default:
        return _StatusStyle(const Color(0xFF059669), const Color(0xFFECFDF5),
            Icons.check_circle_outline_rounded);
    }
  }

  int _statusToStep(String status) => status == '4' ? 4 : 3;

  dynamic _buildLawyerForConsult(Map? m) {
    if (m == null) return null;
    return {
      'name': m['name'] ?? '',
      'avatar': (m['name'] as String? ?? 'ท').characters.first,
      'title': (m['skills'] as List?)?.isNotEmpty == true
          ? (m['skills'] as List).first
          : m['experience'] ?? '',
      'rating': m['scroll'] ?? 0,
      'imageUrl': m['imageUrl'] ?? '',
    };
  }

  void _goToConsultStatus(Map model) {
    Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ConsultStatusPage(
            currentStep: _statusToStep(model['status']?.toString() ?? '1'),
            lawyer: _buildLawyerForConsult(model['lawyerModel'] as Map?),
            appointmentDate: model['appointmentDate'],
            appointmentTime: model['appointmentTime'],
          ),
        ));
  }

  // ═══════════════════════════════════════════════════════════════════
  //  BUILD
  // ═══════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Scaffold(
          backgroundColor: const Color.fromARGB(255, 233, 242, 249),
          body: FadeTransition(
            opacity: _fadeAnim,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // ── SliverAppBar with gradient ──────────────────────
                _buildSliverAppBar(size),
                // SliverToBoxAdapter(child: _buildBody(size)),
                SliverToBoxAdapter(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      // อย่างน้อยต้องสูงเต็มจอ หักความสูง appbar ออก
                      minHeight: MediaQuery.of(context).size.height - 100,
                    ),
                    child: _buildBody(size),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Sliver App Bar ───────────────────────────────────────────────

  Widget _buildSliverAppBar(Size size) {
    return SliverAppBar(
      pinned: true,
      floating: false,
      snap: false,
      expandedHeight: 100, // เท่ากับ collapsedHeight → ไม่ expand/collapse
      collapsedHeight: 100,
      toolbarHeight: 10,
      backgroundColor: const Color.fromARGB(255, 233, 242, 249),
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.black.withOpacity(0.7),
      elevation: 0,
      scrolledUnderElevation: 6, // shadow โชว์เฉพาะตอน scroll ผ่าน
      automaticallyImplyLeading: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.pin,
        background: Stack(
          fit: StackFit.expand,
          children: [
            // gavel icon watermark
            Positioned(
              right: 20,
              bottom: 0,
              child: Icon(
                Icons.gavel_rounded,
                color: const Color(0xFF1565C0).withOpacity(0.06),
                size: 100,
              ),
            ),
            Positioned(
              left: 5,
              bottom: -20,
              child: Icon(
                Icons.balance,
                color: const Color(0xFF1565C0).withOpacity(0.06),
                size: 150,
              ),
            ),
            // content
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _buildAvatar(),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "สวัสดี,",
                            style: GoogleFonts.prompt(
                              color: Colors.black.withOpacity(0.5),
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            name.isNotEmpty ? name : "ผู้ใช้งาน",
                            style: GoogleFonts.prompt(
                              color: Colors.black,
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          _buildMemberBadge(),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => NotificationPage()),
                      ),
                      child: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1565C0).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFF1565C0).withOpacity(0.2),
                          ),
                        ),
                        child: Stack(alignment: Alignment.center, children: [
                          Image.asset(
                            "assets/icons/bell.png",
                            width: 20,
                            height: 20,
                            color: const Color(0xFF1565C0),
                          ),
                          Positioned(
                            top: 8,
                            right: 9,
                            child: Container(
                              width: 7,
                              height: 7,
                              decoration: const BoxDecoration(
                                color: _kGold,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ]),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: _kPrimary.withOpacity(0.7), width: 1),
      ),
      child: ClipOval(
          child: imageUrl.isNotEmpty
              ? typeLogin == 'social'
                  ? Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      width: 32,
                      height: 32,
                    )
                  : Image.asset(
                      imageUrl,
                      fit: BoxFit.cover,
                      width: 32,
                      height: 32,
                    )
              : Image.asset(
                  imageUrl,
                  fit: BoxFit.cover,
                  width: 32,
                  height: 32,
                )

          // CachedNetworkImage(imageUrl: imageUrl, fit: BoxFit.cover)
          // : Image.asset('assets/images/profile-avatar.jpg',
          //     fit: BoxFit.cover),
          ),
    );
  }

  Widget _buildMemberBadge() {
    final label = userType == 'lawyer' ? 'หมอความ' : 'บุคคลทั่วไป';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _kGold),
      ),
      child: Text(label,
          style: GoogleFonts.prompt(
              color: _kGold, fontSize: 10, fontWeight: FontWeight.w600)),
    );
  }

  // ─── Body ────────────────────────────────────────────────────────
  Widget _buildBody(Size size) {
    return IntrinsicHeight(
      child: Container(
        padding: const EdgeInsets.only(bottom: 100),
        decoration: const BoxDecoration(
          color: _kCard,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          // boxShadow: [
          //     BoxShadow(
          //       color: Colors.black.withOpacity(0.2),
          //       blurRadius: 16,
          //       offset: const Offset(0, -6),
          //     )
          //   ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
      
            // Action cards
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: userType != 'lawyer'
                  ? Row(children: [
                      Expanded(
                        child: _actionCard(
                          title: "เปิดเคส",
                          subtitle: "ให้ทนายรับงาน",
                          // icon: Icons.folder_open_rounded,
                          iconAssets: "assets/icons/open-case.png",
                          gradientColors: [
                            // const Color(0xFF0B3D91),
                            // const Color(0xFF1565C0)
                            _kCard,
                            _kCard
                          ],
                          titleColor: const Color(0xFF1565C0),
                          subTitleColor: const Color(0xFF1565C0),
                          iconColor: const Color(0xFF1565C0),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ConsultPage(),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                          child: _actionCard(
                        title: "นัดหมาย",
                        subtitle: "จองเวลาปรึกษา",
                        // icon: Icons.calendar_today_rounded,
                        iconAssets: "assets/icons/appointment-lawyer.png",
                        gradientColors: [
                          const Color(0xFF1565C0),
                          const Color(0xFF1E88E5)
                        ],
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => TopicPage(),
                          ),
                        ),
                      )),
                    ])
                  : _actionCard(
                      title: "รับเคส",
                      subtitle: "ลูกความรอทนาย",
                      icon: Icons.work_rounded,
                      gradientColors: [_kPrimary, _kAccent],
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => LawyerJobListPage())),
                    ),
            ),
      
            const SizedBox(height: 24),
      
            // Banner
            _buildBannerSection(size),
      
            const SizedBox(height: 24),
      
            // Case Status (user only)
            if (userType == 'user') ...[
              _sectionHeader("สถานะเคสของคุณ",
                  onViewAll: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) =>
                              CaseStatusAllPage(caseList: caseList)))),
              // const SizedBox(height: 12),
              _buildCaseStatusList(),
              const SizedBox(height: 24),
            ],
      
            // Law Categories (user only)
            if (userType == 'user') ...[
              _sectionHeader("ประเด็นหัวข้อกฎหมาย",
                  onViewAll: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => LawTypeAllPage()))),
              const SizedBox(height: 14),
              _buildLawCategories(),
              const SizedBox(height: 24),
            ],
      
            // Appointments (lawyer only)
            if (userType == 'lawyer') ...[
              _sectionHeader("นัดหมายที่กำลังจะมาถึง",
                  onViewAll: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => MenuPage(pageIndex: 2)))),
              const SizedBox(height: 12),
              _buildAppointmentList(),
              const SizedBox(height: 24),
            ],
      
            // Lawyer Online (user only)
            if (userType != 'lawyer') ...[
              _sectionHeader("หมอความออนไลน์",
                  onViewAll: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => LawyerOnlineList()))),
              const SizedBox(height: 12),
              _buildLawyerOnline(),
            ],
      
            const SizedBox()
          ],
        ),
      ),
    );
  }

  // ─── Section Header ───────────────────────────────────────────────
  Widget _sectionHeader(String title, {VoidCallback? onViewAll}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title,
              style: GoogleFonts.prompt(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: _kText,
              )),
          if (onViewAll != null)
            GestureDetector(
              onTap: onViewAll,
              child: Row(children: [
                Text("ดูทั้งหมด",
                    style: GoogleFonts.prompt(
                      fontSize: 12,
                      color: _kAccent,
                      fontWeight: FontWeight.w600,
                    )),
                const SizedBox(width: 2),
                const Icon(Icons.arrow_forward_ios_rounded,
                    size: 10, color: _kAccent),
              ]),
            ),
        ],
      ),
    );
  }

  // ─── Action Card ─────────────────────────────────────────────────
  Widget _actionCard({
    required String title,
    required String subtitle,
    IconData? icon,
    String iconAssets = "",
    Color? titleColor = Colors.white,
    Color? subTitleColor = Colors.white,
    Color? iconColor = Colors.white,
    required List<Color> gradientColors,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
              colors: gradientColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(18),
          // boxShadow: [
          //   BoxShadow(
          //     color: Color.fromARGB(255, 157, 183, 211).withOpacity(0.2),
          //     blurRadius: 16,
          //     offset: const Offset(0, 6),
          //   )
          // ],
          boxShadow: [
            BoxShadow(
              color: _kAccent.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            )
          ],
          border: Border.all(
            color: const Color(0xFFE2EAF8),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                // color: Colors.white.withOpacity(0.18),
                borderRadius: BorderRadius.circular(12),
              ),
              // ignore: unnecessary_null_comparison
              child: icon != null
                  ? Icon(icon, color: iconColor, size: 22)
                  : Image.asset(
                      iconAssets,
                      width: 18,
                      height: 18,
                      color: iconColor,
                    ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.prompt(
                    color: titleColor,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.prompt(
                    color: subTitleColor,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─── Banner ───────────────────────────────────────────────────────
  Widget _buildBannerSection(Size size) {
    if (mockBannerList.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15),
        child: Container(
          height: 160,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: Colors.grey.shade200,
          ),
          child:
              const Center(child: CircularProgressIndicator(color: _kAccent)),
        ),
      );
    }
    return Column(children: [
      Container(
        padding: EdgeInsets.symmetric(horizontal: 0),
        height: 140,
        child: CarouselSlider(
          options: CarouselOptions(
            viewportFraction: 0.9,
            aspectRatio: 3,
            enlargeCenterPage: true,
            enlargeFactor: 0.32,
            autoPlay: true,
            autoPlayInterval: const Duration(seconds: 4),
            onPageChanged: (index, _) => setState(() => _currentBanner = index),
          ),
          items: mockBannerList.map((item) {
            return GestureDetector(
                onTap: () => _onBannerTap(item),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    image: DecorationImage(
                      image: NetworkImage(item['imageUrl']),
                      fit: BoxFit.cover,
                      colorFilter: ColorFilter.mode(
                        const Color.fromARGB(133, 55, 55, 55)
                            .withOpacity(0.5), // ความจางของสี
                        BlendMode.srcATop, // โหมดการผสมสี
                      ),
                    ),
                  ),
                  child: CachedNetworkImage(
                    imageUrl: item['imageUrl'],
                    fit: BoxFit.contain,
                    width: double.infinity,
                    height: double.infinity,
                  ),
                ));
          }).toList(),
        ),
      ),
      // const SizedBox(height: 10),
      // dots
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(mockBannerList.length, (i) {
          final active = i == _currentBanner;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: active ? 18 : 6,
            height: 6,
            decoration: BoxDecoration(
              color: active ? _kAccent : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(3),
            ),
          );
        }),
      ),
    ]);
  }

  void _onBannerTap(dynamic item) {
    if (item['action'] == 'out') {
      launchInWebViewWithJavaScript(item['path']);
    } else if (item['action'] == 'in') {
      Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CarouselForm(
                code: item['code'],
                model: item,
                url: mainBannerApi,
                urlGallery: bannerGalleryApi),
          ));
    } else if ((item['action'] as String).toUpperCase() == 'P') {
      Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ComingSoonPage(
              title: "Comming Soon",
              lottieUrl:
                  "https://assets7.lottiefiles.com/packages/lf20_kkflmtur.json",
            ),
          ));
    }
  }

  // ─── Case Status List ─────────────────────────────────────────────
  Widget _buildCaseStatusList() {
    return SizedBox(
      height: 130,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(18, 15, 18, 15),
        itemCount: caseList.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, i) => _caseStatusItem(caseList[i]),
      ),
    );
  }

  Widget _caseStatusItem(Map model) {
    final status = model['status']?.toString() ?? '1';
    final s = _statusStyle(status);
    final lawyerModel = model['lawyerModel'] as Map?;
    final lawyerName = lawyerModel?['name'] ?? '';
    final lawyerImage = lawyerModel?['imageUrl'] ?? '';
    final category = model['category'] ?? '';
    final statusText = model['statusText'] ?? '';

    return GestureDetector(
      onTap: () => _goToConsultStatus(model),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.72,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: _kCard,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.07),
              blurRadius: 12,
              offset: const Offset(0, 3),
            )
          ],
        ),
        child: Row(children: [
          // left colored bar
          Container(
            width: 4,
            height: double.infinity,
            decoration: BoxDecoration(
                color: s.color, borderRadius: BorderRadius.circular(4)),
          ),
          const SizedBox(width: 12),
          // avatar
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.asset(lawyerImage,
                width: 48, height: 48, fit: BoxFit.cover),
          ),
          const SizedBox(width: 12),
          // info
          Expanded(
              child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(lawyerName,
                  style: GoogleFonts.prompt(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _kText,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
              const SizedBox(height: 2),
              Text(category,
                  style: GoogleFonts.prompt(
                    fontSize: 11,
                    color: _kSub,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: s.bg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(s.icon, size: 11, color: s.color),
                  const SizedBox(width: 4),
                  Text(statusText,
                      style: GoogleFonts.prompt(
                        fontSize: 10,
                        color: s.color,
                        fontWeight: FontWeight.w600,
                      )),
                ]),
              ),
            ],
          )),
          Icon(Icons.chevron_right_rounded,
              size: 18, color: Colors.grey.shade400),
        ]),
      ),
    );
  }

  // ─── Law Categories Grid ──────────────────────────────────────────
  Widget _buildLawCategories() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Row(
        children: _lawCategories
            .map((cat) => Expanded(
                  child: _lawCategoryItem(
                    title: cat['title']!,
                    icon: cat['icon']!,
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                                LawyerOnlineList(topic: cat['topic']))),
                  ),
                ))
            .toList(),
      ),
    );
  }

  Widget _lawCategoryItem({
    required String title,
    required String icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _kCard,
              // borderRadius: BorderRadius.circular(100),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: _kAccent.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                )
              ],
              border: Border.all(
                color: const Color(0xFFE2EAF8),
              ),
            ),
            child: Image.asset(
              icon,
              height: 34,
              fit: BoxFit.contain,
              color: _kPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(title,
              style: GoogleFonts.prompt(
                fontSize: 10.5,
                color: _kText,
                height: 1.4,
              ),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }

  // ─── Lawyer Online ────────────────────────────────────────────────
  Widget _buildLawyerOnline() {
    return Container(
      height: 210,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(18, 4, 18, 15),
        itemCount: lawyerOnlineList.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, i) => _lawyerCard(
          lawyerOnlineList[i],
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => LawyerOnlineDetails(
                code: lawyerOnlineList[i]['code'],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _lawyerCard(Map model, {VoidCallback? onTap}) {
    final isFree = (model['cost'] ?? '') == 'Free';
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 148,
        decoration: BoxDecoration(
          color: _kCard,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 14,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(
          children: [
            // image area with gradient overlay
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(18)),
              child: Stack(children: [
                Image.asset(model['imageUrl'] ?? '',
                    height: 100, width: double.infinity, fit: BoxFit.cover),
                Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.5)
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    )),
                Positioned(
                    bottom: 6,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isFree ? const Color(0xFF059669) : _kPrimary,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        isFree
                            ? 'ฟรี'
                            : '฿${model['cost']}${model['costUnit']}',
                        style: GoogleFonts.prompt(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    )),
              ]),
            ),
            // info
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(model['name'] ?? '',
                        style: GoogleFonts.prompt(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: _kText,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Row(children: [
                      const Icon(Icons.star_rounded, size: 13, color: _kGold),
                      const SizedBox(width: 3),
                      Text('${model['scroll'] ?? 0}',
                          style: GoogleFonts.prompt(
                            fontSize: 11,
                            color: _kText,
                            fontWeight: FontWeight.w600,
                          )),
                      const SizedBox(width: 6),
                      const Icon(Icons.work_outline_rounded,
                          size: 11, color: _kSub),
                      const SizedBox(width: 3),
                      Text(model['experience'] ?? '',
                          style: GoogleFonts.prompt(
                            fontSize: 10,
                            color: _kSub,
                          )),
                    ]),
                    const SizedBox(height: 6),
                    Text(
                      (model['skills'] as List?)?.isNotEmpty == true
                          ? (model['skills'] as List).first
                          : '',
                      style: GoogleFonts.prompt(
                        fontSize: 9.5,
                        color: _kAccent,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ]),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Appointment List (lawyer) ────────────────────────────────────
  Widget _buildAppointmentList() {
    return SizedBox(
      height: 90,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(18, 0, 18, 4),
        itemCount: appointmentList.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, i) => _appointmentCard(appointmentList[i],
            onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) =>
                        AppointmentDetailsLawyer(model: appointmentList[i])))),
      ),
    );
  }

  Widget _appointmentCard(Map model, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: MediaQuery.of(context).size.width - 60,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF0B3D91), Color(0xFF1E88E5)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: _kPrimary.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Row(children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child:
                const Icon(Icons.event_rounded, color: Colors.white, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
              child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(model['title'] ?? '',
                  style: GoogleFonts.prompt(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
              const SizedBox(height: 6),
              Row(children: [
                const Icon(Icons.calendar_today_rounded,
                    size: 11, color: Colors.white70),
                const SizedBox(width: 4),
                Text(model['appointmentDate'] ?? '',
                    style: GoogleFonts.prompt(
                      fontSize: 10.5,
                      color: Colors.white70,
                    )),
                const SizedBox(width: 10),
                const Icon(Icons.access_time_rounded,
                    size: 11, color: Colors.white70),
                const SizedBox(width: 4),
                Text(model['appointmentTime'] ?? '',
                    style: GoogleFonts.prompt(
                      fontSize: 10.5,
                      color: Colors.white70,
                    )),
              ]),
            ],
          )),
          const Icon(Icons.chevron_right_rounded,
              color: Colors.white54, size: 18),
        ]),
      ),
    );
  }
}

// ─── Helper class ─────────────────────────────────────────────────
class _StatusStyle {
  final Color color;
  final Color bg;
  final IconData icon;
  const _StatusStyle(this.color, this.bg, this.icon);
}

class AppBarOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // ── rings top-right ──────────────────────────────────────
    final ringPaint = Paint()..style = PaintingStyle.stroke;
    final c = Offset(size.width * 0.90, size.height * 0.16);
    for (final r in [140.0, 100.0, 60.0]) {
      canvas.drawCircle(
          c,
          r,
          ringPaint
            ..color = Colors.white.withOpacity(0.09)
            ..strokeWidth = 0.8);
    }
    canvas.drawCircle(c, 24, Paint()..color = Colors.white.withOpacity(0.05));

    // ── rings bottom-left (gold) ─────────────────────────────
    const gold = Color(0xFFF5A623);
    final cg = Offset(size.width * 0.10, size.height * 0.94);
    for (final r in [80.0, 46.0]) {
      canvas.drawCircle(
          cg,
          r,
          ringPaint
            ..color = gold.withOpacity(0.13)
            ..strokeWidth = 0.8);
    }
    canvas.drawCircle(cg, 18, Paint()..color = gold.withOpacity(0.06));

    // ── diagonal lines ───────────────────────────────────────
    final diagPaint = Paint()
      ..color = Colors.white.withOpacity(0.04)
      ..strokeWidth = 0.7;
    for (int i = 0; i < 6; i++) {
      canvas.drawLine(
        Offset(i * 80.0, size.height),
        Offset(i * 80.0 + size.height, 0),
        diagPaint,
      );
    }

    // ── horizontal rules ─────────────────────────────────────
    final hPaint = Paint()
      ..color = Colors.white.withOpacity(0.03)
      ..strokeWidth = 0.6;
    for (double y = 64; y < size.height; y += 64) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), hPaint);
    }

    // ── dot grid top-left ────────────────────────────────────
    final dotW = Paint()..color = Colors.white.withOpacity(0.13);
    for (int r = 0; r < 3; r++) {
      for (int col = 0; col < 4; col++) {
        canvas.drawCircle(Offset(44 + col * 16.0, 38 + r * 16.0), 1.8, dotW);
      }
    }

    // ── dot grid bottom-right (gold) ─────────────────────────
    final dotG = Paint()..color = gold.withOpacity(0.18);
    for (int r = 0; r < 2; r++) {
      for (int col = 0; col < 4; col++) {
        canvas.drawCircle(
          Offset(size.width - 92 + col * 16.0, size.height - 62 + r * 16.0),
          1.8,
          dotG,
        );
      }
    }

    // ── accent lines ─────────────────────────────────────────
    canvas.drawLine(
      Offset(30, size.height - 24),
      Offset(200, size.height - 24),
      Paint()
        ..color = gold.withOpacity(0.22)
        ..strokeWidth = 0.8,
    );
    canvas.drawLine(
      Offset(30, size.height - 24),
      Offset(80, size.height - 24),
      Paint()
        ..color = gold.withOpacity(0.55)
        ..strokeWidth = 1.4,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
