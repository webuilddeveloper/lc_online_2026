import 'package:LawyerOnline/services/home_refresh_service.dart';
import 'package:LawyerOnline/services/home_lawyer_ranking_service.dart';
import 'package:LawyerOnline/services/banner_service.dart';
import 'package:LawyerOnline/services/location_service.dart';
import 'package:LawyerOnline/repositories/lawyer_repository.dart';
import 'package:LawyerOnline/shared/api_provider.dart';
import 'package:LawyerOnline/widgets/home/home_app_bar.dart';
import 'package:LawyerOnline/widgets/home/home_banner_section.dart';
import 'package:LawyerOnline/widgets/home/home_lawyer_section.dart';
import 'package:LawyerOnline/widgets/home/home_user_section.dart';
import 'package:LawyerOnline/widgets/home/home_action_cards.dart';
import 'package:LawyerOnline/widgets/quick_actions_panel.dart';
import 'dart:async';
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

  List<dynamic> _bannerList = [];
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
  int _homeRefreshToken = 0;
  bool _isRefreshingHome = false;
  bool _refreshQueued = false;
  bool _didInitialLawyerProfileSync = false;

  Future<void> refreshAllData({bool force = false}) async {
    // กัน loop: ถ้ารีเฟรชอยู่แล้ว ให้คิวไว้รอบเดียว ห้ามซ้อน force วนไม่จบ
    if (_isRefreshingHome) {
      _refreshQueued = true;
      return;
    }
    _isRefreshingHome = true;
    try {
      do {
        _refreshQueued = false;
        await UserProfileStore.instance.load();
        await LawyerProfileStore.instance.load();

        final store = UserProfileStore.instance;
        if (store.userType == 'lawyer' && store.isLoggedIn) {
          // sync profile จาก API แค่ครั้งแรก — อย่าเรียกทุก refresh
          // (refreshFromApi จะ notifyListeners → เคยวน refresh ไม่จบ)
          if (!_didInitialLawyerProfileSync) {
            _didInitialLawyerProfileSync = true;
            await UserProfileStore.instance.refreshFromApi();
          }
          if (LawyerProfileStore.instance.isUrgentCaseEnabled) {
            LocationService.startPeriodicUpdate();
          } else {
            LocationService.stopPeriodicUpdate();
          }
        }

        if (!mounted) return;
        setState(() {
          userType = store.userType;
          name = store.name;
          imageUrl = store.imageUrl;
          typeLogin = store.typeLogin;
          _homeRefreshToken++;
        });

        await _loadRealHomeData(force: force);
        if (store.isLoggedIn && store.userType != 'lawyer') {
          await callReadCase(force: force);
        }
      } while (_refreshQueued && mounted);
    } finally {
      _isRefreshingHome = false;
    }
  }

  void _onHomeRefreshRequested() {
    if (!mounted) return;
    refreshAllData(force: true);
  }

  Future<void> _toggleUrgentCase(bool value) async {
    if (value == true) {
      LocationService.startPeriodicUpdate();
    } else {
      LocationService.stopPeriodicUpdate();
    }

    final effectiveValue =
        await LawyerProfileStore.instance.setUrgentCase(value);
    if (!effectiveValue) {
      LocationService.stopPeriodicUpdate();
    }
    if (!mounted || !value || effectiveValue) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'ระบบพักรับเคสด่วนอัตโนมัติ เพราะมีนัดหมายภายใน 1 ชั่วโมง',
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    // fallback แสดงรูปเดิมก่อน แล้วค่อยอัปเดตจาก API
    _bannerList = mockBannerList;
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    callRead();
    _loadBanners();
    UserProfileStore.instance.addListener(_onProfileChanged);
    LawyerJobsStore.instance.addListener(_onJobsChanged);
    HomeRefreshService.instance.addListener(_onHomeRefreshRequested);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      requestPermissions();
      _fadeCtrl.forward();
    });
    print('------- ><><><><><><>< ------- ${_caseRequestJobs}');
  }

  @override
  void didUpdateWidget(HomePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.isTabActive && widget.isTabActive) {
      refreshAllData(force: true);
    }
  }

  Future<void> _loadBanners() async {
    final banners = await BannerService.loadMainBanners();
    if (!mounted) return;
    setState(() => _bannerList = banners);
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
    HomeRefreshService.instance.removeListener(_onHomeRefreshRequested);
    _fadeCtrl.dispose();
    super.dispose();
  }

  void _onProfileChanged() {
    if (!mounted) return;
    // อัปเดตแค่ UI — ห้ามเรียก refreshAllData ที่นี่
    // (location update / refreshFromApi จะ notifyListeners บ่อยมาก)
    final store = UserProfileStore.instance;
    setState(() {
      name = store.name;
      imageUrl = store.imageUrl;
      userType = store.userType;
      typeLogin = store.typeLogin;
    });
  }

  void _onJobsChanged() {
    // ListenableBuilder rebuild จาก store อยู่แล้ว — ไม่ต้องยิง API ซ้ำ
    if (!mounted) return;
    setState(() {});
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
    await refreshAllData(force: true);
  }

  Future<void> _loadRealHomeData({bool force = false}) async {
    if (UserProfileStore.instance.userType != 'lawyer') {
      await _loadHomeLawyers(force: force);
    }

    if (UserProfileStore.instance.userType == 'lawyer') {
      await Future.wait([
        _loadLawyerAppointments(force: force),
        _loadLawyerCaseRequests(),
      ]);
    } else if (mounted) {
      setState(() {
        _lawyerAppointments = const [];
        _apiBookingJobs = const [];
        _appointmentLoadError = null;
        _isLoadingAppointments = false;
      });
    }
  }

  Future<void> _loadHomeLawyers({bool force = false}) async {
    if (_isLoadingLawyers && !force) return;
    if (!mounted) return;
    setState(() {
      _isLoadingLawyers = true;
      _lawyerLoadError = null;
    });
    try {
      dynamic model = {"limit": 50, "userType": "lawyer"};
      final param = await postDio("${server}/m/register/read", model);

      final resulte = param['objectData'] ?? [];
      final lawyers = List<dynamic>.from(resulte is List ? resulte : const []);

      // หมอความมาแรง: โปร (รีวิวดี) -> หน้าใหม่ (ยังไม่โปร)
      final trending =
          HomeLawyerRankingService.instance.rankTrending(lawyers);

      // หมอความสำหรับคุณ: กรองจากเคส/นัดหมาย + โพสในชุมชนของผู้ใช้
      final interests = await HomeLawyerRankingService.instance
          .deriveInterests(userCode: UserProfileStore.instance.code);
      final forYou =
          HomeLawyerRankingService.instance.rankForYou(lawyers, interests);

      if (!mounted) return;
      setState(() {
        _lawyersForYou = forYou;
        _trendingLawyers = trending;
        _isLoadingLawyers = false;
      });
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

  Future<void> _loadLawyerAppointments({bool force = false}) async {
    final lawyerCode = UserProfileStore.instance.code;
    if (!mounted) return;
    setState(() {
      _isLoadingAppointments = true;
      _appointmentLoadError = null;
    });
    try {
      final snapshot =
          await _appointmentRepository.readScheduleForLawyer(lawyerCode);
      if (!mounted) return;
      setState(() {
        _apiBookingJobs = snapshot.bookingJobs
            .where((job) => _isActiveHomeJob(job))
            .toList(growable: false);
        appointmentList = snapshot.appointments
            .where((apt) => _isActiveHomeAppointment(apt))
            .toList(growable: false);
        _lawyerAppointments = appointmentList;
        _isLoadingAppointments = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _appointmentLoadError = 'genericError'.tr();
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

  bool _isActiveHomeJob(dynamic job) {
    if (job is! Map) return false;
    final raw = job['rawCase'];
    if (raw is Map) {
      return CaseAppointmentMapper.isVisibleOnHome(
        Map<String, dynamic>.from(raw),
      );
    }
    return job['status']?.toString() != 'rejected';
  }

  bool _isActiveHomeAppointment(dynamic apt) {
    if (apt is! Map) return false;
    final raw = apt['rawCase'];
    if (raw is Map) {
      return CaseAppointmentMapper.isVisibleOnHome(
        Map<String, dynamic>.from(raw),
      );
    }
    final status = apt['caseStatus'] ?? apt['appointmentStatus'];
    final statusInt = status is int
        ? status
        : int.tryParse(status?.toString() ?? '') ?? -1;
    return statusInt != 0 && statusInt != 4;
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

  Future<void> callReadCase({bool force = false}) async {
    await UserProfileStore.instance.load();
    final store = UserProfileStore.instance;
    if (!store.isLoggedIn || store.code.isEmpty) return;
    // ฝั่งทนายโหลดผ่าน _loadLawyerAppointments / _loadLawyerCaseRequests แล้ว
    if (store.userType == 'lawyer') return;

    try {
      final param = await postDio(
        "${server}/m/case/read",
        {"userCode": store.code},
      );
      final data = param['objectData'];
      if (!mounted) return;
      if (data is List) {
        for (final item in data) {
          if (item is Map) {
            debugPrint(
              '🏠 home case ${item['code']} caseType=${item['caseType']}',
            );
          }
        }
      }
      setState(() {
        caseList = data is List
            ? data.where((item) {
                if (item is! Map) return false;
                return CaseAppointmentMapper.isVisibleOnHome(
                  Map<String, dynamic>.from(item),
                );
              }).toList()
            : const [];
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
          body: RefreshIndicator(
            color: const Color(0xFF0262EC),
            onRefresh: () => refreshAllData(force: true),
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
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
                isPro: LawyerProfileStore.instance.isPro,
                urgentCaseScope: LawyerProfileStore.instance.urgentCaseScope,
                onToggleUrgentCase: _toggleUrgentCase,
                onUrgentCaseScopeChanged: (scope) {
                  LawyerProfileStore.instance.setUrgentCaseScope(scope);
                },
              ),
            ),

            // const SizedBox(height: 16),
            // const QuickActionsPanel(),
            // const SizedBox(height: 24),

            // ── Banner (shared) ──────────────────────────────────
            HomeBannerSection(
              banners: _bannerList,
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
                    refreshAllData(force: true);
                  },
                ),
              ),

            // ── Lawyer dashboard ─────────────────────────────────
            if (typeLogin != 'null' && userType == 'lawyer')
              ListenableBuilder(
                listenable: LawyerJobsStore.instance,
                builder: (_, __) => HomeLawyerSection(
                  refreshToken: _homeRefreshToken,
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
