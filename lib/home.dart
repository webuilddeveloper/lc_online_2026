import 'package:LawyerOnline/services/location_service.dart';
import 'package:LawyerOnline/shared/api_provider.dart';
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
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:LawyerOnline/models/lawyer/lawyer_jobs_store.dart';
import 'package:LawyerOnline/models/lawyer/lawyer_model.dart';
import 'package:LawyerOnline/repositories/booking_case_repository.dart';
import 'package:LawyerOnline/models/user/user_case_adapter.dart';
import 'package:LawyerOnline/repositories/lawyer_appointment_repository.dart';
import 'package:LawyerOnline/repositories/lawyer_repository.dart';
import 'package:LawyerOnline/services/case_request_service.dart';
import 'package:LawyerOnline/shared/responsive/res_layout.dart';
import 'package:LawyerOnline/shared/responsive/app_layout.dart';
import 'package:LawyerOnline/models/lawyer/lawyer_profile_store.dart';
import 'package:LawyerOnline/models/user_profile_store.dart'; // ← UserProfileStore
import 'package:easy_localization/easy_localization.dart';

// ใน build
// final isUrgentCase = LawyerProfileStore.instance.isUrgentCaseEnabled;

// ─── Palette & theme constants ───────────────────────────────────────
const _kCard = Colors.white;

class HomePage extends StatefulWidget {
  const HomePage({
    Key? key,
    this.userType,
    this.onProfileTap,
    this.isTabActive = true,
  });
  final String? userType;
  final VoidCallback? onProfileTap;
  final bool isTabActive;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  List<dynamic> mockBannerList = [
    {"code": "0", "imageUrl": "assets/images/banner1.png"},
    {"code": "1", "imageUrl": "assets/images/banner2.png"},
  ];
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;
  Timer? _profileDebounce;

  // ── ดึงนัดหมายจาก AppointmentStore แทน hardcode ────────────
  // final LawyerRepository _lawyerRepository = const ApiLawyerRepository();
  final LawyerAppointmentRepository _appointmentRepository =
      const ApiLawyerAppointmentRepository();
  final BookingCaseRepository _caseRepository =
      const ApiBookingCaseRepository();

  List<dynamic> _lawyersForYou = const [];
  List<dynamic> _trendingLawyers = const [];
  List<dynamic> _lawyerAppointments = const [];
  List<Map<String, dynamic>> _apiBookingJobs = const [];
  List<Map<String, dynamic>> _caseRequestJobs = const [];
  bool _isLoadingLawyers = false;
  bool _isLoadingAppointments = false;
  String? _lawyerLoadError;
  String? _appointmentLoadError;

  List<dynamic> appointmentList = const [];
  List<Map<String, dynamic>> get _lawyerJobRequests => _mergeJobs(
        _mergeJobs(_apiBookingJobs, _caseRequestJobs),
        LawyerJobsStore.instance.jobsForLawyer(UserProfileStore.instance.code),
      );

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
  // ── profile fields — sync จาก UserProfileStore ──────────────────────
  String userType = "";
  String imageUrl = "";
  String name = "";
  String typeLogin = "";

  List<dynamic> caseList = [];

  void _toggleUrgentCase(bool value) {
    if (value == true) {
      // ตอนทนาย login สำเร็จ หรือเปิดแอพแล้วเช็คว่าเป็นทนาย
      // if (UserProfileStore.instance.userType == 'lawyer') {

      // }
      LocationService.startPeriodicUpdate();
      // print('object');
      // ถ้ากำลังพยายามเปิดรับเคส
      // bool hasConflict = _hasConflictingAppointment();

      // if (hasConflict) {
      //   // มีคิวชนใน 1 ชั่วโมง แจ้งเตือนและไม่อนุญาตให้เปิด
      //   showDialog(
      //     context: context,
      //     builder: (context) => AlertDialog(
      //       shape:
      //           RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      //       title: Row(
      //         children: [
      //           const Icon(Icons.warning_amber_rounded,
      //               color: Colors.orange, size: 28),
      //           const SizedBox(width: 8),
      //           Text("ไม่สามารถเปิดรับเคสด่วนได้",
      //               style: GoogleFonts.prompt(
      //                   fontWeight: FontWeight.bold,
      //                   color: Colors.orange,
      //                   fontSize: 18)),
      //         ],
      //       ),
      //       content: Text(
      //           "คุณมีนัดหมายที่กำลังจะเริ่มภายใน 1 ชั่วโมง หรือกำลังอยู่ในช่วงเวลาของเคสอื่นอยู่ โปรดดำเนินการให้เสร็จสิ้นก่อนเปิดรับเคสด่วน",
      //           style: GoogleFonts.prompt(fontSize: 14)),
      //       actions: [
      //         TextButton(
      //           onPressed: () => Navigator.pop(context),
      //           child: Text("ตกลง",
      //               style: GoogleFonts.prompt(
      //                   color: const Color(0xFF0262EC),
      //                   fontWeight: FontWeight.bold)),
      //         )
      //       ],
      //     ),
      //   );
      //   return;
      // }
    } else {
      // ตอน logout หรือทนายกดปิดสถานะ active
      LocationService.stopPeriodicUpdate();
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
    UserProfileStore.instance.addListener(_onProfileChanged);
    LawyerJobsStore.instance.addListener(_onJobsChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      requestPermissions();
      _fadeCtrl.forward();
    });
  }

  // Future<void> _callReadLawyer() async {
  //   final param = await postDio("${server}m/register/read", {'category': 'guest'});

  //   setState(() {
  //     _lawyersForYou = param['objectDate'];
  //      _isLoadingLawyers = false;
  //   });
  // }

  @override
  void dispose() {
    UserProfileStore.instance.removeListener(_onProfileChanged);
    _profileDebounce?.cancel();
    LawyerJobsStore.instance.removeListener(_onJobsChanged);
    _fadeCtrl.dispose();
    super.dispose();
  }

  void _onProfileChanged() {
    if (!mounted) return;
    final store = UserProfileStore.instance;
    setState(() {
      name = store.name;
      imageUrl = store.imageUrl;
      userType = store.userType;
      typeLogin = store.typeLogin;
    });
    _profileDebounce?.cancel();
    _profileDebounce = Timer(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      _loadRealHomeData();
    });
  }

  void _onJobsChanged() {
    if (!mounted) return;
    if (UserProfileStore.instance.userType == 'lawyer') {
      _loadLawyerAppointments();
    }
  }

  Future<void> requestPermissions() async {
    if (kIsWeb) return; // permission_handler ไม่รองรับ Web
    await [
      Permission.camera,
      Permission.microphone,
      Permission.photos,
      Permission.location,
    ].request();
  }

  callRead() async {
    // โหลด UserProfileStore (ครั้งแรกเท่านั้น — subsequent calls return immediately)
    await UserProfileStore.instance.load();
    await LawyerProfileStore.instance.load();

    final store = UserProfileStore.instance;
    setState(() {
      userType = store.userType;
      name = store.name;
      imageUrl = store.imageUrl;
      typeLogin = store.typeLogin;
    });
    _loadRealHomeData();
    if (store.isLoggedIn) {
      callReadCase();
    }
  }

  Future<void> _loadRealHomeData() async {
    if (UserProfileStore.instance.userType != 'lawyer') {
      _loadHomeLawyers();
    }

    if (UserProfileStore.instance.userType == 'lawyer') {
      _loadLawyerAppointments();
      _loadLawyerCaseRequests();
    } else if (mounted) {
      setState(() {
        _lawyerAppointments = const [];
        _apiBookingJobs = const [];
        _appointmentLoadError = null;
        _isLoadingAppointments = false;
      });
    }
  }

  Future<void> _loadHomeLawyers() async {
    if (_isLoadingLawyers) return;
    setState(() {
      _isLoadingLawyers = true;
      _lawyerLoadError = null;
    });
    try {
      dynamic model = {"limit": 10, "userType": "lawyer"};
      final param = await postDio("${server}/m/register/read", model);

      final resulte = param['objectData'] ?? [];
      if (!mounted) return;
      setState(() {
        _lawyersForYou = resulte.take(10).toList(growable: false);
        _trendingLawyers = [...resulte]..sort((a, b) =>
            ((b['scroll'] as num?) ?? 0).compareTo((a['scroll'] as num?) ?? 0));
        _trendingLawyers = _trendingLawyers.take(10).toList(growable: false);
        _isLoadingLawyers = false;
      });
      // print('------------------- ${mapped}');
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _lawyersForYou = const [];
        _trendingLawyers = const [];
        _lawyerLoadError = 'genericError'.tr();
        _isLoadingLawyers = false;
      });
    }
  }

  Future<void> _loadLawyerAppointments() async {
    final lawyerCode = UserProfileStore.instance.code;
    // if (lawyerCode.isEmpty) return;
    // final localAppointments =
    //     LawyerJobsStore.instance.bookingAppointmentsForLawyer(lawyerCode);
    // if (_isLoadingAppointments) {
    //   // if (localAppointments.isNotEmpty && mounted) {
    //   //   setState(() {
    //   //     _lawyerAppointments = CaseAppointmentMapper.mergeAppointments(
    //   //       _lawyerAppointments,
    //   //       localAppointments,
    //   //     );
    //   //   });
    //   // }
    //   return;
    // }
    // setState(() {
    //   if (localAppointments.isNotEmpty) {
    //     _lawyerAppointments = CaseAppointmentMapper.mergeAppointments(
    //       _lawyerAppointments,
    //       localAppointments,
    //     );
    //   }
    //   _isLoadingAppointments = true;
    //   _appointmentLoadError = null;
    // });
    try {
      // final realAppointments =
      //     await _appointmentRepository.readScheduleForLawyer(lawyerCode);
      // if (!mounted) return;
      final param =
          await postDio("${server}/m/case/read", {"lawyer": lawyerCode});
      setState(() {
        appointmentList = param['objectData'];
        _lawyerAppointments = param['objectData'];
        _isLoadingAppointments = false;
      });
    } catch (_) {
      // if (!mounted) return;
      // final fallbackAppointments =
      //     LawyerJobsStore.instance.bookingAppointmentsForLawyer(lawyerCode);
      setState(() {
        // _lawyerAppointments = fallbackAppointments;
        // _apiBookingJobs = const [];
        // _appointmentLoadError =
        //     fallbackAppointments.isEmpty ? 'genericError'.tr() : null;
        _isLoadingAppointments = false;
      });
    }
  }

  // Map<String, dynamic> _homeLawyerMap(LawyerModel lawyer) {
  //   final legacy = lawyer.toLegacyMap();
  //   final specialty = lawyer.specialty.trim();
  //   return {
  //     ...legacy,
  //     'title': lawyer.title.trim().isNotEmpty ? lawyer.title : 'Lawyer',
  //     'scroll': lawyer.rating,
  //     'cost': lawyer.price > 0 ? lawyer.price.toString() : 'Free',
  //     'costUnit': '/hr',
  //     'userType': 'lawyer',
  //     'imageUrl': lawyer.imageUrl.trim().isNotEmpty
  //         ? lawyer.imageUrl
  //         : 'assets/images/lawyer-avatar-1.png',
  //     'experience':
  //         lawyer.experience.trim().isNotEmpty ? lawyer.experience : '-',
  //     'skills': specialty.isNotEmpty && specialty != '-' ? [specialty] : [],
  //   };
  // }

  List<Map<String, dynamic>> _mergeJobs(
    List<Map<String, dynamic>> apiJobs,
    List<Map<String, dynamic>> localJobs,
  ) {
    final byId = <String, Map<String, dynamic>>{};
    for (final job in apiJobs) {
      final id = job['id']?.toString() ?? '';
      if (id.isNotEmpty) byId[id] = Map<String, dynamic>.from(job);
    }
    for (final job in localJobs) {
      final id = job['id']?.toString() ?? '';
      if (id.isNotEmpty) byId[id] = Map<String, dynamic>.from(job);
    }
    return byId.values.toList(growable: false);
  }

  Future<void> _handleLawyerJobStatusChanged(
    dynamic job,
    String newStatus,
  ) async {
    final jobId = job['id']?.toString() ?? '';
    final isApiCase = job['isApiCase'] == true;
    final isBooking = (job['jobSource'] ?? 'urgent') == 'booking';

    if (!isApiCase) {
      // LawyerJobsStore.instance.updateStatus(jobId, newStatus);
      return;
    }

    final updatedJob = Map<String, dynamic>.from(job)..['status'] = newStatus;
    final updatedAppointments = newStatus == 'confirmed' ||
            newStatus == 'in_session' ||
            newStatus == 'done'
        ? [LawyerJobsStore.bookingJobToAppointment(updatedJob)]
        : <Map<String, dynamic>>[];
    setState(() {
      _apiBookingJobs = _apiBookingJobs.map((item) {
        return item['id'] == jobId ? updatedJob : item;
      }).toList(growable: false);
      // _lawyerAppointments = CaseAppointmentMapper.mergeAppointments(
      //   _lawyerAppointments,
      //   updatedAppointments,
      // );
    });

    if (!isBooking) return;

    final rawCase = job['rawCase'];
    final payload = rawCase is Map
        ? Map<String, dynamic>.from(rawCase)
        : <String, dynamic>{'code': job['caseCode'] ?? jobId};
    payload['caseStatus'] = _caseStatusFromJobStatus(newStatus);
    if ((payload['code']?.toString() ?? '').isEmpty && jobId.isNotEmpty) {
      payload['code'] = jobId;
    }

    try {
      await _caseRepository.updateCase(payload);
      _loadLawyerAppointments();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('genericError'.tr())),
      );
    }
  }

  int _caseStatusFromJobStatus(String status) {
    switch (status) {
      case 'confirmed':
        return 2;
      case 'in_session':
        return 3;
      case 'done':
        return 4;
      case 'rejected':
        return 5;
      default:
        return 1;
    }
  }

  Future<void> _loadLawyerCaseRequests() async {
    if (UserProfileStore.instance.userType != 'lawyer') return;
    try {
      final service = CaseRequestService();
      final list = await service.getLawyerPendingRequests();
      if (!mounted) return;
      setState(() {
        _caseRequestJobs = list
            .map(CaseRequestService.jobFromCaseRequest)
            .toList(growable: false);
      });
      LawyerJobsStore.instance.replaceCaseRequestJobs(_caseRequestJobs);
    } catch (_) {}
  }

  Future<void> callReadCase() async {
    await UserProfileStore.instance.load();
    final store = UserProfileStore.instance;
    if (!store.isLoggedIn || store.code.isEmpty) return;

    try {
      final param = await postDio(
        "${server}/m/case/read",
        {"userCode": store.code},
      );
      final data = param['objectData'];
      if (!mounted) return;
      setState(() {
        caseList = data is List ? data : const [];
        if (userType == 'lawyer') {
          _loadLawyerAppointments();
          _loadLawyerCaseRequests();
        }
      });
    } catch (_) {}
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
                    // listen ทั้งสอง store: profile data + lawyer urgent-case
                    listenable: Listenable.merge([
                      UserProfileStore.instance,
                      LawyerProfileStore.instance,
                    ]),
                    builder: (_, __) => HomeAppBar(
                      name: UserProfileStore.instance.name,
                      imageUrl: UserProfileStore.instance.imageUrl,
                      userType: UserProfileStore.instance.userType,
                      typeLogin: UserProfileStore.instance.typeLogin,
                      isUrgentCaseEnabled:
                          LawyerProfileStore.instance.isUrgentCaseEnabled,
                      onProfileTap:
                          UserProfileStore.instance.typeLogin != 'null'
                              ? widget.onProfileTap
                              : null,
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
            HomeBannerSection(
              banners: mockBannerList,
              autoPlayEnabled: widget.isTabActive,
            ),

            const SizedBox(height: 24),

            // ── User dashboard ───────────────────────────────────
            if (typeLogin == 'null' || userType == 'user')
              ListenableBuilder(
                listenable: LawyerJobsStore.instance,
                builder: (_, __) => HomeUserSection(
                  cases: caseList,
                  // UserCaseAdapter.fromJobs(LawyerJobsStore.instance
                  //     .jobsForClient(UserProfileStore.instance.code)),
                  lawCategories: _lawCategories,
                  lawyers: _lawyersForYou,
                  newLawyers: _trendingLawyers,
                  isGuest: typeLogin == 'null',
                  isLoadingLawyers: _isLoadingLawyers,
                  lawyerLoadError: _lawyerLoadError,
                  onAppointmentClosed: () {
                    debugPrint('📱 AppointmentDetails closed, refreshing...');
                    callRead(); // ✅ เรียก callRead() ใหม่
                  },
                ),
              ),

            // ── Lawyer dashboard ─────────────────────────────────
            if (typeLogin != 'null' && userType == 'lawyer')
              ListenableBuilder(
                listenable: LawyerJobsStore.instance,
                builder: (_, __) => HomeLawyerSection(
                  // appointments: appointmentList,
                  isLoadingAppointments: _isLoadingAppointments,
                  appointmentLoadError: _appointmentLoadError,
                  jobRequests: _lawyerJobRequests,
                  onJobStatusChanged: _handleLawyerJobStatusChanged,
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
