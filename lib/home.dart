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
import 'package:LawyerOnline/consultation-schedule.dart';
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
  List<dynamic> mockBannerList = [
    {"code": "0", "imageUrl": "assets/images/banner1.png"},
    {"code": "1", "imageUrl": "assets/images/banner2.png"},
  ];
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
      "appointmentDate": "28/04/2026",
      "appointmentTime": "11.00 - 14.00",
      "title": "ขอฟ้องร้องมรดกผู้ปกครอง",
      "details": "ต้องการฟ้องร้องพี่น้องที่โกงเงินมรดก",
      "paymentStatus": "1",
    },
    {
      "code": "2",
      "clientName": "อนงค์ ดำเนิน",
      "caseType": "คดีมรดกทุกประเภท",
      "subCaseType": "ฟ้องร้องมรดก",
      "appointmentDate": "28/04/2026",
      "appointmentTime": "11.00 - 14.00",
      "title": "ขอฟ้องร้องมรดกผู้ปกครอง",
      "details": "ต้องการฟ้องร้องพี่น้องที่โกงเงินมรดก",
      "paymentStatus": "1",
    },
    {
      "code": "3",
      "clientName": "อนงค์ ดำเนิน",
      "caseType": "คดีมรดกทุกประเภท",
      "subCaseType": "ฟ้องร้องมรดก",
      "appointmentDate": "28/04/2026",
      "appointmentTime": "11.00 - 14.00",
      "title": "ขอฟ้องร้องมรดกผู้ปกครอง",
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

  List<Map<String, dynamic>> _getLawyerJobsMockData() {
    return [
      {
        'id': 'REQ-2026-001',
        'clientName': 'สมชาย ใจดี',
        'clientAvatar': 'ส',
        'clientColor': 0xFF0262EC,
        'topic': 'ครอบครัวและมรดก',
        'subTopic': 'ฟ้องหย่า / แบ่งสินสมรส',
        'detail':
            'ต้องการปรึกษาเรื่องการฟ้องหย่าและการแบ่งทรัพย์สินสมรส มีบ้านและที่ดิน 2 แปลง ต้องการคำแนะนำเบื้องต้น',
        'date': '28 มี.ค. 2569',
        'time': '10:00 - 11:00',
        'status': 'pending',
        'requestedAt': '2 ชั่วโมงที่แล้ว',
        'type': 'video',
        'budget': 'ฟรี',
      },
      {
        'id': 'REQ-2026-003',
        'clientName': 'ประสิทธิ์ มั่งมี',
        'clientAvatar': 'ป',
        'clientColor': 0xFF059669,
        'topic': 'ธุรกิจและบริษัท',
        'subTopic': 'ตรวจร่างสัญญา',
        'detail':
            'ต้องการให้ตรวจสอบสัญญาซื้อขายกิจการ มูลค่า 5 ล้านบาท กังวลเรื่องเงื่อนไขการรับประกัน',
        'date': '02 เม.ย. 2569',
        'time': '09:00 - 10:00',
        'status': 'accepted',
        'requestedAt': '1 วันที่แล้ว',
        'type': 'video',
        'budget': '1,000 บาท',
      },
      {
        'id': 'REQ-2026-004',
        'clientName': 'นงลักษณ์ สุขสม',
        'clientAvatar': 'น',
        'clientColor': 0xFF7C3AED,
        'topic': 'ทรัพย์สินและที่ดิน',
        'subTopic': 'เช่าบ้าน / ขับไล่ผู้เช่า',
        'detail':
            'ผู้เช่าค้างค่าเช่า 3 เดือน ไม่ยอมออก ต้องการดำเนินการทางกฎหมาย',
        'date': '15 มี.ค. 2569',
        'time': '11:00 - 12:00',
        'status': 'done',
        'requestedAt': '2 สัปดาห์ที่แล้ว',
        'type': 'video',
        'budget': '800 บาท',
      },
      {
        'id': 'REQ-2026-005',
        'clientName': 'อนันต์ ชัยชนะ',
        'clientAvatar': 'อ',
        'clientColor': 0xFFD97706,
        'topic': 'อาญาและอาชญากรรม',
        'subTopic': 'หมิ่นประมาท',
        'detail':
            'ถูกโพสต์หมิ่นประมาทบน Facebook ทำให้เสียชื่อเสียง ต้องการฟ้องร้อง',
        'date': '',
        'time': '',
        'status': 'rejected',
        'requestedAt': '3 วันที่แล้ว',
        'type': 'video',
        'budget': 'ฟรี',
      },
    ];
  }

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
    // final value =
    //     await postDio('${mainBannerApi}read', {'skip': 0, 'limit': 10});
    // setState(() {
    //   mockBannerList = value;
    // });
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
              // physics: const ClampingScrollPhysics(),
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
                          // Text(
                          //   "สวัสดี,",
                          //   style: GoogleFonts.prompt(
                          //     color: Colors.black.withOpacity(0.5),
                          //     fontSize: 12,
                          //   ),
                          // ),
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
                            "assets/icons/bell-2.png",
                            width: 25,
                            height: 25,
                            color: const Color(0xFF1565C0),
                          ),
                          Positioned(
                            top: 8,
                            right: 9,
                            child: Container(
                              width: 9,
                              height: 9,
                              decoration: const BoxDecoration(
                                color: Color.fromARGB(255, 247, 12, 12),
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
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _actionCard(
                          title: "รับเคสด่วน",
                          subtitle: "ลูกความต้องการคำปรึกษาด่วน",
                          icon: Icons.work_rounded,
                          gradientColors: [
                            const Color(0xFF1565C0),
                            const Color(0xFF2F80ED)
                          ],
                          onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => LawyerJobListPage())),
                        ),
                        const SizedBox(height: 14),
                        _actionCard(
                          title: "ตั้งค่าวันที่สามารถปรึกษา",
                          subtitle: "กำหนดวันที่สามารถจองขอคำปรึกษาได้",
                          icon: Icons.date_range_rounded,
                          gradientColors: [_kCard, _kCard],
                          titleColor: const Color(0xFF1565C0),
                          subTitleColor: const Color(0xFF1565C0),
                          iconColor: const Color(0xFF1565C0),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ConsultationSchedule(),
                            ),
                          ),
                        ),
                      ],
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
              _sectionHeader("คำขอจากลูกความ",
                  onViewAll: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => LawyerJobListPage()))),
              const SizedBox(height: 12),
              _buildJobRequestList(),
              const SizedBox(height: 16),
              _sectionHeader("รายการนัดหมาย (${appointmentList.length})",
                  onViewAll: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => MenuPage(pageIndex: 2)))),
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
                borderRadius: BorderRadius.circular(12),
              ),
              child: icon != null
                  ? Icon(icon, color: iconColor, size: 40)
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

  Widget _actionCardBorder({
    required String title,
    required String subtitle,
    IconData? icon,
    String iconAssets = "",
    Color? titleColor = Colors.white,
    Color? subTitleColor = Colors.white,
    Color? iconColor = Colors.white,
    required List<Color> gradientColors,
    Color borderColor = const Color(0xFF0262EC),
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
          boxShadow: [
            BoxShadow(
              color: _kAccent.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            )
          ],
          border: Border.all(
            color: borderColor,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
              ),
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
                      image: AssetImage(item['imageUrl']),
                      fit: BoxFit.cover,
                      colorFilter: ColorFilter.mode(
                        const Color.fromARGB(133, 55, 55, 55)
                            .withOpacity(0.5), // ความจางของสี
                        BlendMode.srcATop, // โหมดการผสมสี
                      ),
                    ),
                  ),
                  child: Image.asset(
                    item['imageUrl'],
                    fit: BoxFit.contain,
                    width: double.infinity,
                    height: double.infinity,
                  ),
                  // child: CachedNetworkImage(
                  //   imageUrl: item['imageUrl'],
                  //   fit: BoxFit.contain,
                  //   width: double.infinity,
                  //   height: double.infinity,
                  // ),
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
  // Widget _buildAppointmentList() {
  //   return SizedBox(
  //     height: 350,
  //     child: ListView.separated(
  //       scrollDirection: Axis.vertical,
  //       padding: const EdgeInsets.fromLTRB(18, 0, 18, 4),
  //       itemCount: appointmentList.length,
  //       separatorBuilder: (_, __) => const SizedBox(height: 10),
  //       itemBuilder: (_, i) => _appointmentCard(appointmentList[i],
  //           onTap: () => Navigator.push(
  //               context,
  //               MaterialPageRoute(
  //                   builder: (_) =>

  //                       AppointmentDetailsLawyer(model: appointmentList[i])))),
  //     ),
  //   );
  // }

  // แบบเดิมที่ยังไม่แยก job กับ appointment
  // Widget _buildAppointmentList() {
  //   final lawyerJobs = _getLawyerJobsMockData();
  //   final acceptedJobs =
  //       lawyerJobs.where((j) => j['status'] == 'accepted').toList();
  //   final pendingJobs =
  //       lawyerJobs.where((j) => j['status'] == 'pending').toList();
  //   final combinedList = [...acceptedJobs, ...pendingJobs, ...appointmentList];

  //   return Padding(
  //     padding: const EdgeInsets.fromLTRB(18, 0, 18, 4),
  //     child: Column(
  //       children: [
  //         for (int i = 0; i < combinedList.length; i++) ...[
  //           if (i > 0) const SizedBox(height: 10),
  //           combinedList[i].containsKey('status')
  //               ? _buildUrgentJobCard(combinedList[i])
  //               : _appointmentCard(
  //                   combinedList[i],
  //                   onTap: () => Navigator.push(
  //                     context,
  //                     MaterialPageRoute(
  //                       builder: (_) => AppointmentDetailsLawyer(
  //                         model: combinedList[i],
  //                       ),
  //                     ),
  //                   ),
  //                 ),
  //         ]
  //       ],
  //     ),
  //   );
  // }
  // ── 1. Job request cards ──────────────────────────────────────────
  Widget _buildJobRequestList() {
    final lawyerJobs = _getLawyerJobsMockData();
    final acceptedJobs =
        lawyerJobs.where((j) => j['status'] == 'accepted').toList();
    final pendingJobs =
        lawyerJobs.where((j) => j['status'] == 'pending').toList();
    final jobList = [...acceptedJobs, ...pendingJobs];

    if (jobList.isEmpty) return const SizedBox();

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 0),
      child: Column(
        children: [
          for (int i = 0; i < jobList.length; i++) ...[
            if (i > 0) const SizedBox(height: 10),
            _buildUrgentJobCard(jobList[i]),
          ],
        ],
      ),
    );
  }

// ── 2. Appointment cards (horizontal) ────────────────────────────
  Widget _buildAppointmentList() {
    if (appointmentList.isEmpty) return const SizedBox();

    return SizedBox(
      height: 160,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(18, 4, 18, 0),
        itemCount: appointmentList.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (_, i) => _appointmentCard(
          appointmentList[i],
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  AppointmentDetailsLawyer(model: appointmentList[i]),
            ),
          ),
        ),
      ),
    );
  }

  Widget _appointmentCard(Map model, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: (MediaQuery.of(context).size.width - 18 * 2 - 14) / 2,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1565C0), Color(0xFF1E88E5)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: _kAccent.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // ── icon ───────────────────────────────────
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.event_rounded,
                  color: Colors.white, size: 20),
            ),

            // ── subCaseType + title ─────────────────
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  model['subCaseType'] ?? '',
                  style: GoogleFonts.prompt(
                    color: Colors.white70,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  model['title'] ?? '',
                  style: GoogleFonts.prompt(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),

            // ── วัน + เวลา ──────────────────────────
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  const Icon(Icons.calendar_today_rounded,
                      size: 10, color: Colors.white70),
                  const SizedBox(width: 4),
                  Text(
                    model['appointmentDate'] ?? '',
                    style:
                        GoogleFonts.prompt(fontSize: 10, color: Colors.white70),
                  ),
                ]),
                const SizedBox(height: 2),
                Row(children: [
                  const Icon(Icons.access_time_rounded,
                      size: 10, color: Colors.white70),
                  const SizedBox(width: 4),
                  Text(
                    model['appointmentTime'] ?? '',
                    style:
                        GoogleFonts.prompt(fontSize: 12, color: const Color.fromARGB(179, 255, 255, 255)),
                  ),
                ]),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUrgentJobCard(Map<String, dynamic> job) {
    final status = job['status'];
    final barColors = _getStatusBarColors(status);
    final badge = _getStatusBadge(status);
    final isAccepted = status == 'accepted';

    return GestureDetector(
      onTap: () {
        final isPending = job['status'] == 'pending';
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => LawyerJobDetailPage(
              job: job,
              onAccept: isPending ? () => Navigator.pop(context) : null,
              onReject: isPending ? () => Navigator.pop(context) : null,
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: IntrinsicHeight(
          child: Row(
            children: [
              // แถบสีด้านซ้าย
              Container(
                width: 6,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: barColors,
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    bottomLeft: Radius.circular(16),
                  ),
                ),
              ),

              // เนื้อหาการ์ด
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header - Avatar + ชื่อ + เวลา + Badge
                      Row(
                        children: [
                          // Avatar
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: Color(job['clientColor']),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(
                                job['clientAvatar'],
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  job['clientName'],
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF1A2340),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    Icon(Icons.access_time,
                                        size: 12, color: Colors.grey[400]),
                                    const SizedBox(width: 4),
                                    Text(
                                      job['requestedAt'],
                                      style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey[500]),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          // Badge สถานะ
                          badge,
                        ],
                      ),

                      const SizedBox(height: 14),

                      // Topic badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0262EC).withOpacity(0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          job['topic'],
                          style: const TextStyle(
                            color: Color(0xFF0262EC),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),

                      // Sub-topic (หัวข้อคดี)
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              job['subTopic'],
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1A2340),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0262EC).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'ดูรายละเอียด',
                                  style: TextStyle(
                                    color: Color(0xFF0262EC),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                SizedBox(width: 4),
                                Icon(Icons.arrow_forward_ios,
                                    size: 10, color: Color(0xFF0262EC)),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      // แสดงข้อมูลนัดหมายสำหรับสถานะ "รับแล้ว"
                      if (isAccepted &&
                          job['date'] != null &&
                          job['date'].isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0262EC).withOpacity(0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFF0262EC).withOpacity(0.2),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color:
                                      const Color(0xFF0262EC).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.calendar_today,
                                  size: 16,
                                  color: Color(0xFF0262EC),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${job['date']} • ${job['time']}',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF1A2340),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'อยู่ในช่วงเวลาให้คำปรึกษา',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[800],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Color> _getStatusBarColors(String status) {
    switch (status) {
      case 'accepted':
        return [const Color(0xFF00AA17), const Color(0xFF00AA17)];
      case 'pending':
        return [const Color(0xFFD97706), const Color(0xFFF59E0B)];
      default:
        return [Colors.grey, Colors.grey.shade400];
    }
  }

  Widget _getStatusBadge(String status) {
    final config = _getStatusBadgeConfig(status);
    if (config == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: config['colors']),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: config['shadowColor'].withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(config['icon'], size: 14, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            config['label'],
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic>? _getStatusBadgeConfig(String status) {
    switch (status) {
      case 'accepted':
        return {
          'colors': [const Color(0xFF0262EC), const Color(0xFF0099FF)],
          'icon': Icons.check_circle,
          'label': 'รับแล้ว',
          'shadowColor': const Color(0xFF0262EC),
        };
      case 'pending':
        return {
          'colors': [const Color(0xFFD97706), const Color(0xFFF59E0B)],
          'icon': Icons.hourglass_top,
          'label': 'รอตอบรับ',
          'shadowColor': const Color(0xFFD97706),
        };
      default:
        return null;
    }
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
