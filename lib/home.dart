import 'package:LawyerOnline/widgets/home/home_app_bar.dart';
import 'package:LawyerOnline/widgets/home/home_banner_section.dart';
import 'package:LawyerOnline/widgets/home/home_lawyer_section.dart';
import 'package:LawyerOnline/widgets/home/home_user_section.dart';
import 'package:LawyerOnline/widgets/home/home_action_cards.dart';
import 'dart:async';
// import 'package:LawyerOnline/appointment-details-lawyer.dart';
// import 'package:LawyerOnline/booking/topic-page.dart';
// import 'package:LawyerOnline/carousel_form.dart';
// import 'package:LawyerOnline/case-status-all.dart';
// import 'package:LawyerOnline/component/appbar.dart';
// import 'package:LawyerOnline/component/comming-soon.dart';
// import 'package:LawyerOnline/component/link_url_in.dart';
// import 'package:LawyerOnline/consult/consult.dart';
// import 'package:LawyerOnline/consult/consult_status.dart';
// import 'package:LawyerOnline/law_type_all_page.dart';
// import 'package:LawyerOnline/lawyer-job-list.dart';
// import 'package:LawyerOnline/lawyer-online-details.dart';
// import 'package:LawyerOnline/lawyer-online-list.dart';
// import 'package:LawyerOnline/consultation-schedule.dart';
// import 'package:LawyerOnline/menu.dart';
// import 'package:LawyerOnline/notification.dart';
// import 'package:LawyerOnline/shared/api_provider.dart';
// import 'package:cached_network_image/cached_network_image.dart';
// import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:LawyerOnline/models/lawyer/lawyer_jobs_store.dart';
import 'package:LawyerOnline/models/lawyer/appointment_store.dart';
import 'package:LawyerOnline/shared/responsive/res_layout.dart';
import 'package:LawyerOnline/shared/responsive/responsive_values.dart';
import 'package:LawyerOnline/shared/responsive/app_layout.dart';
import 'package:LawyerOnline/models/lawyer/lawyer_profile_store.dart';
import 'package:easy_localization/easy_localization.dart';

// ใน build
// final isUrgentCase = LawyerProfileStore.instance.isUrgentCaseEnabled;

// ─── Palette & theme constants ───────────────────────────────────────
const _kPrimary = Color(0xFF0262EC); // deep navy
const _kAccent = Color(0xFF2F80ED); // bright blue
const _kGold = Color(0xFFF5A623); // justice-gold accent
const _kSurface = Color(0xFFF4F6FB); // cool light background
const _kCard = Colors.white;
const _kText = Color(0xFF0D1B2A);
const _kSub = Color(0xFF6B7A99);

class HomePage extends StatefulWidget {
  const HomePage({Key? key, this.userType, this.onProfileTap});
  final String? userType;
  final VoidCallback? onProfileTap;

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

  // bool _isUrgentCaseEnabled = false; // สถานะรับเคสด่วนของทนาย
  Timer? _urgentCaseTimer; // timer คอย monitor นัดหมาย

  List<dynamic> lawyerOnlineList = [
    // ── เดิม 5 คน ──────────────────────────────────────────────────────────────
    {
      "code": "0",
      "name": "ศักดิ์สิทธิ์ พิพากษ์",
      "title": "ทนายความอาวุโส",
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
      "title": "ทนายความอาวุโส",
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
      "title": "ทนายความอาวุโส",
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
      "title": "ทนายความอาวุโส",
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
      "title": "ทนายความอาวุโส",
      "scroll": 4.9,
      "cost": "1,000",
      "costUnit": "/hr",
      "imageUrl": "assets/images/lawyer-avatar-5.png",
      "experience": "20+ ปี",
      "price": 500,
      "skills": ["คดีออนไลน์และเทคโนโลยี", "อื่นๆและระหว่างประเทศ"],
    },

    // ── เพิ่มใหม่ 25 คน ────────────────────────────────────────────────────────
    {
      "code": "5",
      "name": "วรรณา จิตต์ดี",
      "title": "ทนายความด้านครอบครัว",
      "scroll": 4.7,
      "cost": "300",
      "costUnit": "/hr",
      "imageUrl": "assets/images/lawyer-avatar-8.png",
      "experience": "15+ ปี",
      "price": 300,
      "skills": ["ครอบครัวและมรดก", "หย่าร้างและสิทธิ์เลี้ยงดูบุตร"],
    },
    {
      "code": "6",
      "name": "กิตติพงศ์ นิลพัท",
      "title": "ทนายความด้านอสังหาริมทรัพย์",
      "scroll": 4.5,
      "cost": "400",
      "costUnit": "/hr",
      "imageUrl": "assets/images/lawyer-avatar-7.png",
      "experience": "13+ ปี",
      "price": 400,
      "skills": ["ทรัพย์สินและที่ดิน", "สัญญาซื้อขายอสังหาริมทรัพย์"],
    },
    {
      "code": "7",
      "name": "ภาณุพงศ์ ศรีสวัสดิ์",
      "title": "ทนายความด้านแรงงาน",
      "scroll": 4.6,
      "cost": "250",
      "costUnit": "/hr",
      "imageUrl": "assets/images/lawyer-avatar-8.png",
      "experience": "9+ ปี",
      "price": 250,
      "skills": ["แรงงานและการจ้างงาน", "ค่าชดเชยและสวัสดิการ"],
    },
    {
      "code": "8",
      "name": "สุนทรี แก้วมณี",
      "title": "ทนายความด้านแพ่ง",
      "scroll": 4.3,
      "cost": "350",
      "costUnit": "/hr",
      "imageUrl": "assets/images/lawyer-avatar-13.png",
      "experience": "14+ ปี",
      "price": 350,
      "skills": ["คดีแพ่ง", "สัญญาและข้อพิพาท"],
    },
    {
      "code": "9",
      "name": "อนันต์ พรหมพิทักษ์",
      "title": "ทนายความด้านอาชญากรรมไซเบอร์",
      "scroll": 4.8,
      "cost": "600",
      "costUnit": "/hr",
      "imageUrl": "assets/images/lawyer-avatar-10.png",
      "experience": "8+ ปี",
      "price": 600,
      "skills": ["คดีออนไลน์และเทคโนโลยี", "อาญาและอาชญากรรม"],
    },
    {
      "code": "10",
      "name": "ปิยะนุช รุ่งเรือง",
      "title": "ทนายความด้านธุรกิจ",
      "scroll": 4.4,
      "cost": "500",
      "costUnit": "/hr",
      "imageUrl": "assets/images/lawyer-avatar-14.png",
      "experience": "16+ ปี",
      "price": 500,
      "skills": ["ธุรกิจและบริษัท", "สัญญาและข้อพิพาท"],
    },
    {
      "code": "11",
      "name": "ชาติชาย วิริยะ",
      "title": "ทนายความอิสระ",
      "scroll": 3.8,
      "cost": "Free",
      "costUnit": "/hr",
      "imageUrl": "assets/images/lawyer-avatar-12.png",
      "experience": "5+ ปี",
      "price": 0,
      "skills": ["อาญาและอาชญากรรม", "ฟ้องศาล เรียกค่าเสียหาย"],
    },
    {
      "code": "12",
      "name": "มณีรัตน์ สุวรรณโชติ",
      "title": "ทนายความด้านภาษี",
      "scroll": 4.2,
      "cost": "450",
      "costUnit": "/hr",
      "imageUrl": "assets/images/lawyer-avatar-15.png",
      "experience": "11+ ปี",
      "price": 450,
      "skills": ["ภาษีและการเงิน", "ธุรกิจและบริษัท"],
    },
    {
      "code": "13",
      "name": "วิทยา ธรรมสาร",
      "title": "ทนายความด้านสิ่งแวดล้อม",
      "scroll": 4.0,
      "cost": "350",
      "costUnit": "/hr",
      "imageUrl": "assets/images/lawyer-avatar-14.png",
      "experience": "7+ ปี",
      "price": 350,
      "skills": ["สิ่งแวดล้อมและที่ดิน", "ทรัพย์สินและที่ดิน"],
    },
    {
      "code": "14",
      "name": "ณัฐพล อินทรวิชัย",
      "title": "ทนายความด้านทรัพย์สินทางปัญญา",
      "scroll": 4.7,
      "cost": "700",
      "costUnit": "/hr",
      "imageUrl": "assets/images/lawyer-avatar-15.png",
      "experience": "12+ ปี",
      "price": 700,
      "skills": ["ทรัพย์สินทางปัญญา", "คดีออนไลน์และเทคโนโลยี"],
    },
  ];

  List<dynamic> newLawyerOnlineList = [
    {
      "code": "0",
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
      "code": "1",
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
    {
      "code": "2",
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
      "code": "3",
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
      "code": "4",
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
  ];

  // ── ดึงนัดหมายจาก AppointmentStore แทน hardcode ────────────
  List<dynamic> get appointmentList => AppointmentStore.instance.list;

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

// ฟังก์ชันตรวจสอบนัดหมายล่วงหน้า 1 ชั่วโมง — delegate ไป AppointmentStore
  bool _hasConflictingAppointment() =>
      AppointmentStore.instance.hasConflictingAppointment();

// ฟังก์ชันเมื่อมีการกดเปิด-ปิดสวิตช์
  void _startUrgentCaseTimer() {
    _urgentCaseTimer?.cancel();
    _urgentCaseTimer = Timer.periodic(const Duration(minutes: 1), (_) async {
      if (!mounted) return;
      if (LawyerProfileStore.instance.isUrgentCaseEnabled &&
          _hasConflictingAppointment()) {
        // setUrgentCase เรียก notifyListeners() เอง ไม่ต้อง setState
        await LawyerProfileStore.instance.setUrgentCase(false);

        // แจ้งเตือน
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                const Icon(Icons.notifications_active_rounded,
                    color: Colors.orange, size: 28),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'ปิดรับเคสด่วนแล้ว',
                    style: GoogleFonts.prompt(
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                        fontSize: 17),
                  ),
                ),
              ],
            ),
            content: Text(
              'คุณมีนัดหมายที่กำลังจะเริ่มภายใน 1 ชั่วโมง\nระบบปิดรับเคสด่วนให้อัตโนมัติแล้ว',
              style: GoogleFonts.prompt(fontSize: 14),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(
                  'รับทราบ',
                  style: GoogleFonts.prompt(
                      color: const Color(0xFF0262EC),
                      fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        );
      }
    });
  }

  void _toggleUrgentCase(bool value) {
    if (value == true) {
      // ถ้ากำลังพยายามเปิดรับเคส
      bool hasConflict = _hasConflictingAppointment();

      if (hasConflict) {
        // มีคิวชนใน 1 ชั่วโมง แจ้งเตือนและไม่อนุญาตให้เปิด
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                const Icon(Icons.warning_amber_rounded,
                    color: Colors.orange, size: 28),
                const SizedBox(width: 8),
                Text("ไม่สามารถเปิดรับเคสด่วนได้",
                    style: GoogleFonts.prompt(
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                        fontSize: 18)),
              ],
            ),
            content: Text(
                "คุณมีนัดหมายที่กำลังจะเริ่มภายใน 1 ชั่วโมง หรือกำลังอยู่ในช่วงเวลาของเคสอื่นอยู่ โปรดดำเนินการให้เสร็จสิ้นก่อนเปิดรับเคสด่วน",
                style: GoogleFonts.prompt(fontSize: 14)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text("ตกลง",
                    style: GoogleFonts.prompt(
                        color: const Color(0xFF0262EC),
                        fontWeight: FontWeight.bold)),
              )
            ],
          ),
        );
        return;
      }
    }

    // store จะเรียก notifyListeners() เอง → ListenableBuilder rebuild อัตโนมัติ
    LawyerProfileStore.instance.setUrgentCase(value);

    // บันทึกสถานะลง persistent storage
    // storage.write(key: 'urgentCaseEnabled', value: value.toString());
  }

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
    _startUrgentCaseTimer();
  }

  @override
  void dispose() {
    _urgentCaseTimer?.cancel();
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
    // final urgentCaseEnabled = await storage.read(key: 'urgentCaseEnabled');

    await LawyerProfileStore.instance.load();

    setState(() {
      userType = uType ?? '';
      name = namePro ?? '';
      imageUrl = imgPro ?? '';
      typeLogin = type.toString();
      // _isUrgentCaseEnabled = urgentCaseEnabled == 'true';
    });
    // final value =
    //     await postDio('${mainBannerApi}read', {'skip': 0, 'limit': 10});
    // setState(() {
    //   mockBannerList = value;
    // });
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
                // desktop ไม่แสดง SliverAppBar เพราะมี TopNav ใน menu.dart แล้ว
                if (!ResponsiveLayout.isDesktop(context))
                  ListenableBuilder(
                    listenable: LawyerProfileStore.instance,
                    builder: (_, __) => HomeAppBar(
                      name: name,
                      imageUrl: imageUrl,
                      userType: userType,
                      typeLogin: typeLogin,
                      isUrgentCaseEnabled:
                          LawyerProfileStore.instance.isUrgentCaseEnabled,
                      onProfileTap:
                          typeLogin != 'null' ? widget.onProfileTap : null,
                    ),
                  ),
                SliverToBoxAdapter(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: MediaQuery.of(context).size.height - 100,
                    ),
                    // wrap ด้วย AppLayout จำกัดความกว้างบน desktop
                    child: AppLayout(
                      child: _buildBody(size),
                    ),
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
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),

            ListenableBuilder(
              listenable: LawyerProfileStore.instance,
              builder: (_, __) => HomeActionCards(
                typeLogin: typeLogin,
                userType: userType,
                isUrgentCaseEnabled:
                    LawyerProfileStore.instance.isUrgentCaseEnabled,
                onToggleUrgentCase: _toggleUrgentCase,
              ),
            ),

            const SizedBox(height: 24),

            // ── Banner (shared) ──────────────────────────────────
            HomeBannerSection(banners: mockBannerList),

            const SizedBox(height: 24),

            // ── User dashboard ───────────────────────────────────
            if (typeLogin == 'null' || userType == 'user')
              HomeUserSection(
                cases: caseList,
                lawCategories: _lawCategories,
                lawyers: lawyerOnlineList,
                newLawyers: newLawyerOnlineList,
                isGuest: typeLogin == 'null',
              ),

            // ── Lawyer dashboard ─────────────────────────────────
            if (typeLogin != 'null' && userType == 'lawyer')
              ListenableBuilder(
                listenable: LawyerJobsStore.instance,
                builder: (_, __) => HomeLawyerSection(
                  appointments: appointmentList,
                  jobRequests: LawyerJobsStore.instance.jobs,
                  onJobStatusChanged: (id, newStatus) {
                    LawyerJobsStore.instance.updateStatus(id, newStatus);
                  },
                ),
              ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // ─── Action Card ─────────────────────────────────────────────────
}
