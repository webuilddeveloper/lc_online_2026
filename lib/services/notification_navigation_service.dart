import 'package:LawyerOnline/appointment-details-lawyer.dart';
import 'package:LawyerOnline/chat/chat_page_lawyer.dart';
import 'package:LawyerOnline/chat/chat_page_user.dart';
import 'package:LawyerOnline/component/dialog_service.dart';
import 'package:LawyerOnline/consult/consult_map.dart';
import 'package:LawyerOnline/consult/consult_status.dart';
import 'package:LawyerOnline/lawyer-job-details.dart';
import 'package:LawyerOnline/main.dart';
import 'package:LawyerOnline/models/user_profile_store.dart';
import 'package:LawyerOnline/post-details.dart';
import 'package:LawyerOnline/services/case_request_service.dart';
import 'package:LawyerOnline/services/lawyer_apply_notification_handler.dart';
import 'package:LawyerOnline/services/lawyer_case_broadcast_service.dart';
import 'package:LawyerOnline/shared/api_provider.dart';
import 'package:flutter/material.dart';

/// นำทางจากการแจ้งเตือน (รายการ, FCM, in-app banner) ไปยังหน้าที่เกี่ยวข้อง
class NotificationNavigationService {
  static String extractCode(Map<String, dynamic> data) {
    final ref = data['refCode']?.toString().trim() ?? '';
    if (ref.isNotEmpty) return ref;
    return data['code']?.toString().trim() ?? '';
  }

  static bool canNavigate(Map<String, dynamic> data) {
    if (LawyerApplyNotificationHandler.isLawyerApplyApproved(data)) return true;
    final page = data['page']?.toString() ?? '';
    final type = data['type']?.toString() ?? '';
    if (type == 'call') return false;
    if (page == 'lawyer_apply_approved' || type == 'lawyer_apply_approved') {
      return true;
    }
    final code = extractCode(data);
    return page.isNotEmpty && code.isNotEmpty;
  }

  /// ใช้เมื่อไม่มี BuildContext (FCM / local notification tap)
  static void handlePayload(Map<String, dynamic> data) {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final context = navigatorKey.currentContext;
      if (context == null || !context.mounted) return;
      await handle(context, data);
    });
  }

  /// คืน true ถ้านำทางสำเร็จ
  static Future<bool> handle(
    BuildContext context,
    Map<String, dynamic> data, {
    bool showLoading = true,
  }) async {
    await UserProfileStore.instance.load();

    if (LawyerApplyNotificationHandler.isLawyerApplyApproved(data)) {
      await LawyerApplyNotificationHandler.handle(showDialog: true);
      return true;
    }

    final type = data['type']?.toString() ?? '';
    if (type == 'call') return false;

    final page = data['page']?.toString() ?? '';
    final code = extractCode(data);

    if (page.isEmpty && code.isEmpty) return false;

    if (showLoading && context.mounted) {
      DialogService.showLoading(context);
    }

    try {
      switch (page) {
        case 'chat':
          return await _openChat(context, code: code, type: type);
        case 'appointment_detail':
          return await _openAppointment(context, code: code);
        case 'case_request_detail':
          return await _openCaseRequest(context, code: code, type: type);
        case 'community':
          return await _openCommunity(context, code: code);
        case 'lawyer_apply_approved':
          await LawyerApplyNotificationHandler.handle(showDialog: true);
          return true;
        default:
          return await _openByType(context, type: type, code: code);
      }
    } catch (_) {
      return false;
    } finally {
      if (showLoading && context.mounted) {
        Navigator.of(context, rootNavigator: true).maybePop();
      }
    }
  }

  static Future<bool> _openByType(
    BuildContext context, {
    required String type,
    required String code,
  }) async {
    if (code.isEmpty) return false;

    switch (type) {
      case 'chat_message':
      case 'session_start':
      case 'payment_confirmed':
      case 'case_payment_confirmed':
        return _openChat(context, code: code, type: type);
      case 'create_case':
      case 'case_accepted':
      case 'case_rejected':
      case 'session_end':
        return _openAppointment(context, code: code);
      case 'create_case_request':
      case 'lawyer_claim_request':
      case 'new_case_request':
      case 'case_request_rejected':
        return _openCaseRequest(context, code: code, type: type);
      case 'lawyer_apply_approved':
        await LawyerApplyNotificationHandler.handle(showDialog: true);
        return true;
      default:
        return false;
    }
  }

  static Future<bool> _openChat(
    BuildContext context, {
    required String code,
    required String type,
  }) async {
    if (code.isEmpty) return false;

    final userType = UserProfileStore.instance.userType;
    final myUserId = UserProfileStore.instance.code;

    final treatAsRoom = type == 'chat_message';
    if (treatAsRoom) {
      final opened = await _openChatByRoomCode(
        context,
        roomCode: code,
        userType: userType,
        myUserId: myUserId,
      );
      if (opened) return true;
    }

    final caseData = await _fetchCase(code);
    if (caseData == null) {
      if (!treatAsRoom) return false;
      return _openChatByRoomCode(
        context,
        roomCode: code,
        userType: userType,
        myUserId: myUserId,
        allowMinimal: true,
      );
    }

    return _openChatFromCase(
      context,
      caseData: caseData,
      userType: userType,
      myUserId: myUserId,
    );
  }

  static Future<bool> _openChatByRoomCode(
    BuildContext context, {
    required String roomCode,
    required String userType,
    required String myUserId,
    bool allowMinimal = false,
  }) async {
    final conv = await _findConversation(roomCode);
    if (conv != null) {
      final other = conv['user2Model'] as Map?;
      final chatModel = {
        'name': other?['name']?.toString() ??
            '${other?['firstName'] ?? ''} ${other?['lastName'] ?? ''}'.trim(),
        'imageUrl': other?['imageUrl']?.toString() ?? '',
        'caseCode': conv['caseCode']?.toString() ?? '',
        'active': true,
        'caseSuccess': false,
      };

      if (!context.mounted) return false;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => userType == 'lawyer'
              ? ChatPageLawyer(
                  model: chatModel,
                  roomCode: roomCode,
                  userId: myUserId,
                )
              : ChatPageUser(
                  model: chatModel,
                  roomCode: roomCode,
                  userId: myUserId,
                  caseCode: chatModel['caseCode']?.toString() ?? '',
                ),
        ),
      );
      return true;
    }

    if (!allowMinimal) return false;
    if (!context.mounted) return false;

    final minimalModel = {
      'name': 'แชท',
      'imageUrl': '',
      'active': true,
      'caseSuccess': false,
    };
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => userType == 'lawyer'
            ? ChatPageLawyer(
                model: minimalModel,
                roomCode: roomCode,
                userId: myUserId,
              )
            : ChatPageUser(
                model: minimalModel,
                roomCode: roomCode,
                userId: myUserId,
                caseCode: '',
              ),
      ),
    );
    return true;
  }

  static Future<bool> _openChatFromCase(
    BuildContext context, {
    required Map<String, dynamic> caseData,
    required String userType,
    required String myUserId,
  }) async {
    final existingRoom = caseData['messageRoomCode']?.toString() ?? '';
    if (existingRoom.isNotEmpty) {
      return _openChatByRoomCode(
        context,
        roomCode: existingRoom,
        userType: userType,
        myUserId: myUserId,
        allowMinimal: true,
      );
    }

    final userCode = caseData['userCode']?.toString() ?? '';
    final lawyerCode = caseData['lawyer']?.toString() ?? '';
    if (userCode.isEmpty || lawyerCode.isEmpty) return false;

    final ids = [userCode, lawyerCode]..sort();
    final result = await postObjectData('/m/chat/room/create', {
      'members': ids,
      'userA': userCode,
      'userB': lawyerCode,
      'caseCode': caseData['code'],
    });
    if (result['status'] != 'S') return false;

    final roomCode = result['objectData']?['roomCode']?.toString() ?? '';
    if (roomCode.isEmpty) return false;

    await postObjectData('/m/case/update', {
      'code': caseData['code'],
      'messageRoomCode': roomCode,
    });

    final otherName = userType == 'lawyer'
        ? caseData['userName']?.toString() ?? 'ลูกความ'
        : caseData['lawyerName']?.toString() ?? 'ทนายความ';

    final chatModel = {
      'name': otherName,
      'imageUrl': '',
      'caseCode': caseData['code']?.toString() ?? '',
      'active': true,
      'caseSuccess': false,
      ...caseData,
    };

    if (!context.mounted) return false;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => userType == 'lawyer'
            ? ChatPageLawyer(
                model: chatModel,
                roomCode: roomCode,
                userId: myUserId,
              )
            : ChatPageUser(
                model: chatModel,
                roomCode: roomCode,
                userId: myUserId,
                caseCode: caseData['code']?.toString() ?? '',
              ),
      ),
    );
    return true;
  }

  static Future<bool> _openAppointment(
    BuildContext context, {
    required String code,
  }) async {
    if (code.isEmpty) return false;

    final caseData = await _fetchCase(code);
    if (caseData == null) return false;

    final userType = UserProfileStore.instance.userType;
    if (!context.mounted) return false;

    if (userType == 'lawyer') {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AppointmentDetailsLawyer(model: caseData),
        ),
      );
      return true;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ConsultStatusPage(caseCode: code),
      ),
    );
    return true;
  }

  static Future<bool> _openCaseRequest(
    BuildContext context, {
    required String code,
    required String type,
  }) async {
    if (code.isEmpty) return false;

    final userType = UserProfileStore.instance.userType;
    final caseReqService = CaseRequestService();
    final request = await caseReqService.getRequestDetail(code);
    if (request.isEmpty) return false;

    if (userType == 'lawyer') {
      if (type == 'new_case_request') {
        final status = request['status'] ?? request['requestStatus'];
        final isOpen = status == 0 ||
            status == '0' ||
            status == 1 ||
            status == '1' ||
            (request['pendingLawyer']?.toString().isEmpty ?? true);
        if (isOpen) {
          await LawyerCaseBroadcastService.instance
              .presentCaseFromRequestCode(code);
          return true;
        }
      }

      final job = CaseRequestService.jobFromCaseRequest(request);
      if (!context.mounted) return false;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => LawyerJobDetailPage(job: job),
        ),
      );
      return true;
    }

    if (!context.mounted) return false;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ConsultMapPage(
          topic: request['topic']?.toString() ?? '',
          topicTitle: request['topicTitle']?.toString() ?? '',
          subTopic: request['subTopic']?.toString() ?? '',
          subTopicTitle: request['subTopicTitle']?.toString() ?? '',
          province: request['provinceTitle']?.toString() ??
              request['provinceCode']?.toString() ??
              '',
          detail: request['details']?.toString() ?? '',
          demand: request['requirement']?.toString() ?? '',
          images: const [],
          requestCode: code,
          caseType: request['caseType'] is int
              ? request['caseType'] as int
              : int.tryParse(request['caseType']?.toString() ?? '') ?? 2,
        ),
      ),
    );
    return true;
  }

  static Future<bool> _openCommunity(
    BuildContext context, {
    required String code,
  }) async {
    if (code.isEmpty) return false;

    final result = await postObjectData('/m/community/read', {
      'code': code,
      'skip': 0,
      'limit': 1,
    });
    if (result['status'] != 'S') return false;

    final raw = result['objectData'];
    Map<String, dynamic>? post;
    if (raw is List && raw.isNotEmpty && raw.first is Map) {
      post = Map<String, dynamic>.from(raw.first as Map);
    } else if (raw is Map) {
      post = Map<String, dynamic>.from(raw);
    }
    if (post == null) return false;

    if (!context.mounted) return false;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PostDetails(model: post),
      ),
    );
    return true;
  }

  static Future<Map<String, dynamic>?> _fetchCase(String code) async {
    final res = await postDio('${server}/m/case/read', {'code': code});
    if (res == null || res['status'] != 'S') return null;
    final raw = res['objectData'];
    if (raw is List && raw.isNotEmpty && raw.first is Map) {
      return Map<String, dynamic>.from(raw.first as Map);
    }
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return null;
  }

  static Future<Map<String, dynamic>?> _findConversation(String roomCode) async {
    final type = UserProfileStore.instance.userType;
    final userId = UserProfileStore.instance.code;
    final result = await postObjectData('/m/chat/readList', {
      'userType': type,
      'reference': userId,
      'limit': 100,
    });
    if (result['status'] != 'S') return null;
    final list = result['objectData'];
    if (list is! List) return null;

    for (final item in list) {
      if (item is! Map) continue;
      final conv = Map<String, dynamic>.from(item);
      if (conv['code']?.toString() == roomCode) return conv;
    }
    return null;
  }
}
