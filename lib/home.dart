import 'package:LawyerOnline/appointment-details.dart';
import 'package:LawyerOnline/case-status-all.dart';
import 'package:LawyerOnline/component/appbar.dart';
import 'package:LawyerOnline/consult/consult.dart';
import 'package:LawyerOnline/consult/consult_status.dart';
import 'package:LawyerOnline/law_type_all_page.dart';
import 'package:LawyerOnline/lawyer-online-details.dart';
import 'package:LawyerOnline/lawyer-online-list.dart';
import 'package:LawyerOnline/menu.dart';
import 'package:LawyerOnline/notification.dart';
import 'package:LawyerOnline/shared/api_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:latlong2/latlong.dart';
import 'package:permission_handler/permission_handler.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key, this.userType});

  final String? userType;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<dynamic> mockBannerList = [];
  int _currentBanner = 1;

  List<dynamic> lawyerOnlineList = [
    {
      "code": "0",
      "name": "ศักดิ์สิทธิ์ พิพากษ์",
      "scroll": 4.8,
      "cost": "Free",
      "costUnit": "/hr",
      "imageUrl": "assets/images/lawyer-avatar-1.png",
      "experience": "11+ years",
      "clientReviews": "60+",
      "casesWon": "148+",
      "skills": ["กฏหมายแพ่งและอาญา", "กฏหมายครอบครัว"]
    },
    {
      "code": "1",
      "name": "ธนากร นิติศักดิ์",
      "scroll": 4.1,
      "cost": "Free",
      "costUnit": "/hr",
      "imageUrl": "assets/images/lawyer-avatar-2.png",
      "experience": "19+ years",
      "clientReviews": "60+",
      "casesWon": "148+",
      "skills": ["กฏหมายครอบครัว", "ธุรกิจและการค้า"]
    },
    {
      "code": "2",
      "name": "พงษ์ภพ ยุติธรรม",
      "scroll": 3.9,
      "cost": "Free",
      "costUnit": "/hr",
      "imageUrl": "assets/images/lawyer-avatar-3.png",
      "experience": "10+ years",
      "clientReviews": "60+",
      "casesWon": "148+",
      "skills": ["กฏหมายแรงงาน", "ธุรกิจและการค้า"]
    },
    {
      "code": "3",
      "name": "อาริย์ ศิษย์กฎหมาย",
      "scroll": 3.0,
      "cost": "200",
      "costUnit": "/hr",
      "imageUrl": "assets/images/lawyer-avatar-4.png",
      "experience": "12+ years",
      "clientReviews": "60+",
      "casesWon": "148+",
      "skills": ["แรงงานต่างด้าว"]
    },
    {
      "code": "4",
      "name": "Sachin K",
      "scroll": 4.9,
      "cost": "1000",
      "costUnit": "/hr",
      "imageUrl": "assets/images/lawyer-avatar-5.png",
      "experience": "20+ years",
      "clientReviews": "60+",
      "casesWon": "148+",
      "skills": ["เทคโนโลยี/ออนไลน์", "นักสืบ/สืบสวน"]
    }
  ];

  List<Map<String, String>> postCategoryList = [
    {"code": "0", "title": "กฏหมายแพ่งและอาญา"},
    {"code": "1", "title": "กฏหมายครอบครัว"},
    {"code": "2", "title": "กฏหมายแรงงาน"},
    {"code": "3", "title": "ที่ดินและอสังหาริมทรัพย์"},
    {"code": "4", "title": "ธุรกิจและการค้า"},
    {"code": "5", "title": "แรงงานต่างด้าว"},
    {"code": "6", "title": "เทคโนโลยี/ออนไลน์"},
    {"code": "7", "title": "นักสืบ/สืบสวน"},
  ];

  String? selectedCategory = "0";

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
      "paymentStatus": "1"
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
      "paymentStatus": "1"
    },
  ];

  // ── caseList ─────────────────────────────────────────────────────
  // status ต้องสอดคล้องกับ CaseStatusAllPage tabs และ ConsultStatusPage:
  //   "1" = กำลังปรึกษา  → currentStep: 3
  //   "3" = เสร็จสิ้น    → currentStep: 4
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
      "statusText": "กำลังปรึกษา"
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
      "statusText": "เสร็จสิ้น"
    },
  ];

  final storage = FlutterSecureStorage();
  String userType = "";
  String imageUrl = "";
  String name = "";
  String typeLogin = "";

  @override
  void initState() {
    callRead();
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      requestPermissions();
    });
  }

  Future<void> requestPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.camera,
      Permission.microphone,
      Permission.photos,
      Permission.location,
    ].request();
    if (statuses[Permission.camera]!.isDenied) {}
  }

  callRead() async {
    var userType = await storage.read(key: 'userType');
    var imageProfile = await storage.read(key: 'imageUrlSocial');
    var nameProfile = await storage.read(key: 'name');
    var type = await storage.read(key: 'typeLogin');

    setState(() {
      this.userType = userType ?? '';
      name = nameProfile ?? 'assets/images/profile-avatar.jpg';
      imageUrl = imageProfile ?? '';
      typeLogin = type.toString();
    });

    var value = await postDio('${mainBannerApi}read', {'skip': 0, 'limit': 10});
    setState(() {
      mockBannerList = value;
    });
  }

  // ── สี + icon ตาม status ─────────────────────────────────────────
  Color _statusColor(String status) {
    switch (status) {
      case '1':
        return const Color(0xFFEF4444);
      case '2':
        return const Color(0xFFFF9500);
      case '3':
        return const Color(0xFF0262EC);
      default:
        return const Color(0xFF34C759);
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case '1':
        return Icons.info_outline_rounded;
      case '2':
        return Icons.pending_actions_rounded;
      case '3':
        return Icons.pending_actions_rounded;
      default:
        return Icons.check_circle_outline_rounded;
    }
  }

  // ── แปลง status → currentStep ของ ConsultStatusPage ──────────────
  int _statusToStep(String status) {
    switch (status) {
      case '3': return 3; // กำลังปรึกษา
      case '4': return 4; // เสร็จสิ้น
      default:  return 3;
    }
  }

  // ── แมป lawyerModel → lawyer ที่ ConsultStatusPage ต้องการ ────────
  Map<String, dynamic>? _buildLawyerForConsult(Map? lawyerModel) {
    if (lawyerModel == null) return null;
    return {
      'name'    : lawyerModel['name'] ?? '',
      'avatar'  : (lawyerModel['name'] as String? ?? 'ท').characters.first,
      'title'   : (lawyerModel['skills'] as List?)?.isNotEmpty == true
                      ? (lawyerModel['skills'] as List).first
                      : lawyerModel['experience'] ?? '',
      'rating'  : lawyerModel['scroll'] ?? 0,
      'imageUrl': lawyerModel['imageUrl'] ?? '',
    };
  }

  // ── navigate → ConsultStatusPage ─────────────────────────────────
  void _goToConsultStatus(Map model) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ConsultStatusPage(
          currentStep     : _statusToStep(model['status']?.toString() ?? '1'),
          lawyer          : _buildLawyerForConsult(model['lawyerModel'] as Map?),
          appointmentDate : model['appointmentDate'],
          appointmentTime : model['appointmentTime'],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: const Color(0xFFEEF2F5),
        appBar: appBarHome(
          name: name,
          memberType: userType == 'user' ? 'บุคคลทั่วไป' : 'หมอความ',
          imageUrl: imageUrl,
          typeLogin: typeLogin,
          rightWidget: Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => NotificationPage())),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFAFAFA),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(width: 1, color: const Color(0xFFDBDBDB)),
                  ),
                  child: Image.asset("assets/icons/bell.png", width: 20, height: 20),
                ),
              ),
            ],
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 20),
          children: [

            // ── Action Cards (user only) ──────────────────────────
            userType != "lawyer"
                ? Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    child: Column(
                      children: [
                        Row(children: [
                          Expanded(
                            child: actionCard(
                              title: "เปิดเคสให้ทนาย",
                              icon: "assets/icons/open-case.png",
                              onTap: () => Navigator.push(context,
                                  MaterialPageRoute(builder: (_) => ConsultPage())),
                            ),
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: actionCard(
                              title: "นัดหมายทนาย",
                              icon: "assets/icons/appointment-lawyer.png",
                              onTap: () => Navigator.push(context,
                                  MaterialPageRoute(builder: (_) => LawyerOnlineList())),
                            ),
                          ),
                        ]),
                        const SizedBox(height: 25),
                      ],
                    ),
                  )
                : const SizedBox.shrink(),

            // ── Banner ───────────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              height: heightCalculate(150),
              child: _buildBanner(),
            ),

            // ── Case Status Cards ─────────────────────────────────
            userType == "user"
                  ? 
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                title(
                  title: "สถานะเคส",
                  isRightBtn: true,
                  titleRightBtn: "ดูทั้งหมด",
                  viewAll: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CaseStatusAllPage(caseList: caseList),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                _buildCaseStatusList(),
                const SizedBox(height: 10),
              ],
            ) : const SizedBox.shrink(),

            // ── Law Type Category ────────────────────────────────
            title(
              title: "ประเภทกฏหมาย",
              isRightBtn: true,
              titleRightBtn: "ดูทั้งหมด",
              viewAll: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => LawTypeAllPage())),
            ),
            const SizedBox(height: 5),
            _buildMenuLowCategory(),
            const SizedBox(height: 25),

            // ── Upcoming Appointments (lawyer only) ──────────────
            userType == 'lawyer'
                ? Column(
                    children: [
                      title(
                        title: "นัดหมายที่กำลังจะมาถึง",
                        isRightBtn: true,
                        titleRightBtn: "ดูทั้งหมด",
                        viewAll: () => Navigator.push(context,
                            MaterialPageRoute(
                                builder: (_) => MenuPage(pageIndex: 2))),
                      ),
                      const SizedBox(height: 10),
                      _buildAppointmentList(),
                      const SizedBox(height: 10),
                    ],
                  )
                : const SizedBox.shrink(),

            // ── Lawyer Online (user only) ─────────────────────────
            userType != "lawyer"
                ? Column(
                    children: [
                      title(
                        title: "หมอความออนไลน์",
                        isRightBtn: true,
                        titleRightBtn: "ดูทั้งหมด",
                        viewAll: () => Navigator.push(context,
                            MaterialPageRoute(builder: (_) => LawyerOnlineList())),
                      ),
                      _buildLawyerOnline(),
                      const SizedBox(height: 80),
                    ],
                  )
                : const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  // ── Case Status List ──────────────────────────────────────────────
  Widget _buildCaseStatusList() {
    return SizedBox(
      height: 110,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(15, 0, 15, 15),
        itemCount: caseList.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, index) => _caseStatusItem(caseList[index]),
      ),
    );
  }

  Widget _caseStatusItem(Map model) {
    final status      = model['status']?.toString() ?? '1';
    final statusText  = model['statusText'] ?? '';
    final category    = model['category'] ?? '';
    final lawyerModel = model['lawyerModel'] as Map?;
    final lawyerName  = lawyerModel?['name'] ?? '';
    final lawyerImage = lawyerModel?['imageUrl'] ?? '';
    final color       = _statusColor(status);
    final icon        = _statusIcon(status);

    return GestureDetector(
      onTap: () => _goToConsultStatus(model),
      child: Container(
        width: MediaQuery.of(context).size.width - 60,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.asset(lawyerImage, width: 56, height: 56, fit: BoxFit.cover),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    lawyerName,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w700, color: Colors.black87),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    category,
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(icon, size: 12, color: color),
                        const SizedBox(width: 4),
                        Text(statusText,
                            style: TextStyle(
                                fontSize: 11,
                                color: color,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded,
                size: 14, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }

  // ── Banner ─────────────────────────────────────────────────────────
  _buildBanner() {
    return Stack(
      children: [
        CarouselSlider(
          options: CarouselOptions(
            aspectRatio: 3,
            enlargeCenterPage: false,
            scrollDirection: Axis.horizontal,
            viewportFraction: 1,
            enlargeFactor: 1,
            autoPlay: true,
            onPageChanged: (index, reason) => setState(() {}),
          ),
          items: mockBannerList.map((item) {
            return GestureDetector(
              onTap: () {},
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  image: DecorationImage(
                    image: NetworkImage(item['imageUrl']),
                    fit: BoxFit.cover,
                    colorFilter: ColorFilter.mode(
                      const Color.fromARGB(133, 70, 70, 70).withOpacity(0.5),
                      BlendMode.srcATop,
                    ),
                  ),
                ),
                child: CachedNetworkImage(
                  imageUrl: item['imageUrl'],
                  fit: BoxFit.contain,
                  width: double.infinity,
                  height: double.infinity,
                ),
              ),
            );
          }).toList(),
        ),
        Positioned(
          bottom: 30,
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: mockBannerList.map<Widget>((url) {
              int index = mockBannerList.indexOf(url);
              return Container(
                width: _currentBanner == index ? 17.5 : 7.0,
                height: 7.0,
                margin: const EdgeInsets.all(2.0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  color: Colors.white,
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  _buildMenuLowCategory() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _lawTypeItem(
              title: "กฏหมายแพ่งและอาญา",
              icons: "assets/icons/law-type-1.png",
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) =>
                      LawyerOnlineList(lawType: "กฏหมายแพ่งและอาญา"))),
            ),
          ),
          const SizedBox(width: 25),
          Expanded(
            child: _lawTypeItem(
              title: "กฎหมายครอบครัว",
              icons: "assets/icons/law-type-2.png",
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) =>
                      LawyerOnlineList(lawType: "กฏหมายครอบครัว"))),
            ),
          ),
          const SizedBox(width: 25),
          Expanded(
            child: _lawTypeItem(
              title: "กฎหมายบริษัท",
              icons: "assets/icons/law-type-3.png",
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) =>
                      LawyerOnlineList(lawType: "กฏหมายแรงงาน"))),
            ),
          ),
          const SizedBox(width: 25),
          Expanded(
            child: _lawTypeItem(
              title: "กฎหมายธุรกิจ",
              icons: "assets/icons/law-type-4.png",
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) =>
                      LawyerOnlineList(lawType: "ธุรกิจและการค้า"))),
            ),
          ),
        ],
      ),
    );
  }

  _lawTypeItem({required String title, required String icons, Function? onTap}) {
    return GestureDetector(
      onTap: () => onTap!(),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
                shape: BoxShape.circle, color: Color(0xFF0262EC)),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Image.asset(icons, fit: BoxFit.contain, height: 50),
            ),
          ),
          const SizedBox(height: 12),
          Text(title,
              style: const TextStyle(fontSize: 12), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  _buildLawyerOnline() {
    return SizedBox(
      height: 205,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(15, 12, 15, 20),
        itemCount: lawyerOnlineList.length,
        itemBuilder: (context, index) => Align(
          alignment: Alignment.topCenter,
          child: _lawyerOnlineItem(lawyerOnlineList[index],
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) =>
                      LawyerOnlineDetails(code: lawyerOnlineList[index]['code'])))),
        ),
        separatorBuilder: (_, __) => const SizedBox(width: 15),
      ),
    );
  }

  _lawyerOnlineItem(Map model, {Function? onTap}) {
    return GestureDetector(
      onTap: () => onTap!(),
      child: Container(
        width: 140,
        padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 15,
              offset: const Offset(0, 4))],
        ),
        child: Column(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.asset(model['imageUrl'] ?? '',
                  height: 80, width: 60, fit: BoxFit.cover),
            ),
            const SizedBox(height: 12),
            Text(model['name'] ?? '',
                style: const TextStyle(fontSize: 12),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
            const SizedBox(height: 8),
            Text('${model['scroll'] ?? 0} ⭐',
                style: const TextStyle(fontSize: 12)),
            Text(model['cost'] ?? '', style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }

  heightCalculate(double height) {
    return (((MediaQuery.of(context).size.width *
                    MediaQuery.of(context).size.height) /
                MediaQuery.of(context).size.height) -
            MediaQuery.of(context).size.width) +
        height;
  }

  title({String? title, bool isRightBtn = false,
      String? titleRightBtn, Function? viewAll}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(title!,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          isRightBtn
              ? GestureDetector(
                  onTap: () => viewAll!(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(width: 1, color: const Color(0xFFDBDBDB)),
                    ),
                    child: Text(titleRightBtn!,
                        style: const TextStyle(color: Color(0xFF0262EC), fontSize: 12)),
                  ),
                )
              : const SizedBox.shrink(),
        ],
      ),
    );
  }

  _buildAppointmentList() {
    return SizedBox(
      height: 86,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(15, 0, 15, 10),
        itemCount: appointmentList.length,
        itemBuilder: (context, index) => Align(
          alignment: Alignment.topCenter,
          child: _appointmentItem(appointmentList[index],
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) =>
                      AppointmentDetails(model: appointmentList[index])))),
        ),
        separatorBuilder: (_, __) => const SizedBox(width: 15),
      ),
    );
  }

  _appointmentItem(Map model, {Function? onTap}) {
    return GestureDetector(
      onTap: () => onTap!(),
      child: Container(
        width: MediaQuery.of(context).size.width - 30,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
            color: const Color(0xFFBAD5FF),
            borderRadius: BorderRadius.circular(10)),
        child: Row(
          children: [
            Container(
              width: 58,
              height: 56,
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: const Color(0xFF0262EC)),
              child: Image.asset('assets/icons/calendar-appointment.png',
                  height: 34, width: 36, fit: BoxFit.contain, color: Colors.white),
            ),
            const SizedBox(width: 30),
            Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(model['title'] ?? '',
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w700),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                Row(children: [
                  Image.asset('assets/icons/calendar-appointment.png',
                      height: 13, width: 13, fit: BoxFit.contain, color: Colors.black),
                  const SizedBox(width: 5),
                  Text(model['appointmentDate'] ?? '',
                      style: const TextStyle(fontSize: 10),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ]),
                Row(children: [
                  Image.asset('assets/icons/time-appointment.png',
                      height: 13, width: 13, fit: BoxFit.contain, color: Colors.black),
                  const SizedBox(width: 5),
                  Text(model['appointmentTime'] ?? '',
                      style: const TextStyle(fontSize: 10),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ]),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget actionCard(
      {required String title, required String icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: const Color(0xFF0262EC),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 15,
              offset: const Offset(0, 6))],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(icon, width: 40),
            const SizedBox(height: 12),
            Text(title,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 16)),
          ],
        ),
      ),
    );
  }

  void goBack() async {
    Navigator.pop(context, false);
  }
}