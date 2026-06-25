import 'package:LawyerOnline/component/appbar.dart';
import 'package:LawyerOnline/component/dialog_service.dart';
import 'package:LawyerOnline/shared/api_provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:LawyerOnline/models/lawyer/lawyer_jobs_store.dart';
import 'package:LawyerOnline/models/user_profile_store.dart';
import 'package:LawyerOnline/chat/chat_page_lawyer.dart';
import 'package:LawyerOnline/repositories/booking_case_repository.dart';
import 'package:LawyerOnline/repositories/lawyer_appointment_repository.dart';
import 'package:LawyerOnline/shared/responsive/app_layout.dart';
import 'package:LawyerOnline/shared/responsive/res_layout.dart';

class LawyerJobDetailPage extends StatefulWidget {
  final dynamic job;
  final VoidCallback? onAccept;
  final VoidCallback? onReject;

  const LawyerJobDetailPage({
    super.key,
    required this.job,
    this.onAccept,
    this.onReject,
  });

  @override
  State<LawyerJobDetailPage> createState() => _LawyerJobDetailPageState();
}

class _LawyerJobDetailPageState extends State<LawyerJobDetailPage> {
  static const _kPrimary = Color(0xFF0262EC);

  dynamic userModel = const {};
  bool isLoadingLawyers = true;

  Color _safeClientColor(dynamic raw) {
    if (raw == null) return const Color(0xFF0262EC);
    if (raw is int) return Color(raw);
    final parsed = int.tryParse(raw.toString());
    return parsed != null ? Color(parsed) : const Color(0xFF0262EC);
  }

  Future<void> callReadUser() async {
    try {
      final param = await postDio(
          "${server}/m/register/read", {"code": widget.job['userCode']});
      setState(() {
        userModel = param['objectData'][0];
        isLoadingLawyers = false;
        // _specialtyOptions = [...param['objectData']];
      });
    } catch (_) {
      isLoadingLawyers = false;
    }
  }

  Future<void> updateStatusConfirmCase(code, caseStatus) async {
    DialogService.showLoading(context);
    try {
      dynamic model = {"code": code, "caseStatus": caseStatus};
      final param = await postDio("${server}/m/case/update", model);
      if (param['status'] == 'S') {
        Navigator.pop(context);
        DialogService.showSuccess(
          context,
          title: "รับเคสสำเร็จ",
          message:
              "คุณได้ทำการรับงานจากลูกความจาก คุณ${widget.job['userName']} เรียบร้อยแล้ว",
          onClose: () {
            Navigator.pop(context);
          },
        );
      }
      // // final lawyers = await _lawyerRepository.searchLawyers();
      // // final mapped = lawyers.map(_homeLawyerMap).toList(growable: false);
      // final resulte = param['objectData'] ?? [];
      // if (!mounted) return;
      // setState(() {
      //   _lawyersForYou = resulte.take(10).toList(growable: false);
      //   _trendingLawyers = [...resulte]..sort((a, b) =>
      //       ((b['scroll'] as num?) ?? 0).compareTo((a['scroll'] as num?) ?? 0));
      //   _trendingLawyers = _trendingLawyers.take(10).toList(growable: false);
      //   _isLoadingLawyers = false;
      // });
      // print('------------------- ${mapped}');
    } catch (_) {
      // if (!mounted) return;
      // setState(() {
      //   _lawyersForYou = const [];
      //   _trendingLawyers = const [];
      //   _lawyerLoadError = 'genericError'.tr();
      //   _isLoadingLawyers = false;
      // });
    }
  }

  Future<void> updateStatusRejectCase(reasonCancel, caseStatus) async {
    DialogService.showLoading(context);
    try {
      dynamic model = {
        "code": widget.job['code'],
        "caseStatus": caseStatus,
        "reasonCancel": reasonCancel,
        "userType": "lawyer",
        "userCode": widget.job['userCode'],
        "cancelDate": DateFormat('yyyy-MM-dd').format(DateTime.now()),
        "cancelTime": DateFormat('HH:mm:ss').format(DateTime.now()),
      };
      print(model);
      final param = await postDio("${server}/m/case/update", model);
      if (param['status'] == 'S') {
        Navigator.pop(context);
        DialogService.showSuccess(
          context,
          title: "ยกเลิกนัดหมายแล้ว",
          message:
              "คุณได้ทำการยกเลิกนัดหมายลูกความจาก คุณ${widget.job['userName']} เรียบร้อยแล้ว",
          onClose: () {
            Navigator.pop(context);
            Navigator.pop(context);
          },
        );
      }
      // // final lawyers = await _lawyerRepository.searchLawyers();
      // // final mapped = lawyers.map(_homeLawyerMap).toList(growable: false);
      // final resulte = param['objectData'] ?? [];
      // if (!mounted) return;
      // setState(() {
      //   _lawyersForYou = resulte.take(10).toList(growable: false);
      //   _trendingLawyers = [...resulte]..sort((a, b) =>
      //       ((b['scroll'] as num?) ?? 0).compareTo((a['scroll'] as num?) ?? 0));
      //   _trendingLawyers = _trendingLawyers.take(10).toList(growable: false);
      //   _isLoadingLawyers = false;
      // });
      // print('------------------- ${mapped}');
    } catch (_) {
      // if (!mounted) return;
      // setState(() {
      //   _lawyersForYou = const [];
      //   _trendingLawyers = const [];
      //   _lawyerLoadError = 'genericError'.tr();
      //   _isLoadingLawyers = false;
      // });
    }
  }

  @override
  void initState() {
    super.initState();
    callReadUser();
  }

  @override
  Widget build(BuildContext context) {
    final caseStatus = widget.job['caseStatus'];
    final caseStatusInt = caseStatus is int
        ? caseStatus
        : int.tryParse(caseStatus?.toString() ?? '') ?? 0;
    // final isPending = caseStatusInt == 1;
    // final isAccepted = caseStatusInt == 2;

    final clientColor = _safeClientColor(widget.job['clientColor']);
    final isDesktop = ResponsiveLayout.isDesktop(context);

    print('===---==== ${widget.job}');

    return Scaffold(
      backgroundColor:
          isDesktop ? const Color(0xFFE9F2F9) : const Color(0xFFF2F6FF),
      appBar: isDesktop
          ? null
          : appBar(
              title: 'รายละเอียดคำขอ',
              backBtn: true,
              rightBtn: false,
              backAction: () => Navigator.pop(context),
              rightAction: () {},
            ),
      body: isLoadingLawyers
          ? _loadingState()
          : AppLayout(
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                      child: Column(children: [
                        _buildStatusCard(caseStatusInt),
                        const SizedBox(height: 14),
                        if (widget.job['caseStatusInt'] == 0) ...[
                          _buildDetailReasonCancelCard(clientColor),
                          const SizedBox(height: 14),
                        ],
                        _buildClientCard(clientColor),
                        const SizedBox(height: 14),
                        _buildDetailCard(clientColor),
                        const SizedBox(height: 14),
                        if ((widget.job['caseDate']?.toString() ?? '')
                            .isNotEmpty) ...[
                          _buildScheduleCard(),
                          const SizedBox(height: 14),
                        ],
                      ]),
                    ),
                  ),
                  if (widget.job['caseStatus'] == 1 && widget.onAccept != null)
                    _buildPendingButtons(context)
                  else if (widget.job['caseStatusInt'] == 2)
                    _buildAcceptedButton(context),
                ],
              ),
            ),
    );
  }

  Widget _buildClientCard(Color color) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecor(),
      child: Row(children: [
        Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(colors: [color, color.withOpacity(0.7)]),
            boxShadow: [
              BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 3))
            ],
          ),
          child: userModel['imageUrl'] != ""
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(43),
                  child: Container(
                    width: 45,
                    height: 45,
                    color: Colors.white.withOpacity(0.2),
                    child: Image.network(
                      userModel['imageUrl'] ?? '',
                      fit: BoxFit.cover,
                    ),
                  ),
                )
              : Center(
                  child: Text(
                    (widget.job['clientAvatar'] ?? '?').toString(),
                    style: const TextStyle(
                        fontSize: 22,
                        color: Colors.white,
                        fontWeight: FontWeight.w800),
                  ),
                ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${userModel['firstName']} ${userModel['lastName']}',
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1A2340)),
              ),
              const SizedBox(height: 4),
              Row(children: [
                Icon(Icons.schedule_rounded, size: 12, color: Colors.grey[400]),
                const SizedBox(width: 4),
                Text('ส่งคำขอ ${widget.job['caseDate'] ?? ''}',
                    style: TextStyle(fontSize: 11, color: Colors.grey[400])),
              ]),
              const SizedBox(height: 6),
              Row(children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _kPrimary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    (widget.job['price'] ?? '').toString(),
                    style: const TextStyle(
                        fontSize: 12,
                        color: _kPrimary,
                        fontWeight: FontWeight.w700),
                  ),
                ),
              ]),
            ],
          ),
        ),
      ]),
    );
  }

  Widget _buildDetailCard(Color color) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecor(),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _sectionTitle(Icons.gavel_rounded, 'รายละเอียดคดี', color),
        const SizedBox(height: 14),
        _infoRow('ประเภทหัวข้อ', (widget.job['topicTitle'] ?? '').toString()),
        const Divider(height: 20, color: Color(0xFFF0F4F8)),
        _infoRow('หัวข้อย่อย', (widget.job['subTopicTitle'] ?? '').toString()),
        const Divider(height: 20, color: Color(0xFFF0F4F8)),
        Text('รายละเอียด',
            style: TextStyle(fontSize: 11, color: Colors.grey[400])),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF8F9FB),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            (widget.job['details'] ?? '-').toString(),
            style:
                TextStyle(fontSize: 13, color: Colors.grey[700], height: 1.6),
          ),
        ),
      ]),
    );
  }

  Widget _buildDetailReasonCancelCard(Color color) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecor(),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('เหตุผลที่ยกเลิก',
            style: TextStyle(fontSize: 11, color: Colors.grey[400])),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF8F9FB),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            (widget.job['reasonCancel'] ?? '-').toString(),
            style:
                TextStyle(fontSize: 13, color: Colors.grey[700], height: 1.6),
          ),
        ),
      ]),
    );
  }

  Widget _buildScheduleCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecor(),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _sectionTitle(
            Icons.calendar_month_rounded, 'วันและเวลานัดหมาย', _kPrimary),
        const SizedBox(height: 14),
        Row(children: [
          Expanded(
            child: _scheduleChip(
                Icons.calendar_today_rounded,
                (widget.job['caseDate'] ?? '').toString(),
                const Color(0xFF0262EC)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _scheduleChip(
                Icons.access_time_rounded,
                '${widget.job['startTime']}-${widget.job['endTime']}',
                const Color(0xFF059669)),
          ),
        ]),
      ]),
    );
  }

  Widget _scheduleChip(IconData icon, String label, Color color) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(label,
                style: TextStyle(
                    fontSize: 12, color: color, fontWeight: FontWeight.w700)),
          ),
        ]),
      );

  Widget _buildStatusCard(int status) {
    final configs = {
      0: (
        Colors.grey,
        Icons.cancel_outlined,
        'ยกเลิกเคส',
        'เคสนี้ถูกยกเลิกแล้ว'
      ),
      1: (
        const Color(0xFFD97706),
        Icons.hourglass_top_rounded,
        'รอทนายรับเคส',
        'กรุณาตอบรับหรือปฏิเสธภายใน 24 ชั่วโมง'
      ),
      2: (
        _kPrimary,
        Icons.verified_rounded,
        'รอปรึกษา',
        'ยืนยันนัดหมายแล้ว รอถึงเวลานัด'
      ),
      3: (
        const Color(0xFF059669),
        Icons.headset_mic_rounded,
        'กำลังปรึกษา',
        'เริ่มห้องปรึกษาแล้ว สามารถพูดคุยกับลูกความได้'
      ),
      4: (
        const Color(0xFF6D28D9),
        Icons.task_alt_rounded,
        'เสร็จสิ้น',
        'การปรึกษาเสร็จสิ้นแล้ว'
      ),
    };
    final cfg = configs[status] ?? configs[1]!;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cfg.$1.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cfg.$1.withOpacity(0.2)),
      ),
      child: Row(children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
              color: cfg.$1.withOpacity(0.15), shape: BoxShape.circle),
          child: Icon(cfg.$2, size: 18, color: cfg.$1),
        ),
        const SizedBox(width: 12),
        Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(cfg.$3,
                style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w700, color: cfg.$1)),
            Text(cfg.$4,
                style: TextStyle(fontSize: 11, color: Colors.grey[500])),
          ]),
        ),
      ]),
    );
  }

  Widget _buildPendingButtons(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          16, 10, 16, MediaQuery.of(context).padding.bottom + 14),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFEEF2F5))),
      ),
      child: Row(children: [
        Expanded(
          child: GestureDetector(
            onTap: () {
              DialogService.showConfirmRejectJob(
                context,
                title: "ปฏิเสธคำขอ",
                message: "คุณยืนยันที่จะปฏิเสธคำขอนี้ใช่หรือไม่",
                onConfirm: () {
                  // widget.onReject?.call();
                  // if (context.mounted) Navigator.pop(context);
                  // updateStatusRejectCase(widget.job['code'], 0);
                  showReasonCancelDialog(context);
                },
              );
            },
            child: Container(
              height: 52,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF2F2),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: const Color(0xFFEF4444).withOpacity(0.4),
                    width: 1.5),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.close_rounded, color: Color(0xFFEF4444), size: 18),
                  SizedBox(width: 6),
                  Text('ปฏิเสธ',
                      style: TextStyle(
                          color: Color(0xFFEF4444),
                          fontWeight: FontWeight.w700,
                          fontSize: 14)),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: GestureDetector(
            onTap: () {
              DialogService.showConfirmAcceptJob(
                context,
                title: "รับงาน",
                message: "คุณยืนยันที่จะรับคำขอนี้ใช่หรือไม่",
                onConfirm: () {
                  updateStatusConfirmCase(widget.job['code'], 2);
                  // widget.onAccept?.call();
                  // if (context.mounted) Navigator.pop(context);
                },
              );
            },
            child: Container(
              height: 52,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [Color(0xFF0262EC), Color(0xFF0099FF)]),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                      color: _kPrimary.withOpacity(0.4),
                      blurRadius: 14,
                      offset: const Offset(0, 4))
                ],
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_outline_rounded,
                      color: Colors.white, size: 18),
                  SizedBox(width: 8),
                  Text('รับงานนี้',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 15)),
                ],
              ),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _buildAcceptedButton(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          16, 10, 16, MediaQuery.of(context).padding.bottom + 14),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFEEF2F5))),
      ),
      child: GestureDetector(
        onTap: () => {
          // Navigator.push(
          //   context,
          //   MaterialPageRoute(
          //     builder: (_) => ChatPageLawyer(
          //       // jobId: widget.job['id']?.toString(),
          //       model: {
          //         'name': widget.job['clientName'] ?? '',
          //         'avatar': widget.job['clientAvatar'] ?? '',
          //         'active': true,
          //         'caseSuccess': false,
          //         'clientColor': widget.job['clientColor'],
          //       },
          //     ),
          //   ),
          // ),
          print('==============123 ${widget.job}')
        },
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
                colors: [Color(0xFF0262EC), Color(0xFF0099FF)]),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                  color: _kPrimary.withOpacity(0.4),
                  blurRadius: 14,
                  offset: const Offset(0, 4))
            ],
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.headset_mic_rounded, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Text('เริ่มปรึกษา / แชทกับลูกความ',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 15)),
            ],
          ),
        ),
      ),
    );
  }

  void _onTapConversation(dynamic conv) async {
    setState(() {
      // appointmentList = param['objectData'];
      // _lawyerAppointments = param['objectData'];
      // _isLoadingAppointments = false;
    });
    String myUserId = UserProfileStore.instance.code;
    dynamic lawyerModel = {};

    await postDio("${server}/m/register/read", {"code": conv['lawyer']}).then(
      (paramLawyer) => {
        setState(
          () {
            lawyerModel = paramLawyer['objectData'][0];
          },
        ),
      },
    );

    List<String> ids = [userModel['code'], lawyerModel['code']]..sort();
    var model = {
      "members": ids,
      "userA": userModel['code'],
      "userB": lawyerModel['code'],
      "caseCode":  widget.job['code'],
    };
    var roomCode;
    await postObjectData("/m/chat/room/create", model).then(
      (result) async => {
        if (result['status'] == 'S')
          {
            setState(() {
              roomCode = result['objectData']['roomCode'];
            }),
            await postObjectData("/m/case/update",
                {"code": widget.job['code'], "messageRoomCode": roomCode}).then(
              (res) => {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => ChatPageLawyer(
                            model: {
                              'code': widget.job['code'],
                              'name':
                                  '${userModel['firstName']} ${userModel['lastName']}',
                              'avatar': userModel['imageUrl'],
                              // 'clientColor': conv.clientColor,
                              'active': true,
                              'caseSuccess': false,
                            },
                            // jobId: conv.id,
                            roomCode: roomCode,
                            userId: myUserId,
                          )),
                ),
              },
            ),
          }
      },
    );
  }

  Widget _infoRow(String label, String value) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(label,
                style: TextStyle(fontSize: 11, color: Colors.grey[400])),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A2340))),
          ),
        ],
      );

  Widget _sectionTitle(IconData icon, String title, Color color) =>
      Row(children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [color, color.withOpacity(0.7)]),
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2))
            ],
          ),
          child: Icon(icon, size: 16, color: Colors.white),
        ),
        const SizedBox(width: 10),
        Text(title,
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A2340))),
      ]);

  BoxDecoration _cardDecor() => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 12,
              offset: const Offset(0, 3))
        ],
      );

  Widget _loadingState() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }

  void showReasonCancelDialog(BuildContext context) {
    final TextEditingController reasonCancelController =
        TextEditingController();

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.45),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: EdgeInsets.fromLTRB(
                  24, MediaQuery.of(context).size.height * 0.01, 24, 0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: _buildFormContent(
                  context,
                  reasonCancelController,
                  setState, // ✅ ส่ง setState ลงไป
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFormContent(
    BuildContext context,
    TextEditingController reasonCancelController,
    StateSetter setState, // ✅ รับ setState มาใช้
  ) {
    final hasText = reasonCancelController.text.trim().isNotEmpty;

    return Container(
      key: const ValueKey('form'),
      color: Colors.white,
      child: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('เหตุผลการยกเลิก',
                  style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A2340))),
              const SizedBox(height: 4),
              Text('กรุณาใส่เหตุผลในการยกเลิกนัดหมาย',
                  style: TextStyle(fontSize: 13, color: Colors.grey[400])),
              const SizedBox(height: 20),
              TextFormField(
                controller: reasonCancelController,
                maxLines: 3,
                maxLength: 300,
                keyboardType: TextInputType.multiline,
                textInputAction: TextInputAction.newline,
                // ✅ trigger rebuild ทุกครั้งที่พิมพ์
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'กรอกเหตุผล...',
                  hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
                  filled: true,
                  fillColor: const Color(0xFFEEF2F5),
                  contentPadding: const EdgeInsets.all(14),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                          color: Color(0xFFEEF2F5), width: 1.5)),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                          color: Color(0xFFEEF2F5), width: 1.5)),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                          color: Color(0xFF0262EC), width: 1.5)),
                  counterStyle:
                      TextStyle(color: Colors.grey[400], fontSize: 11),
                ),
              ),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: const Color(0xFFEEF2F5), width: 1.5),
                      ),
                      child: const Center(
                        child: Text('ยกเลิก',
                            style: TextStyle(
                                color: Color(0xFF64748B),
                                fontWeight: FontWeight.w600,
                                fontSize: 14)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: GestureDetector(
                    onTap: hasText
                        ? () => updateStatusRejectCase(
                            reasonCancelController.text, 0)
                        : null, // ✅ ปิดปุ่มเมื่อไม่มีข้อความ
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: hasText
                            ? const LinearGradient(
                                colors: [Color(0xFF0262EC), Color(0xFF0485FF)])
                            : null,
                        color: hasText ? null : const Color(0xFFCDD5E0),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: hasText
                            ? [
                                BoxShadow(
                                    color: const Color(0xFF0262EC)
                                        .withOpacity(0.3),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4))
                              ]
                            : null,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.send_rounded,
                              color: hasText ? Colors.white : Colors.grey[400],
                              size: 16),
                          const SizedBox(width: 6),
                          Text('ส่งเหตุผล',
                              style: TextStyle(
                                  color:
                                      hasText ? Colors.white : Colors.grey[400],
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14)),
                        ],
                      ),
                    ),
                  ),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}
